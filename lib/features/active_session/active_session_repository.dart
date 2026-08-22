import 'dart:async';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import '../../core/sensor_capture/aggregate_sensor_data.dart';
import '../../core/sensor_capture/sensor_service.dart';
import '../../core/analysis/session_sample.dart';
import '../../core/analysis/classifier_service.dart';
import '../../core/analysis/analyzer_service.dart';
import '../../core/file_storage/file_service.dart';

enum ActiveSessionError {
  inactiveService,
  activeService,
  activeCapture,
  noCapture,
  noResult,
  gpsDisabled,
  gpsDenied,
  gpsPermaDenied,
  preciseGpsDenied,
  sensorUnknown,
  outOfStorage,
  fileUnknown,
}

enum ActiveSessionStatus {
  inactive,
  initializing,
  idle,
  capturing,
  analyzing,
  analyzed,
}

class ActiveSessionRepository {
  final SensorService _sensorService;
  final ClassifierService _classifierService;
  final AnalyzerService _analyzerService;
  final FileService _fileService;
  final _statusController = BehaviorSubject<ActiveSessionStatus>.seeded(
    ActiveSessionStatus.inactive,
  );
  final List<AggregateSensorData> _stagingBuffer = [];
  final List<SessionSample> _sessionLog = [];

  Analysis _analysis = Analysis();

  StreamSubscription<AggregateSensorData>? _sensorSubscription;
  StreamSubscription<SensorStatus>? _statusSubscription;
  StreamSubscription<Classification>? _classifierSubscription;

  ActiveSessionRepository({
    required this._sensorService,
    required this._classifierService,
    required this._analyzerService,
    required this._fileService,
  });

  Stream<ActiveSessionStatus> get statusStream => _statusController.stream;
  List<SessionSample> get sessionLog => List.unmodifiable(_sessionLog);
  Analysis get analysis => _analysis;

  Future<void> initialize({
    required void Function(ActiveSessionError) onError,
  }) async {
    try {
      if (_statusController.value != ActiveSessionStatus.inactive) {
        onError(ActiveSessionError.activeService);
        return;
      }

      await _statusSubscription?.cancel();
      _statusSubscription = _sensorService.statusStream.listen((sensorStatus) {
        final ActiveSessionStatus status;

        switch (sensorStatus) {
          case SensorStatus.inactive:
            reset();
            status = ActiveSessionStatus.inactive;
          case SensorStatus.initialising:
            status = ActiveSessionStatus.initializing;
          case SensorStatus.active:
            _classifierService.initialize(_sensorService.sensorStream);
            status = ActiveSessionStatus.idle;
        }

        _statusController.add(status);
      });

      await _sensorService.initialiseSensor();
    } on SensorException catch (exception) {
      switch (exception) {
        case ServiceInactiveException():
          onError(ActiveSessionError.inactiveService);
        case ServiceAlreadyActiveException():
          onError(ActiveSessionError.activeService);
        case GpsDisabledException():
          onError(ActiveSessionError.gpsDisabled);
        case GpsDeniedException():
          onError(ActiveSessionError.gpsDenied);
        case GpsPermaDeniedException():
          onError(ActiveSessionError.gpsPermaDenied);
        case PreciseGpsDeniedException():
          onError(ActiveSessionError.preciseGpsDenied);
        case UnknownSensorException():
          onError(ActiveSessionError.sensorUnknown);
      }
    }
  }

  void startCapture({required void Function(ActiveSessionError) onError}) {
    if (_statusController.value != ActiveSessionStatus.idle) {
      switch (_statusController.value) {
        case ActiveSessionStatus.inactive:
        case ActiveSessionStatus.initializing:
          onError(ActiveSessionError.inactiveService);
        default:
          onError(ActiveSessionError.activeCapture);
      }
      return;
    }

    _statusController.add(ActiveSessionStatus.capturing);

    _sensorSubscription = _sensorService.sensorStream
        .sampleTime(const Duration(milliseconds: 20))
        .where((_) => _statusController.value == ActiveSessionStatus.capturing)
        .listen(
          (data) => _stagingBuffer.add(data),
          onError: (error) => switch (error) {
            GpsDeniedException() => onError(ActiveSessionError.gpsDenied),
            GpsDisabledException() => onError(ActiveSessionError.gpsDisabled),
            GpsPermaDeniedException() => onError(
              ActiveSessionError.gpsPermaDenied,
            ),
            PreciseGpsDeniedException() => onError(
              ActiveSessionError.preciseGpsDenied,
            ),
            _ => onError(ActiveSessionError.sensorUnknown),
          },
        );
    _classifierSubscription = _classifierService.classificationStream
        .where((_) => _statusController.value == ActiveSessionStatus.capturing)
        .listen((classification) {
          _sessionLog.addAll(
            _stagingBuffer.map(
              (data) =>
                  SessionSample(data: data, classification: classification),
            ),
          );
          _stagingBuffer.clear();
        });
  }

  Future<void> stopCapture({
    required void Function(ActiveSessionError) onError,
  }) async {
    if (_statusController.value != ActiveSessionStatus.capturing ||
        _sessionLog.isEmpty) {
      switch (_statusController.value) {
        case ActiveSessionStatus.inactive:
        case ActiveSessionStatus.initializing:
          onError(ActiveSessionError.inactiveService);
        default:
          onError(ActiveSessionError.noCapture);
      }
      return;
    }

    _statusController.add(ActiveSessionStatus.analyzing);
    _stagingBuffer.clear();
    await _classifierSubscription?.cancel();
    await _sensorSubscription?.cancel();
    await _getAnalysis(_sessionLog);
  }

  Future<void> save({
    required void Function(ActiveSessionError) onError,
  }) async {
    try {
      if (_statusController.value != ActiveSessionStatus.analyzed) {
        switch (_statusController.value) {
          case ActiveSessionStatus.inactive:
          case ActiveSessionStatus.initializing:
            onError(ActiveSessionError.inactiveService);
          default:
            onError(ActiveSessionError.noResult);
        }
        return;
      }

      final resolvedName =
          'log_num_${_sessionLog[0].data.rawAccel.timestamp.toString()}';

      final sessionExport = {
        'metadata': {
          'generated_at': DateTime.now().toIso8601String(),
          'version': _analysis.version,
        },
        'analysis': _analysis.toJson(),
        'session_log': _sessionLog.map((sample) => sample.toJson()).toList(),
      };

      final exportString = jsonEncode(sessionExport);

      await _fileService.logAppData(
        exportString,
        fileName: resolvedName,
        type: FileType.result,
      );

      reset();
    } on FileException catch (exception) {
      switch (exception) {
        case OutOfStorageException():
          onError(ActiveSessionError.outOfStorage);
        case FileNotFoundException():
        case UnknownStorageException():
          onError(ActiveSessionError.fileUnknown);
      }
    }
  }

  void reset() async {
    if (_statusController.value == ActiveSessionStatus.inactive ||
        _statusController.value == ActiveSessionStatus.initializing) {
      return;
    }

    _sessionLog.clear();
    _stagingBuffer.clear();
    _classifierSubscription?.cancel();
    _sensorSubscription?.cancel();
    _analysis = Analysis();
    _statusController.add(ActiveSessionStatus.idle);
  }

  Future<void> dispose() async {
    await _statusSubscription?.cancel();
    await _sensorSubscription?.cancel();
    await _classifierSubscription?.cancel();
    _sensorService.dispose();
    _classifierService.dispose();
  }

  Future<void> _getAnalysis(List<SessionSample> log) async {
    final analysis = await _analyzerService.analyze(log);

    if (_statusController.value != ActiveSessionStatus.analyzing) {
      return;
    }

    _analysis = analysis;
    _statusController.add(ActiveSessionStatus.analyzed);
  }
}

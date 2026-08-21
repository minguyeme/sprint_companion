import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../core/sensor_capture/aggregate_sensor_data.dart';
import '../../core/sensor_capture/sensor_service.dart';
import '../../core/analysis/session_sample.dart';
import '../../core/analysis/classifier_service.dart';
import '../../core/analysis/analyzer_service.dart';

enum ActiveSessionError {
  inactiveService,
  activeService,
  activeCapture,
  gpsDisabled,
  gpsDenied,
  gpsPermaDenied,
  preciseGpsDenied,
  sensorUnknown,
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
  });

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
          onError(ActiveSessionError.inactiveService);
        default:
          onError(ActiveSessionError.activeCapture);
      }
      return;
    }

    _statusController.add(ActiveSessionStatus.capturing);

    _sensorSubscription = _sensorService.sensorStream
        .sampleTime(const Duration(milliseconds: 20))
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
    if (_statusController.value != ActiveSessionStatus.capturing) {
      onError(ActiveSessionError.inactiveService);
      return;
    }

    _statusController.add(ActiveSessionStatus.analyzing);
    _stagingBuffer.clear();
    await _classifierSubscription?.cancel();
    await _sensorSubscription?.cancel();
    await _getAnalysis(_sessionLog);
  }

  Future<void> reset() async {
    if (_statusController.value == ActiveSessionStatus.inactive ||
        _statusController.value == ActiveSessionStatus.initializing) {
      return;
    }

    _sessionLog.clear();
    _stagingBuffer.clear();
    await _classifierSubscription?.cancel();
    await _sensorSubscription?.cancel();
    _analysis = Analysis();
    _statusController.add(ActiveSessionStatus.idle);
  }

  Future<void> dispose() async {
    await _statusSubscription?.cancel();
    await _sensorSubscription?.cancel();
    await _classifierSubscription?.cancel();
    await _statusController.close();
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

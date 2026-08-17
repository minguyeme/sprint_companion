import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../core/sensor_capture/aggregate_sensor_data.dart';
import '../../core/sensor_capture/sensor_service.dart';
import '../../core/classification/classifier_service.dart';

const _classifierFrequency = 1;
const _dataStreamFrequency = 50;
const int _dataStreamWaitTimeInMs = 1000 ~/ _dataStreamFrequency;
//_dataStreamFrequency must be divisible by _classifierFrequency
const int _classificationRatio = _dataStreamFrequency~/_dataStreamFrequency;

enum AnalyzerError {
  inactiveService,
  activeService,
  activeCapture,
  emptyLogs,
  gpsDisabled,
  gpsDenied,
  gpsPermaDenied,
  preciseGpsDenied,
  sensorUnknown,
}

enum AnalyzerStatus {
  inactive,
  initializing,
  idle,
  capturing,
  analyzing,
  analyzed,
}

class SprintAnalyzerRepository {
  final SensorService _sensorService;
  final ClassifierService _classifierService;
  final _statusController = BehaviorSubject<AnalyzerStatus>.seeded(
    AnalyzerStatus.inactive,
  );
  final List<AggregateSensorData> _sessionLog = [];
  final List<Classification> _classificationLog = [];

  StreamSubscription<AggregateSensorData>? _sensorSubscription;
  StreamSubscription<SensorStatus>? _statusSubscription;
  StreamSubscription<Classification>? _classifierSubscription;

  SprintAnalyzerRepository({
    required this._sensorService,
    required this._classifierService,
  });

  Future<void> initialize({
    required void Function(AnalyzerError) onError,
  }) async {
    try {
      if (_statusController.value != AnalyzerStatus.inactive) {
        onError(AnalyzerError.activeService);
        return;
      }

      _statusSubscription = _sensorService.statusStream.listen((sensorStatus) {
        final AnalyzerStatus status;

        switch (sensorStatus) {
          case SensorStatus.inactive:
            _classifierService.dispose();
            status = AnalyzerStatus.inactive;
          case SensorStatus.initialising:
            status = AnalyzerStatus.initializing;
          case SensorStatus.active:
            _classifierService.initialize(_sensorService.sensorStream);
            status = AnalyzerStatus.idle;
        }

        _statusController.add(status);
      });

      await _sensorService.initialiseSensor();
    } on SensorException catch (exception) {
      switch (exception) {
        case ServiceInactiveException():
          onError(AnalyzerError.inactiveService);
        case ServiceAlreadyActiveException():
          onError(AnalyzerError.activeService);
        case GpsDisabledException():
          onError(AnalyzerError.gpsDisabled);
        case GpsDeniedException():
          onError(AnalyzerError.gpsDenied);
        case GpsPermaDeniedException():
          onError(AnalyzerError.gpsPermaDenied);
        case PreciseGpsDeniedException():
          onError(AnalyzerError.preciseGpsDenied);
        case UnknownSensorException():
          onError(AnalyzerError.sensorUnknown);
      }
    }
  }

  void startCapture({required void Function(AnalyzerError) onError}) {
    if (_statusController.value != AnalyzerStatus.idle) {
      switch (_statusController.value) {
        case AnalyzerStatus.inactive:
          onError(AnalyzerError.inactiveService);
        default:
          onError(AnalyzerError.activeCapture);
      }
      return;
    }

    _statusController.add(AnalyzerStatus.capturing);
    _sensorSubscription = _sensorService.sensorStream
        .where((_) => _statusController.value == AnalyzerStatus.capturing)
        .throttleTime(const Duration(milliseconds: _dataStreamWaitTimeInMs))
        .listen(
          (data) => _sessionLog.add(data),
          onError: (error) => switch (error) {
            GpsDeniedException() => onError(AnalyzerError.gpsDenied),
            GpsDisabledException() => onError(AnalyzerError.gpsDisabled),
            GpsPermaDeniedException() => onError(AnalyzerError.gpsPermaDenied),
            PreciseGpsDeniedException() => onError(
              AnalyzerError.preciseGpsDenied,
            ),
            _ => onError(AnalyzerError.sensorUnknown),
          },
        );
    _classifierSubscription = _classifierService.classificationStream
        .where((_) => _statusController.value == AnalyzerStatus.capturing)
        .listen((classification) => _classificationLog.add(classification));
  }

  Future<void> stopCapture({
    required void Function(AnalyzerError) onError,
  }) async {
    if (_statusController.value != AnalyzerStatus.capturing ||
        _classificationLog.isEmpty) {
      switch (_statusController.value) {
        case AnalyzerStatus.inactive:
          onError(AnalyzerError.inactiveService);
        default:
          onError(AnalyzerError.emptyLogs);
      }
      return;
    }

    _statusController.add(AnalyzerStatus.analyzing);
    await _sensorSubscription?.cancel();

    _sessionLog.length = (_sessionLog.length ~/ _classificationRatio) * _classificationRatio;
  }

  Future<void> dipose() async {
    _sensorService.dispose();
    _classifierService.dispose();
    await _statusSubscription?.cancel();
    await _sensorSubscription?.cancel();
    await _classifierSubscription?.cancel();
    await _statusController.close();
  }
}

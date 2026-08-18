import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../core/sensor_capture/aggregate_sensor_data.dart';
import '../../core/sensor_capture/sensor_service.dart';
import '../../core/classification/classifier_service.dart';

enum AnalyzerError {
  inactiveService,
  activeService,
  activeCapture,
  gpsDisabled,
  gpsDenied,
  gpsPermaDenied,
  preciseGpsDenied,
  sensorUnknown,
}

enum AnalyzerStatus { inactive, initializing, idle, capturing, analyzed }

typedef SessionSample = ({
  AggregateSensorData data,
  Classification classification,
});

class SprintAnalyzerRepository {
  final SensorService _sensorService;
  final ClassifierService _classifierService;
  final _statusController = BehaviorSubject<AnalyzerStatus>.seeded(
    AnalyzerStatus.inactive,
  );
  final List<AggregateSensorData> _stagingBuffer = [];
  final List<SessionSample> _sessionLog = [];

  double? _sessionDuration;
  double? _intenseDuration;
  double? _maxGForce;
  double? _fatigueIndex;

  StreamSubscription<AggregateSensorData>? _sensorSubscription;
  StreamSubscription<SensorStatus>? _statusSubscription;
  StreamSubscription<Classification>? _classifierSubscription;

  SprintAnalyzerRepository({
    required this._sensorService,
    required this._classifierService,
  });

  List<SessionSample> get sessionLog => _sessionLog;
  double? get sessionDuration => _sessionDuration;
  double? get intenseDuration => _intenseDuration;
  double? get maxGForce => _maxGForce;
  double? get fatigueIndex => _fatigueIndex;

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
        .sampleTime(const Duration(milliseconds: 20))
        .listen(
          (data) => _stagingBuffer.add(data),
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
        .listen((classification) {
          _sessionLog.addAll(
            _stagingBuffer.map(
              (data) => (data: data, classification: classification),
            ),
          );
          _stagingBuffer.clear();
        });
  }

  Future<void> stopCapture({
    required void Function(AnalyzerError) onError,
  }) async {
    if (_statusController.value != AnalyzerStatus.capturing) {
      onError(AnalyzerError.inactiveService);
      return;
    }

    _statusController.add(AnalyzerStatus.analyzed);
    _stagingBuffer.clear();
    await _classifierSubscription?.cancel();
    await _sensorSubscription?.cancel();
  }

  Future<void> dipose() async {
    _sensorService.dispose();
    _classifierService.dispose();
    await _statusSubscription?.cancel();
    await _sensorSubscription?.cancel();
    await _classifierSubscription?.cancel();
    await _statusController.close();
  }

  void _analyze(List<SessionSample> log) {
    if (log.isEmpty) {
      _sessionDuration = null;
      _intenseDuration = null;
      _maxGForce = null;
      _fatigueIndex = null;
      return;
    }

    _sessionDuration = _sessionLog.length * 0.02;
  }
}

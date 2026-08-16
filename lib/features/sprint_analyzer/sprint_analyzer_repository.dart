import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../core/sensor_capture/aggregate_sensor_data.dart';
import '../../core/sensor_capture/sensor_service.dart';
import '../../core/classification/classifier_service.dart';

enum AnalyzerError {
  inactiveService,
  activeService,
  gpsDisabled,
  gpsDenied,
  gpsPermaDenied,
  preciseGpsDenied,
  sensorUnknown,
}

enum AnalyzerStatus { inactive, initializing, idle, analyzing }

class SprintAnalyzerRepository {
  final SensorService _sensorService;
  final ClassifierService _classifierService;
  final _statusController = BehaviorSubject<AnalyzerStatus>.seeded(
    AnalyzerStatus.inactive,
  );

  StreamSubscription<AggregateSensorData>? _sensorSubscription;
  StreamSubscription<SensorStatus>? _statusSubscription;

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
        _statusController.add(switch (sensorStatus) {
          SensorStatus.inactive => AnalyzerStatus.inactive,
          SensorStatus.initialising => AnalyzerStatus.initializing,
          SensorStatus.active => AnalyzerStatus.idle,
        });
      });

      await _sensorService.initialiseSensor();
      _classifierService.initialize(_sensorService.sensorStream);
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

  Future<void> dipose() async {
    _sensorService.dispose();
    _classifierService.dispose();
    await _statusSubscription?.cancel();
    await _sensorSubscription?.cancel();
    await _statusController.close();
  }
}

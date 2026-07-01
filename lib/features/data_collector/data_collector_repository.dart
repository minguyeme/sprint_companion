import 'dart:async';
import '../../core/aggregate_sensor_data.dart';
import '../../core/sensor_service.dart';

enum CollectorError { activeService, activeRecording, notRecording, gpsDisabled, gpsDenied, unknown }

class DataCollectorRepository {
  final _sensorService = SensorService();
  final List<List<num>> _sensorCache = [];
  StreamSubscription<AggregateSensorData>? _sensorStream;

  Future<({bool isSucessful, CollectorError? error})>
  initialiseSession() async {
    try {
      await _sensorService.initialiseSensor();
    } catch (exception) {
      return (
        isSucessful: false,
        error: switch (exception) {
          ServiceAlreadyActiveException() => CollectorError.activeService,
          GpsDisabledException() => CollectorError.gpsDisabled,
          GpsDeniedException() => CollectorError.gpsDenied,
          _ => CollectorError.unknown,
        },
      );
    }

    return (isSucessful: true, error: null);
  }

  void cacheData(AggregateSensorData data) {
    final AggregateSensorData(:rawAccel, :cleanAccel, :gyro, :gps) = data;

    _sensorCache.add([
      rawAccel.timestamp,
      rawAccel.x,
      rawAccel.y,
      rawAccel.z,
      cleanAccel.timestamp,
      cleanAccel.x,
      cleanAccel.y,
      cleanAccel.z,
      gyro.timestamp,
      gyro.x,
      gyro.y,
      gyro.z,
      gps.timestamp,
      gps.speed,
      gps.accuracy,
    ]);
  }

  void startRecording({required void Function(CollectorError) onError}) {
    if (_sensorStream != null) onError(CollectorError.activeRecording);
    _sensorStream = _sensorService.sensorStream.listen(
      cacheData,
      onError: (error) => switch (error) {
        GpsDeniedException() => onError(CollectorError.gpsDenied),
        GpsDisabledException() => onError(CollectorError.gpsDisabled),
        _ => onError(CollectorError.unknown),
      },
    );
  }

  void stopRecording({required void Function(CollectorError) onError}) {
    if (_sensorStream == null) onError(CollectorError.notRecording);
  }
}

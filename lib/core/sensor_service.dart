import 'dart:async';
import 'dart:developer' as developer;
import 'package:rxdart/rxdart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'aggregate_sensor_data.dart';

sealed class SensorException implements Exception {}

class ServiceInactiveException extends SensorException {}

class ServiceAlreadyActiveException extends SensorException {}

class GpsDisabledException extends SensorException {}

class GpsDeniedException extends SensorException {}

class GpsPermaDeniedException extends SensorException {}

class UnknownSensorException extends SensorException {}

class SensorService {
  static final SensorService _instance = SensorService._internal();

  bool _isInitialising = false;
  final _sensorOutputController = BehaviorSubject<AggregateSensorData>();
  StreamSubscription<AggregateSensorData>? _sensorSubscription;

  factory SensorService() => _instance;
  SensorService._internal();

  Stream<AggregateSensorData> get sensorStream {
    if (_sensorSubscription == null) throw ServiceInactiveException();
    return _sensorOutputController.stream;
  }

  Future<void> initialiseSensor() async {
    try {
      if (_sensorSubscription != null || _isInitialising == true) {
        throw ServiceAlreadyActiveException();
      }

      _isInitialising = true;
      if (!(await Geolocator.isLocationServiceEnabled())) {
        throw GpsDisabledException();
      }
      if (await Geolocator.checkPermission() == LocationPermission.denied) {
        switch (await Geolocator.requestPermission()) {
          case LocationPermission.denied:
            throw GpsDeniedException();
          case LocationPermission.deniedForever:
            throw GpsPermaDeniedException();
          case LocationPermission.unableToDetermine:
            throw UnknownSensorException();
          default:
        }
      }
      _isInitialising = false;

      final Stream<AccelerometerEvent> rawAccelChannel =
          accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 10),
          );
      final Stream<UserAccelerometerEvent> cleanAccelChannel =
          userAccelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 10),
          );
      final Stream<GyroscopeEvent> gyroChannel = gyroscopeEventStream(
        samplingPeriod: const Duration(milliseconds: 10),
      );
      final Stream<Position> gpsChannel = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 1),
        ),
      );

      final Stream<TimestampedVector3D> timestampedRawAccel = rawAccelChannel
          .map(
            (event) => (
              timestamp: event.timestamp.millisecondsSinceEpoch,
              x: event.x,
              y: event.y,
              z: event.z,
            ),
          );
      final Stream<TimestampedVector3D> timestampedCleanAccel =
          cleanAccelChannel.map(
            (event) => (
              timestamp: event.timestamp.millisecondsSinceEpoch,
              x: event.x,
              y: event.y,
              z: event.z,
            ),
          );
      final Stream<TimestampedVector3D> timestampedGyro = gyroChannel.map(
        (event) => (
          timestamp: event.timestamp.millisecondsSinceEpoch,
          x: event.x,
          y: event.y,
          z: event.z,
        ),
      );
      final Stream<TimestampedGpsSpeed> timestampedSpeed = gpsChannel.map(
        (position) => (
          timestamp: position.timestamp.millisecondsSinceEpoch,
          speed: position.speed,
          accuracy: position.speedAccuracy,
        ),
      );

      _sensorSubscription =
          CombineLatestStream.combine4(
            timestampedRawAccel,
            timestampedCleanAccel,
            timestampedGyro,
            timestampedSpeed,
            (raw, clean, gyro, gps) => AggregateSensorData(
              rawAccel: raw,
              cleanAccel: clean,
              gyro: gyro,
              gps: gps,
            ),
          ).listen(
            (aggregateData) {
              _sensorOutputController.add(aggregateData);
            },
            onError: (error, stackTrace) {
              developer.log(
                'Sensor stream failure.',
                name: 'SensorService',
                error: error,
                stackTrace: stackTrace,
              );
              _sensorOutputController.addError(switch (error) {
                PermissionDeniedException() => GpsDeniedException(),
                LocationServiceDisabledException() => GpsDisabledException(),
                _ => UnknownSensorException(),
              });
              _sensorSubscription?.cancel();
              _sensorSubscription = null;
            },
          );
    } catch (exception) {
      _isInitialising = false;
      await _sensorSubscription?.cancel();
      _sensorSubscription = null;
      rethrow;
    }
  }

  void dispose() async {
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }
}

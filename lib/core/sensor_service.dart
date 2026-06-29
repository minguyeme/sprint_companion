import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'aggregate_sensor_data.dart';

sealed class SensorException implements Exception {
  final String message;
  const SensorException(this.message);

  @override
  String toString() => message;
}

class ServiceInactiveException extends SensorException {
  const ServiceInactiveException() : super('Sensor tracking is uninitialised.');
}

class ServiceAlreadyActiveException extends SensorException {
  const ServiceAlreadyActiveException()
    : super('Sensor tracking is already active.');
}

class GpsDisabledException extends SensorException {
  const GpsDisabledException()
    : super('Gps is disabled. The app needs gps to work.');
}

class GpsDeniedException extends SensorException {
  const GpsDeniedException()
    : super('Gps access is denied. The app needs gps to work.');
}

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
        if (await Geolocator.requestPermission() !=
            LocationPermission.whileInUse) {
          throw GpsDeniedException();
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
              _sensorOutputController.addError(error, stackTrace);
            },
          );
    } catch (exception) {
      _isInitialising = false;
      _sensorSubscription?.cancel();
      _sensorSubscription = null;
      rethrow;
    }
  }

  void dispose() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }
}

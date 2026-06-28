import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sprint_companion/core/aggregate_sensor_data.dart';

typedef Timestamped<T> = ({int timestamp, T data});

class SensorService {
  static final SensorService _instance = SensorService._internal();

  final _sensorOutputController = BehaviorSubject<AggregateSensorData>();

  StreamSubscription<AggregateSensorData>? _sensorSubscription;

  factory SensorService() => _instance;

  SensorService._internal();

  Stream<AggregateSensorData> get sensorStream =>
      _sensorOutputController.stream;

  void initialiseSensor() {
    if (_sensorSubscription != null) return;

    final Stream<AccelerometerEvent> rawAccelChannel =
        accelerometerEventStream();

    final Stream<UserAccelerometerEvent> cleanAccelChannel =
        userAccelerometerEventStream();

    final Stream<GyroscopeEvent> gyroChannel = gyroscopeEventStream();

    final Stream<Position> gpsChannel = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      ),
    );

    final Stream<Timestamped<Vector3D>> timestampedRawAccel = rawAccelChannel
        .map(
          (event) => (
            timestamp: event.timestamp.millisecondsSinceEpoch,
            data: (x: event.x, y: event.y, z: event.z),
          ),
        );

    final Stream<Timestamped<Vector3D>> timestampedCleanAccel =
        cleanAccelChannel.map(
          (event) => (
            timestamp: event.timestamp.millisecondsSinceEpoch,
            data: (x: event.x, y: event.y, z: event.z),
          ),
        );

    final Stream<Timestamped<Vector3D>> timestampedGyro = gyroChannel.map(
      (event) => (
        timestamp: event.timestamp.millisecondsSinceEpoch,
        data: (x: event.x, y: event.y, z: event.z),
      ),
    );

    final Stream<Timestamped<GpsSpeed>> timestampedSpeed = gpsChannel.map(
      (position) => (
        timestamp: position.timestamp.millisecondsSinceEpoch,
        data: (speed: position.speed, speedAccuracy: position.speedAccuracy),
      ),
    );

    _sensorSubscription =
        CombineLatestStream.combine4(
          timestampedRawAccel,
          timestampedCleanAccel,
          timestampedGyro,
          timestampedSpeed,
          (raw, clean, gyro, gps) => AggregateSensorData(
            gpsTimestamp: gps.timestamp,
            gps: gps.data,
            rawAccelTimestamp: raw.timestamp,
            rawAccel: raw.data,
            cleanAccelTimestamp: clean.timestamp,
            cleanAccel: clean.data,
            gyroTimestamp: gyro.timestamp,
            gyro: gyro.data,
          ),
        ).listen(
          (aggregateData) {
            _sensorOutputController.add(aggregateData);
          },
          onError: (error, stackTrace) {
            _sensorOutputController.addError(error, stackTrace);
          },
        );
  }

  void dispose() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
    _sensorOutputController.close();
  }
}

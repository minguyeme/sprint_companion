import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sprint_companion/core/aggregate_sensor_data.dart';

/// Time in microseconds, anchored to device monotonic bootclock
typedef Timestamped<T> = ({int timestamp, T data});

class SensorService {
  static final SensorService _instance = SensorService._internal();

  bool isReady = false;

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
            timestamp: event.timestamp.microsecondsSinceEpoch,
            data: (x: event.x, y: event.y, z: event.z),
          ),
        );

    final Stream<Timestamped<Vector3D>> timestampedCleanAccel =
        cleanAccelChannel.map(
          (event) => (
            timestamp: event.timestamp.microsecond,
            data: (x: event.x, y: event.y, z: event.z),
          ),
        );

    final Stream<Timestamped<Vector3D>> timestampedGyro = gyroChannel.map(
      (event) => (
        timestamp: event.timestamp.microsecond,
        data: (x: event.x, y: event.y, z: event.z),
      ),
    );

    final Stream<GpsSpeed> timestampedSpeed = gpsChannel.map(
      (position) =>
          (speed: position.speed, speedAccuracy: position.speedAccuracy),
    );
  }
}

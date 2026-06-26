import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sprint_companion/core/aggregate_sensor_data.dart';

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

    final Stream<Position> gpsChannel = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1)
      ),
    );

    final Stream<AccelerometerEvent> rawAccelChannel = accelerometerEventStream();

    final Stream<UserAccelerometerEvent> cleanAccelChannel = userAccelerometerEventStream();

    final Stream<GyroscopeEvent> gyroChannel = gyroscopeEventStream();
  }
}

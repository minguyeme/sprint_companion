import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../sensor_capture/aggregate_sensor_data.dart';
import '../sensor_capture/sensor_service.dart';

class MockSensorService implements SensorService {
  final _statusController = BehaviorSubject<SensorStatus>.seeded(
    SensorStatus.inactive,
  );
  final _sensorController = PublishSubject<AggregateSensorData>();

  StreamSubscription<AggregateSensorData>? _mockSensorSubscription;

  @override
  Stream<SensorStatus> get statusStream => _statusController.stream;

  @override
  Stream<AggregateSensorData> get sensorStream => _sensorController.stream;

  @override
  Future<void> initialiseSensor() async {
    _statusController.add(SensorStatus.initialising);
    await Future.delayed(const Duration(seconds: 2));
    _mockSensorSubscription = Stream.periodic(Duration(microseconds: 3333), (
      i,
    ) {
      final v = i.toDouble();
      return AggregateSensorData(
        rawAccel: (
          x: v,
          y: v,
          z: v,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
        cleanAccel: (
          x: v,
          y: v,
          z: v,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
        gyro: (
          x: v,
          y: v,
          z: v,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
        gps: (
          speed: v,
          accuracy: v,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }).listen(_sensorController.add);
    _statusController.add(SensorStatus.active);
  }

  @override
  Future<void> dispose() async {
    _statusController.add(SensorStatus.inactive);
    _mockSensorSubscription?.cancel();
    _mockSensorSubscription = null;
  }
}

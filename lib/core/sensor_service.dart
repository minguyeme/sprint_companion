import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'sensor_exception.dart';
import 'aggregate_sensor_data.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();

  bool _isInitialising = false;
  final _sensorOutputController = BehaviorSubject<AggregateSensorData>();
  StreamSubscription<AggregateSensorData>? _sensorSubscription;

  factory SensorService() => _instance;
  SensorService._internal();

  Stream<AggregateSensorData> get sensorStream =>
      _sensorOutputController.stream;

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
    } catch (exception, stackTrace) {
      _isInitialising = false;
      _sensorOutputController.addError(exception, stackTrace);
    }
  }

  void dispose() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
    _sensorOutputController.close();
  }
}

import 'dart:math';
import 'dart:async';
import 'dart:collection';
import 'package:rxdart/rxdart.dart';
import '../sensor_capture/aggregate_sensor_data.dart';

typedef TimestampedMagnitude = ({double magnitude, int timestamp});

extension TimestampedVector3DExtension on TimestampedVector3D {
  TimestampedMagnitude toMagnitude() =>
      (magnitude: sqrt(x * x + y * y + z * z), timestamp: timestamp);
}

enum Classification { intense, mild }

class ClassifierService {
  final _classificationController = PublishSubject<Classification>();
  final _rawAccelBuffer = ListQueue<TimestampedMagnitude>();
  final _gyroBuffer = ListQueue<TimestampedMagnitude>();
  int _latestTime = 0;
  int _oldRawAccelTimestamp = 0;
  int _oldGyroTimestamp = 0;

  StreamSubscription<AggregateSensorData>? _sensorSubscription;

  Stream<Classification> get classificationStream =>
      _classificationController.stream;

  void initialize(Stream<AggregateSensorData> sensorStream) {
    _sensorSubscription = sensorStream.listen(_process);
  }

  Future<void> dispose() async {
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }

  void _process(AggregateSensorData data) {
    final AggregateSensorData(:rawAccel, :gyro) = data;
    bool isUpdated = false;

    if (rawAccel.timestamp != _oldRawAccelTimestamp) {
      _latestTime = _oldRawAccelTimestamp = rawAccel.timestamp;
      _rawAccelBuffer.addLast(rawAccel.toMagnitude());
      isUpdated = true;
    }

    if (gyro.timestamp != _oldGyroTimestamp) {
      _latestTime = _oldGyroTimestamp = gyro.timestamp;
      _gyroBuffer.addLast(gyro.toMagnitude());
      isUpdated = true;
    }

    if (isUpdated) {
      final windowStartBoundary = _latestTime - 2000;

      while (_rawAccelBuffer.isNotEmpty &&
          _rawAccelBuffer.first.timestamp < windowStartBoundary) {
        _rawAccelBuffer.removeFirst();
      }

      while (_gyroBuffer.isNotEmpty &&
          _gyroBuffer.first.timestamp < windowStartBoundary) {
        _gyroBuffer.removeFirst();
      }
    }
  }
}

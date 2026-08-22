import 'dart:math';
import 'dart:async';
import 'dart:collection';
import 'package:rxdart/rxdart.dart';
import '../sensor_capture/aggregate_sensor_data.dart';
import 'models/binary_intensity_classifier.dart' as model;

typedef TimestampedMagnitude = ({double magnitude, int timestamp});
typedef FeatureRow = ({double rawAccelMean, double gyroStd});

extension TimestampedVector3DExtension on TimestampedVector3D {
  TimestampedMagnitude toMagnitude() =>
      (magnitude: sqrt(x * x + y * y + z * z), timestamp: timestamp);
}

enum Classification { intense, mild;
  String toJson() => name;
 }

class ClassifierService {
  final _classificationController = PublishSubject<Classification>();
  final _rawAccelBuffer = ListQueue<TimestampedMagnitude>();
  final _gyroBuffer = ListQueue<TimestampedMagnitude>();
  int _latestTime = 0;
  int _lastRawAccelTimestamp = 0;
  int _lastGyroTimestamp = 0;
  int? _nextCheckpoint;

  StreamSubscription<AggregateSensorData>? _sensorSubscription;

  Stream<Classification> get classificationStream =>
      _classificationController.stream;

  void initialize(Stream<AggregateSensorData> sensorStream) {
    _sensorSubscription?.cancel();
    _sensorSubscription = sensorStream.listen(_process);
  }

  Future<void> dispose() async {
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;
    await _classificationController.close();
  }

  void _process(AggregateSensorData data) {
    final AggregateSensorData(:rawAccel, :gyro) = data;
    bool isUpdated = false;

    if (rawAccel.timestamp != _lastRawAccelTimestamp) {
      _latestTime = _lastRawAccelTimestamp = rawAccel.timestamp;

      if (_nextCheckpoint != null && _latestTime >= _nextCheckpoint!) {
        _runPipeline();
        _nextCheckpoint = _nextCheckpoint! + 1000;
      }

      _rawAccelBuffer.addLast(rawAccel.toMagnitude());
      isUpdated = true;
    } else if (gyro.timestamp != _lastGyroTimestamp) {
      _latestTime = _lastGyroTimestamp = gyro.timestamp;

      if (_nextCheckpoint != null && _latestTime >= _nextCheckpoint!) {
        _runPipeline();
        _nextCheckpoint = _nextCheckpoint! + 1000;
      }

      _gyroBuffer.addLast(gyro.toMagnitude());
      isUpdated = true;
    }

    if (isUpdated) {
      _nextCheckpoint ??= _latestTime + 2000;

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

  void _runPipeline() {
    final featureRow = _extractFeature();
    final classification = _classify(featureRow);
    _classificationController.add(classification);
  }

  FeatureRow _extractFeature() {
    assert(
      _rawAccelBuffer.length >= 2,
      'Raw accel buffer must contain at least 2 rows.',
    );
    assert(
      _gyroBuffer.length >= 2,
      'Gyro buffer must contain at least 2 rows.',
    );

    double rawAccelSum = 0;
    for (final row in _rawAccelBuffer) {
      rawAccelSum += row.magnitude;
    }
    final double rawAccelMean = rawAccelSum / _rawAccelBuffer.length;

    double gyroSum = 0;
    for (final row in _gyroBuffer) {
      gyroSum += row.magnitude;
    }
    final double gyroMean = gyroSum / _gyroBuffer.length;

    double gyroVarianceSum = 0;
    for (final row in _gyroBuffer) {
      final deviation = row.magnitude - gyroMean;
      gyroVarianceSum += deviation * deviation;
    }
    final double gyroStd = sqrt(gyroVarianceSum / (_gyroBuffer.length - 1));

    return (rawAccelMean: rawAccelMean, gyroStd: gyroStd);
  }

  Classification _classify(FeatureRow features) {
    final List<double> input = [features.gyroStd, features.rawAccelMean];

    final [mildProbability, intenseProbability] = model.score(input);

    return intenseProbability > mildProbability
        ? Classification.intense
        : Classification.mild;
  }
}

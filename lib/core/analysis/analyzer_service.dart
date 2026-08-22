import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../sensor_capture/aggregate_sensor_data.dart';
import 'classifier_service.dart';
import 'session_sample.dart';

class Analysis {
  final String? version;
  final double? sessionDuration;
  final double? intenseDuration;
  final double? maxGForce;
  final double? fatigueIndex;
  final double? maxGpsSpeed;

  Analysis({
    this.version,
    this.sessionDuration,
    this.intenseDuration,
    this.maxGForce,
    this.fatigueIndex,
    this.maxGpsSpeed,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'session_duration': sessionDuration,
    'intense_duration': intenseDuration,
    'max_g_force': maxGForce,
    'fatigue_index': fatigueIndex,
    'max_gps_speed': maxGpsSpeed,
  };
}

class AnalyzerService {
  Future<Analysis> analyze(List<SessionSample> log) async {
    return await compute(_analyzeWorker, log);
  }
}

Analysis _analyzeWorker(List<SessionSample> log) {
  double? sessionDuration;
  double? intenseDuration;
  double? maxGForce;
  double? fatigueIndex;
  double? maxGpsSpeed;

  if (log.isNotEmpty) {
    sessionDuration = log.length * 0.02;
  }

  int intenseCount = 0;
  int? firstIntenseIndex;
  int lastIntenseIndex = 0;
  if (log.isNotEmpty) {
    for (final (int index, SessionSample(:classification)) in log.indexed) {
      if (classification == Classification.intense) {
        intenseCount += 1;
        firstIntenseIndex ??= index;
        lastIntenseIndex = index;
      }
    }
    intenseDuration = intenseCount * 0.02;
  }
  final int? intenseMidpoint =
      intenseCount > 1 &&
          (intenseCount == (lastIntenseIndex - firstIntenseIndex! + 1))
      ? firstIntenseIndex + intenseCount ~/ 2
      : null;

  if (log.isNotEmpty) {
    double maxMagnitudeSquared = 0;
    for (final SessionSample(:data) in log) {
      final AggregateSensorData(:cleanAccel) = data;

      final double magnitudeSquared =
          cleanAccel.x * cleanAccel.x +
          cleanAccel.y * cleanAccel.y +
          cleanAccel.z * cleanAccel.z;

      if (maxMagnitudeSquared < magnitudeSquared) {
        maxMagnitudeSquared = magnitudeSquared;
      }
    }
    maxGForce = sqrt(maxMagnitudeSquared) / 9.80665;
  }

  if (intenseMidpoint != null) {
    double firstSplitSum = 0;
    double lastSplitSum = 0;
    double firstSplitSize = 0;
    double lastSplitSize = 0;
    for (final (int index, SessionSample(:data, :classification))
        in log.indexed) {
      final AggregateSensorData(:cleanAccel) = data;

      if (classification == Classification.intense) {
        final double magnitude = sqrt(
          cleanAccel.x * cleanAccel.x +
              cleanAccel.y * cleanAccel.y +
              cleanAccel.z * cleanAccel.z,
        );

        if (index < intenseMidpoint) {
          firstSplitSum += magnitude;
          firstSplitSize += 1;
        } else {
          lastSplitSum += magnitude;
          lastSplitSize += 1;
        }
      }
    }
    final double firstSplitMean = firstSplitSum / firstSplitSize;
    final double lastSplitMean = lastSplitSum / lastSplitSize;

    fatigueIndex = max(0, (firstSplitMean - lastSplitMean) / firstSplitMean);
  }

  if (log.isNotEmpty) {
    maxGpsSpeed = 0;
    for (final SessionSample(:data) in log) {
      final AggregateSensorData(:gps) = data;

      if (gps.accuracy <= 2.5 && maxGpsSpeed! < gps.speed) {
        maxGpsSpeed = gps.speed;
      }
    }
    if (maxGpsSpeed! < 4) {
      maxGpsSpeed = null;
    }
  }

  return Analysis(
    version: '0.0.1',
    sessionDuration: sessionDuration,
    intenseDuration: intenseDuration,
    maxGForce: maxGForce,
    fatigueIndex: fatigueIndex,
    maxGpsSpeed: maxGpsSpeed,
  );
}

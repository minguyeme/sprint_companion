import 'dart:math';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';
import '../../core/sensor_capture/aggregate_sensor_data.dart';
import '../../core/sensor_capture/sensor_service.dart';
import '../../core/classification/classifier_service.dart';

enum AnalyzerError {
  inactiveService,
  activeService,
  activeCapture,
  gpsDisabled,
  gpsDenied,
  gpsPermaDenied,
  preciseGpsDenied,
  sensorUnknown,
}

enum AnalyzerStatus {
  inactive,
  initializing,
  idle,
  capturing,
  analyzing,
  analyzed,
}

typedef SessionSample = ({
  AggregateSensorData data,
  Classification classification,
});

typedef Analysis = ({
  double? sessionDuration,
  double? intenseDuration,
  double? maxGForce,
  double? fatigueIndex,
});

class SprintAnalyzerRepository {
  final SensorService _sensorService;
  final ClassifierService _classifierService;
  final _statusController = BehaviorSubject<AnalyzerStatus>.seeded(
    AnalyzerStatus.inactive,
  );
  final List<AggregateSensorData> _stagingBuffer = [];
  final List<SessionSample> _sessionLog = [];

  Analysis _analysis = (
    sessionDuration: null,
    intenseDuration: null,
    maxGForce: null,
    fatigueIndex: null,
  );

  StreamSubscription<AggregateSensorData>? _sensorSubscription;
  StreamSubscription<SensorStatus>? _statusSubscription;
  StreamSubscription<Classification>? _classifierSubscription;

  SprintAnalyzerRepository({
    required this._sensorService,
    required this._classifierService,
  });

  List<SessionSample> get sessionLog => List.unmodifiable(_sessionLog);
  Analysis get analysis => _analysis;

  Future<void> initialize({
    required void Function(AnalyzerError) onError,
  }) async {
    try {
      if (_statusController.value != AnalyzerStatus.inactive) {
        onError(AnalyzerError.activeService);
        return;
      }

      await _statusSubscription?.cancel();
      _statusSubscription = _sensorService.statusStream.listen((sensorStatus) {
        final AnalyzerStatus status;

        switch (sensorStatus) {
          case SensorStatus.inactive:
            reset();
            status = AnalyzerStatus.inactive;
          case SensorStatus.initialising:
            status = AnalyzerStatus.initializing;
          case SensorStatus.active:
            _classifierService.initialize(_sensorService.sensorStream);
            status = AnalyzerStatus.idle;
        }

        _statusController.add(status);
      });

      await _sensorService.initialiseSensor();
    } on SensorException catch (exception) {
      switch (exception) {
        case ServiceInactiveException():
          onError(AnalyzerError.inactiveService);
        case ServiceAlreadyActiveException():
          onError(AnalyzerError.activeService);
        case GpsDisabledException():
          onError(AnalyzerError.gpsDisabled);
        case GpsDeniedException():
          onError(AnalyzerError.gpsDenied);
        case GpsPermaDeniedException():
          onError(AnalyzerError.gpsPermaDenied);
        case PreciseGpsDeniedException():
          onError(AnalyzerError.preciseGpsDenied);
        case UnknownSensorException():
          onError(AnalyzerError.sensorUnknown);
      }
    }
  }

  void startCapture({required void Function(AnalyzerError) onError}) {
    if (_statusController.value != AnalyzerStatus.idle) {
      switch (_statusController.value) {
        case AnalyzerStatus.inactive:
          onError(AnalyzerError.inactiveService);
        default:
          onError(AnalyzerError.activeCapture);
      }
      return;
    }

    _statusController.add(AnalyzerStatus.capturing);

    _sensorSubscription = _sensorService.sensorStream
        .sampleTime(const Duration(milliseconds: 20))
        .listen(
          (data) => _stagingBuffer.add(data),
          onError: (error) => switch (error) {
            GpsDeniedException() => onError(AnalyzerError.gpsDenied),
            GpsDisabledException() => onError(AnalyzerError.gpsDisabled),
            GpsPermaDeniedException() => onError(AnalyzerError.gpsPermaDenied),
            PreciseGpsDeniedException() => onError(
              AnalyzerError.preciseGpsDenied,
            ),
            _ => onError(AnalyzerError.sensorUnknown),
          },
        );
    _classifierSubscription = _classifierService.classificationStream
        .where((_) => _statusController.value == AnalyzerStatus.capturing)
        .listen((classification) {
          _sessionLog.addAll(
            _stagingBuffer.map(
              (data) => (data: data, classification: classification),
            ),
          );
          _stagingBuffer.clear();
        });
  }

  Future<void> stopCapture({
    required void Function(AnalyzerError) onError,
  }) async {
    if (_statusController.value != AnalyzerStatus.capturing) {
      onError(AnalyzerError.inactiveService);
      return;
    }

    _statusController.add(AnalyzerStatus.analyzing);
    _stagingBuffer.clear();
    await _classifierSubscription?.cancel();
    await _sensorSubscription?.cancel();
    await _analyze(_sessionLog);
  }

  Future<void> reset() async {
    if (_statusController.value == AnalyzerStatus.inactive ||
        _statusController.value == AnalyzerStatus.initializing) {
      return;
    }

    _sessionLog.clear();
    _stagingBuffer.clear();
    await _classifierSubscription?.cancel();
    await _sensorSubscription?.cancel();
    _analysis = (
      sessionDuration: null,
      intenseDuration: null,
      maxGForce: null,
      fatigueIndex: null,
    );
    _statusController.add(AnalyzerStatus.idle);
  }

  Future<void> dispose() async {
    await _statusSubscription?.cancel();
    await _sensorSubscription?.cancel();
    await _classifierSubscription?.cancel();
    await _statusController.close();
    _sensorService.dispose();
    _classifierService.dispose();
  }

  Future<void> _analyze(List<SessionSample> log) async {
    final analysis = await compute(_analyzeWorker, log);

    if (_statusController.value != AnalyzerStatus.analyzing) {
      return;
    }

    _analysis = analysis;
    _statusController.add(AnalyzerStatus.analyzed);
  }
}

Analysis _analyzeWorker(List<SessionSample> log) {
  double? sessionDuration;
  double? intenseDuration;
  double? maxGForce;
  double? fatigueIndex;

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

  return (
    sessionDuration: sessionDuration,
    intenseDuration: intenseDuration,
    maxGForce: maxGForce,
    fatigueIndex: fatigueIndex,
  );
}

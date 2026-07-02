import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import '../../core/aggregate_sensor_data.dart';
import '../../core/sensor_service.dart';
import '../../core/file_service.dart';

enum CollectorError {
  activeService,
  activeRecording,
  noRecording,
  gpsDisabled,
  gpsDenied,
  outOfStorage,
  sensorUnknown,
  fileUnknown,
}

enum CollectorState { uninitialised, idle, recording, cached, processing }

enum SessionFlag {stationary, walk, jog, sprint}

class DataCollectorRepository {
  final _sensorService = SensorService();
  final _fileService = FileService();
  CollectorState _collectorState = CollectorState.uninitialised;
  final List<List<num>> _sensorCache = [];
  StreamSubscription<AggregateSensorData>? _sensorStream;

  Future<({bool isSucessful, CollectorError? error})>
  initialiseSession() async {
    try {
      await _sensorService.initialiseSensor();
      _collectorState = CollectorState.idle;
    } catch (exception) {
      return (
        isSucessful: false,
        error: switch (exception) {
          ServiceAlreadyActiveException() => CollectorError.activeService,
          GpsDisabledException() => CollectorError.gpsDisabled,
          GpsDeniedException() => CollectorError.gpsDenied,
          _ => CollectorError.sensorUnknown,
        },
      );
    }

    return (isSucessful: true, error: null);
  }

  void startRecording({required void Function(CollectorError) onError}) {
    if (_collectorState != CollectorState.idle) {
      onError(CollectorError.activeRecording);
    }
    _sensorStream = _sensorService.sensorStream.listen(
      _cacheData,
      onError: (error) => switch (error) {
        GpsDeniedException() => onError(CollectorError.gpsDenied),
        GpsDisabledException() => onError(CollectorError.gpsDisabled),
        _ => onError(CollectorError.sensorUnknown),
      },
    );
    _collectorState = CollectorState.recording;
  }

  Future<void> stopRecording({
    required void Function(CollectorError) onError,
  }) async {
    if (_collectorState != CollectorState.recording || _sensorCache.isEmpty) {
      onError(CollectorError.noRecording);
      return;
    }
    _collectorState = CollectorState.cached;
    await _sensorStream?.cancel();
    _sensorStream = null;
  }

  Future<void> saveCache({
    String? name,
    required SessionFlag flag,
    required void Function(CollectorError) onError,
    required void Function() onCompletion,
  }) async {
    try {
      if (_collectorState != CollectorState.cached) {
        onError(CollectorError.noRecording);
        return;
      }
      final String resolvedName = _resolveName(name, flag);

      String csvString = await compute(_toCsvWorker, _sensorCache);
      await _fileService.saveUserData(
        csvString,
        fileName: resolvedName,
        type: FileType.dataset,
      );
      onCompletion();
      _sensorCache.clear();
      _collectorState = CollectorState.idle;
    } catch (exception) {
      switch (exception) {
        case OutOfStorageException():
          onError(CollectorError.outOfStorage);
        case UnknownStorageException():
          onError(CollectorError.fileUnknown);
      }
    }
  }

  String _resolveName(String? name, SessionFlag flag) {
    //TODO
    throw UnimplementedError();
  }

  void _cacheData(AggregateSensorData data) {
    if (_collectorState != CollectorState.recording) return;

    final AggregateSensorData(:rawAccel, :cleanAccel, :gyro, :gps) = data;

    _sensorCache.add([
      rawAccel.timestamp,
      rawAccel.x,
      rawAccel.y,
      rawAccel.z,
      cleanAccel.timestamp,
      cleanAccel.x,
      cleanAccel.y,
      cleanAccel.z,
      gyro.timestamp,
      gyro.x,
      gyro.y,
      gyro.z,
      gps.timestamp,
      gps.speed,
      gps.accuracy,
    ]);
  }
}

Future<String> _toCsvWorker(List<List<num>> matrix) async {
  final List<List<dynamic>> csvMatrix = [
    [
      'raw_accel_timestamp',
      'raw_accel_x',
      'raw_accel_y',
      'raw_accel_z',
      'clean_accel_timestamp',
      'clean_accel_x',
      'clean_accel_y',
      'clean_accel_z',
      'gyro_timestamp',
      'gyro_x',
      'gyro_y',
      'gyro_z',
      'gps_timestamp',
      'speed',
      'speed_accuracy',
    ],
    ...matrix,
  ];
  return csv.encode(csvMatrix);
}

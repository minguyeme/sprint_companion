import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import '../../core/aggregate_sensor_data.dart';
import '../../core/sensor_service.dart';
import '../../core/file_service.dart';

enum CollectorError {
  activeService,
  activeRecording,
  notRecording,
  gpsDisabled,
  gpsDenied,
  outOfStorage,
  sensorUnknown,
  fileUnknown,
}

class DataCollectorRepository {
  final _sensorService = SensorService();
  final _fileService = FileService();
  final List<List<num>> _sensorCache = [];
  StreamSubscription<AggregateSensorData>? _sensorStream;

  Future<({bool isSucessful, CollectorError? error})>
  initialiseSession() async {
    try {
      await _sensorService.initialiseSensor();
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

  void cacheData(AggregateSensorData data) {
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

  void startRecording({required void Function(CollectorError) onError}) {
    if (_sensorStream != null) onError(CollectorError.activeRecording);
    _sensorStream = _sensorService.sensorStream.listen(
      cacheData,
      onError: (error) => switch (error) {
        GpsDeniedException() => onError(CollectorError.gpsDenied),
        GpsDisabledException() => onError(CollectorError.gpsDisabled),
        _ => onError(CollectorError.sensorUnknown),
      },
    );
  }

  Future<void> stopRecording({
    required void Function(CollectorError) onError,
  }) async {
    if (_sensorStream == null || _sensorCache.isEmpty) {
      onError(CollectorError.notRecording);
      return;
    }
    await _sensorStream?.cancel();
    _sensorStream = null;
  }

  Future<void> saveCache({
    required void Function(CollectorError) onError,
    required void Function() onCompletion,
  }) async {
    try {
      if (_sensorStream != null) onError(CollectorError.activeRecording);
      String csvString = await compute(_toCsvWorker, _sensorCache);
      await _fileService.saveUserData(
        csvString,
        fileName: '',
        type: FileType.dataset,
      );
      onCompletion();
      _sensorCache.clear();
    } catch (exception) {
      switch (exception) {
        case OutOfStorageException():
          onError(CollectorError.outOfStorage);
        case UnknownStorageException():
          onError(CollectorError.fileUnknown);
      }
    }
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

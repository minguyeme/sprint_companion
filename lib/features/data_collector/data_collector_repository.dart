import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:csv/csv.dart';
import '../../core/aggregate_sensor_data.dart';
import '../../core/sensor_service.dart';
import '../../core/file_service.dart';

enum CollectorError {
  inactiveService,
  activeService,
  activeRecording,
  noRecording,
  noCache,
  gpsDisabled,
  gpsDenied,
  gpsPermaDenied,
  preciseGpsDenied,
  outOfStorage,
  sensorUnknown,
  fileUnknown,
}

enum CollectorStatus {
  inactive,
  initialising,
  idle,
  recording,
  cached,
  processing,
}

enum SessionFlag { stationary, walk, jog, sprint }

class DataCollectorRepository {
  final _sensorService = SensorService();
  final _fileService = FileService();
  final _statusController = BehaviorSubject<CollectorStatus>.seeded(
    CollectorStatus.inactive,
  );
  final List<List<num>> _sensorCache = [];
  StreamSubscription<AggregateSensorData>? _sensorSubscription;
  StreamSubscription<SensorStatus>? _statusSubscription;

  Stream<CollectorStatus> get statusStream => _statusController.stream;

  Future<void> initialiseSession({
    required void Function(CollectorError) onError,
  }) async {
    try {
      if (_statusController.value != CollectorStatus.inactive) {
        onError(CollectorError.activeService);
        return;
      }
      _statusSubscription = _sensorService.statusStream.listen((sensorStatus) {
        _statusController.add(switch (sensorStatus) {
          SensorStatus.inactive => CollectorStatus.inactive,
          SensorStatus.initialising => CollectorStatus.initialising,
          SensorStatus.active => CollectorStatus.idle,
        });
      });
      await _sensorService.initialiseSensor();
    } on SensorException catch (exception) {
      switch (exception) {
        case ServiceInactiveException():
          onError(CollectorError.inactiveService);
        case ServiceAlreadyActiveException():
          onError(CollectorError.activeService);
        case GpsDisabledException():
          onError(CollectorError.gpsDisabled);
        case GpsDeniedException():
          onError(CollectorError.gpsDenied);
        case GpsPermaDeniedException():
          onError(CollectorError.gpsPermaDenied);
        case PreciseGpsDeniedException():
          onError(CollectorError.preciseGpsDenied);
        case UnknownSensorException():
          onError(CollectorError.sensorUnknown);
      }
    }
  }

  void startRecording({required void Function(CollectorError) onError}) {
    if (_statusController.value != CollectorStatus.idle) {
      switch (_statusController.value) {
        case CollectorStatus.inactive:
          onError(CollectorError.inactiveService);
        default:
          onError(CollectorError.activeRecording);
      }
      return;
    }
    _sensorSubscription = _sensorService.sensorStream
        .where((_) => _statusController.value == CollectorStatus.recording)
        .listen(
          _cacheData,
          onError: (error) => switch (error) {
            GpsDeniedException() => onError(CollectorError.gpsDenied),
            GpsDisabledException() => onError(CollectorError.gpsDisabled),
            GpsPermaDeniedException() => onError(CollectorError.gpsPermaDenied),
            PreciseGpsDeniedException() => onError(
              CollectorError.preciseGpsDenied,
            ),
            _ => onError(CollectorError.sensorUnknown),
          },
        );
    _statusController.add(CollectorStatus.recording);
  }

  Future<void> stopRecording({
    required void Function(CollectorError) onError,
  }) async {
    if (_statusController.value != CollectorStatus.recording) {
      switch (_statusController.value) {
        case CollectorStatus.inactive:
          onError(CollectorError.inactiveService);
        default:
          onError(CollectorError.noRecording);
      }
      return;
    }
    _statusController.add(CollectorStatus.cached);
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }

  Future<void> saveCache({
    String? name,
    required SessionFlag flag,
    required void Function(CollectorError) onError,
  }) async {
    try {
      if (_statusController.value != CollectorStatus.cached) {
      switch (_statusController.value) {
        case CollectorStatus.inactive:
          onError(CollectorError.inactiveService);
        default:
          onError(CollectorError.noCache);
      }
      return;
    }
      _statusController.add(CollectorStatus.processing);
      final String resolvedName = _resolveName(name, flag);
      String csvString = await compute(_toCsvWorker, _sensorCache);
      await _fileService.saveUserData(
        csvString,
        fileName: resolvedName,
        type: FileType.dataset,
      );
      _sensorCache.clear();
      _statusController.add(CollectorStatus.idle);
    } on FileException catch (exception) {
      switch (exception) {
        case OutOfStorageException():
          onError(CollectorError.outOfStorage);
        case UnknownStorageException():
          onError(CollectorError.fileUnknown);
      }
    }
  }

  Future<void> dispose() async {
    _sensorService.dispose();
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;
    _sensorCache.clear();
  }

  String _resolveName(String? name, SessionFlag flag) {
    //TODO
    throw UnimplementedError();
  }

  void _cacheData(AggregateSensorData data) {
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

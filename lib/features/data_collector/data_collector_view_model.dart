import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/file_storage/file_service.dart';
import '../../core/file_storage/managed_file_data.dart';
import '../../core/file_storage/file_management_repository.dart';
import 'data_collector_repository.dart';

class DataCollectorViewModel extends ChangeNotifier {
  final nameController = TextEditingController();
  final FileManagementRepository _fileRepository;
  final DataCollectorRepository _collectorRepository;

  StreamSubscription<FileManagementStatus>? _fileStatusSubscription;
  StreamSubscription<List<ManagedFileData>>? _managedFilesSubscription;
  StreamSubscription<CollectorStatus>? _collectorStatusSubscription;
  String _statusMessage = 'Awaiting sensors';

  FileManagementStatus _fileStatus = FileManagementStatus.inactive;
  CollectorStatus _collectorStatus = CollectorStatus.inactive;
  var _cachedInfo = (rows: 0, maxSpeed: 0.0, maxSpeedAccuracy: 0.0);
  List<ManagedFileData> _savedDatasets = [];

  DataCollectorViewModel({
    required this._fileRepository,
    required this._collectorRepository,
  }) {
    _fileStatusSubscription = _fileRepository.statusStream.listen((status) {
      _fileStatus = status;
      notifyListeners();
    });

    _managedFilesSubscription = _fileRepository.managedFilesStream.listen((
      list,
    ) {
      _savedDatasets = list;
      notifyListeners();
    });

    _collectorStatusSubscription = _collectorRepository.statusStream.listen((
      status,
    ) {
      _collectorStatus = status;
      switch (_collectorStatus) {
        case CollectorStatus.idle:
          nameController.clear();
          _cachedInfo = (rows: 0, maxSpeed: 0.0, maxSpeedAccuracy: 0.0);
        case CollectorStatus.cached:
          _cachedInfo = _collectorRepository.cacheInfo();
        default:
      }
      notifyListeners();
    });
  }

  FileManagementStatus get fileStatus => _fileStatus;
  CollectorStatus get collectorStatus => _collectorStatus;
  List<ManagedFileData> get savedDatasets => _savedDatasets;
  String get statusMessage => _statusMessage;

  ({String rows, String maxSpeed, String maxSpeedAccuracy}) get cacheInfo => (
    rows: '${_cachedInfo.rows} rows',
    maxSpeed: '${_cachedInfo.maxSpeed.toStringAsFixed(2)} m/s',
    maxSpeedAccuracy:
        '± ${_cachedInfo.maxSpeedAccuracy.toStringAsFixed(2)} m/s',
  );

  void initialiseScreen() {
    if (_fileStatus == FileManagementStatus.inactive) {
      _fileRepository.initialiseFor(
        FileType.dataset,
        onError: _handleFileError,
      );
    }
    if (_collectorStatus == CollectorStatus.inactive) {
      _collectorRepository.initialiseSession(onError: _handleCollectorError);
    }
  }

  void handlePrimaryButtonPress() {
    switch (_collectorStatus) {
      case CollectorStatus.idle:
        _collectorRepository.startRecording(onError: _handleCollectorError);
      case CollectorStatus.recording:
        _collectorRepository.stopRecording(onError: _handleCollectorError);
      case CollectorStatus.cached:
        final name = nameController.text.trim();
        _collectorRepository.saveCache(
          name: name.isEmpty ? null : name,
          onError: _handleCollectorError,
        );
      default:
    }
  }

  void handleDelete(ManagedFileData file) {
    _fileRepository.delete(file, onError: _handleFileError);
  }

  void handleRename(ManagedFileData file, {required String name}) {
    _fileRepository.rename(file, newName: name, onError: _handleFileError);
  }

  void handleShare(ManagedFileData file) {
    _fileRepository.share(
      file,
      onResult: (bool isSucessful) {
        if (isSucessful) {
          _statusMessage = 'File shared successfully.';
        } else {
          _statusMessage = 'Failed to share file.';
        }
        notifyListeners();
      },
    );
  }

  void _handleFileError(FileManagementError error) {
    _statusMessage = switch (error) {
      FileManagementError.alreadyActive =>
        'A file management instance is already running.',
      FileManagementError.unknownFile =>
        'Could not read or write data. Please check your storage availability.',
    };
    notifyListeners();
  }

  void _handleCollectorError(CollectorError error) {
    _statusMessage = switch (error) {
      CollectorError.inactiveService =>
        'Collector is uninitialised. Please initialise or restart the page',

      CollectorError.activeService =>
        'A collection session is already running.',

      CollectorError.activeRecording =>
        'Cannot perform action while recording is actively running.',

      CollectorError.noRecording =>
        'No active recording session was found to stop or save.',

      CollectorError.gpsDisabled =>
        'GPS is turned off. Please enable location services.',

      CollectorError.gpsDenied =>
        'Location permission denied. The app needs gps to function.',

      CollectorError.gpsPermaDenied =>
        'Location access is blocked. Please enable it in your device\'s settings',

      CollectorError.preciseGpsDenied =>
        'Precise location is required. Please allow precise location.',

      CollectorError.outOfStorage =>
        'Storage is full. Please clear some space on your device.',

      CollectorError.sensorUnknown =>
        'Failed to connect to tracking sensors. Please restart the app.',

      CollectorError.fileUnknown =>
        'Could not read or write data. Please check your storage availability.',
    };
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    _fileStatusSubscription?.cancel();
    _managedFilesSubscription?.cancel();
    _collectorStatusSubscription?.cancel();
    super.dispose();
  }
}

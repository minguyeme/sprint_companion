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
  String? _statusMessage;
  bool _isFailure = false;

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
  String? get statusMessage => _statusMessage;
  bool get isFailure => _isFailure;

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
    _statusMessage = null;
    _isFailure = false;
  }

  void handleDelete(ManagedFileData file) {
    _fileRepository.delete(file, onError: _handleFileError);
  }

  void handleRename(ManagedFileData file, {required String name}) {
    _fileRepository.rename(file, newName: name, onError: _handleFileError);
  }

  void handleShare(ManagedFileData file) {
    _fileRepository.shareFiles(
      [file],
      onResult: (bool isSucessful) {
        if (isSucessful) {
          _statusMessage = 'Dataset shared successfully';
        } else {
          _statusMessage = 'Failed to share dataset';
          _isFailure = true;
        }
        notifyListeners();
      },
    );
  }

  void handleBulkShare() {
    if (savedDatasets.isEmpty) {
      _statusMessage = 'No datasets to share';
      _isFailure = true;
      notifyListeners();
      return;
    }
    _fileRepository.shareFiles(
      savedDatasets,
      onResult: (bool isSucessful) {
        if (isSucessful) {
          _statusMessage = 'Datasets shared successfully';
        } else {
          _statusMessage = 'Failed to share datasets';
          _isFailure = true;
        }
        notifyListeners();
      },
    );
  }

  void _handleFileError(FileManagementError error) {
    _statusMessage = switch (error) {
      FileManagementError.alreadyActive => 'File management already active',
      FileManagementError.unknownFile => 'Unknown storage failure',
    };
    notifyListeners();
  }

  void _handleCollectorError(CollectorError error) {
    _statusMessage = switch (error) {
      CollectorError.inactiveService => 'Collector is uninitialised',

      CollectorError.activeService => 'Collector already initialised',

      CollectorError.activeRecording => 'Collector is recording',

      CollectorError.noRecording => 'Collector not recording',

      CollectorError.gpsDisabled => 'Location service is off',

      CollectorError.gpsDenied => 'GPS permission denied',

      CollectorError.gpsPermaDenied => 'GPS use is permanently blocked',

      CollectorError.preciseGpsDenied => 'Precise location is blocked',

      CollectorError.outOfStorage => 'Storage is full',

      CollectorError.sensorUnknown => 'Unknown sensor failure',

      CollectorError.fileUnknown => 'Unknown storage failure',
    };
    _isFailure = true;
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

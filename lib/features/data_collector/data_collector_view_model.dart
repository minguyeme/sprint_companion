import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sprint_companion/core/file_storage/file_service.dart';
import 'package:sprint_companion/core/file_storage/managed_file_data.dart';
import 'data_collector_repository.dart';
import '../../core/file_storage/file_management_repository.dart';

class DataCollectorViewModel extends ChangeNotifier {
  final nameController = TextEditingController();
  final FileManagementRepository _fileRepository;
  final DataCollectorRepository _collectorRepository;

  StreamSubscription<FileManagementStatus>? _fileStatusSubscription;
  StreamSubscription<List<ManagedFileData>>? _managedFilesSubscription;
  StreamSubscription<CollectorStatus>? _collectorStatusSubscription;

  FileManagementStatus _fileStatus = FileManagementStatus.inactive;
  CollectorStatus _collectorStatus = CollectorStatus.inactive;
  var _cachedInfo = (rows: 0, maxSpeed: 0.0, maxSpeedAccuracy: 0.0);
  List<ManagedFileData> _savedDatasets = [];
  SessionFlag _selectedFlag = SessionFlag.sprint;

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

  SessionFlag get selectedFlag => _selectedFlag;
  set selectedFlag(SessionFlag flag) {
    _selectedFlag = flag;
    notifyListeners();
  }

  ({String rows, String maxSpeed, String maxSpeedAccuracy}) get cacheInfo => (
    rows: '${_cachedInfo.rows} rows',
    maxSpeed: '${_cachedInfo.maxSpeed.toStringAsFixed(2)} m/s',
    maxSpeedAccuracy:
        '± ${_cachedInfo.maxSpeedAccuracy.toStringAsFixed(2)} m/s',
  );

  void initialiseScreen({
    required void Function(CollectorError) uiOnCollectorError,
    required void Function(FileManagementError) uiOnFileError,
  }) {
    if (_fileStatus == FileManagementStatus.inactive) {
      _fileRepository.initialiseFor(FileType.dataset, onError: uiOnFileError);
    }
    if (_collectorStatus == CollectorStatus.inactive) {
      _collectorRepository.initialiseSession(onError: uiOnCollectorError);
    }
  }

  void handlePrimaryButtonPress({
    required void Function(CollectorError) uiOnError,
  }) {
    switch (_collectorStatus) {
      case CollectorStatus.idle:
        _collectorRepository.startRecording(onError: uiOnError);
      case CollectorStatus.recording:
        _collectorRepository.stopRecording(onError: uiOnError);
      case CollectorStatus.cached:
        final name = nameController.text.trim();
        _collectorRepository.saveCache(
          name: name.isEmpty ? null : name,
          flag: _selectedFlag,
          onError: uiOnError,
        );
      default:
    }
  }

  void handleDelete(
    ManagedFileData file, {
    required void Function(FileManagementError) uiOnError,
  }) {
    _fileRepository.delete(file, onError: uiOnError);
  }

  void handleRename(
    ManagedFileData file, {
    required String name,
    required void Function(FileManagementError) uiOnError,
  }) {
    _fileRepository.rename(file, newName: name, onError: uiOnError);
  }

  void handleShare(
    ManagedFileData file, {
    required void Function(bool) uiOnResult,
  }) {
    _fileRepository.share(file, onResult: uiOnResult);
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

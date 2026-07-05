import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sprint_companion/core/file_storage/file_service.dart';
import 'package:sprint_companion/core/file_storage/managed_file_data.dart';
import 'data_collector_repository.dart';
import '../../core/file_storage/file_management_repository.dart';

class DataCollectorViewModel extends ChangeNotifier {
  final FileManagementRepository _fileRepository;
  final DataCollectorRepository _collectorRepository;

  StreamSubscription<FileManagementStatus>? _fileStatusSubscription;
  StreamSubscription<CollectorStatus>? _collectorStatusSubscription;

  FileManagementStatus _fileStatus = FileManagementStatus.inactive;
  CollectorStatus _collectorStatus = CollectorStatus.inactive;
  List<ManagedFileData> _managedFiles = [];
  SessionFlag _selectedFlag = SessionFlag.sprint;

  DataCollectorViewModel({
    required this._fileRepository,
    required this._collectorRepository,
  }) {
    _fileStatusSubscription = _fileRepository.statusStream.listen((status) {
      _fileStatus = status;
      notifyListeners();
    });
    _collectorStatusSubscription = _collectorRepository.statusStream.listen((
      status,
    ) {
      _collectorStatus = status;
      notifyListeners();
    });
  }

  FileManagementStatus get fileStatus => _fileStatus;
  CollectorStatus get collectorStatus => _collectorStatus;
  List<ManagedFileData> get managedFiles => _managedFiles;
  SessionFlag get selectedFlag => _selectedFlag;

  void initialiseScreen({
    required void Function(CollectorError) uiOnCollectorError,
    required void Function(FileManagementError) uiOnFileError,
  }) {
    if (_fileStatus != FileManagementStatus.inactive) {
      _fileRepository.initialiseFor(FileType.dataset, onError: uiOnFileError);
    }
    if (_collectorStatus != CollectorStatus.inactive) {
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
        _collectorRepository.saveCache(
          name: 'name',
          flag: _selectedFlag,
          onError: uiOnError,
        );
      default:
    }
  }

  @override
  void dispose() {
    _fileStatusSubscription?.cancel();
    _collectorStatusSubscription?.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'active_session_repository.dart';

class ActiveSessionViewModel extends ChangeNotifier {
  final ActiveSessionRepository _activeSessionRepository;
  final _eventController = PublishSubject();

  StreamSubscription<ActiveSessionStatus>? _activeStatusSubscription;

  ActiveSessionStatus _status = ActiveSessionStatus.inactive;

  ActiveSessionViewModel({required this._activeSessionRepository}) {
    _activeStatusSubscription = _activeSessionRepository.statusStream.listen((
      status,
    ) {
      _status = status;
      notifyListeners();
    });
  }

  void initialize() {
    if (_status == ActiveSessionStatus.inactive) {
      _activeSessionRepository.initialize(onError: _handleActiveError);
    }
  }

  void handlePrimaryButtonPress() {
    switch (_status) {
      case ActiveSessionStatus.idle:
        _activeSessionRepository.startCapture(onError: _handleActiveError);
      case ActiveSessionStatus.capturing:
        _activeSessionRepository.stopCapture(onError: _handleActiveError);
      case ActiveSessionStatus.analyzed:
        _activeSessionRepository.save(onError: _handleActiveError);
      default:
    }
  }

  void _handleActiveError(ActiveSessionError error) {
    _eventController.add(switch (error) {
      ActiveSessionError.inactiveService => 'Current session is uninitialised',

      ActiveSessionError.activeService => 'Current session already initialised',

      ActiveSessionError.activeCapture => 'Current session already capturing',

      ActiveSessionError.noCapture => 'Current session is not captured',

      ActiveSessionError.noResult => 'Current session has no results available',

      ActiveSessionError.gpsDisabled => 'Your location service is off',

      ActiveSessionError.gpsDenied => 'GPS permission denied for this app',

      ActiveSessionError.gpsPermaDenied => 'GPS use is permanently blocked',

      ActiveSessionError.preciseGpsDenied => 'Precise location is blocked',

      ActiveSessionError.outOfStorage => 'Your storage is full',

      ActiveSessionError.sensorUnknown => 'Unknown sensor failure',

      ActiveSessionError.fileUnknown => 'Unknown storage failure',
    });
  }

  @override
  void dispose() {
    _activeStatusSubscription?.cancel();
    _eventController.close();
    super.dispose();
  }
}

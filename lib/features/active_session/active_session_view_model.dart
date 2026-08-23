import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'active_session_repository.dart';
import '../../core/analysis/analysis.dart';

typedef AnalysisUi = ({
  String version,
  String sessionDuration,
  String intenseDuration,
  String maxGForce,
  String fatigueIndex,
  String maxGpsSpeed,
});

class ActiveSessionViewModel extends ChangeNotifier {
  final ActiveSessionRepository _activeSessionRepository;
  final _eventController = PublishSubject();

  StreamSubscription<ActiveSessionStatus>? _activeStatusSubscription;

  ActiveSessionStatus _status = ActiveSessionStatus.inactive;
  Analysis _analysis = Analysis();

  ActiveSessionViewModel({required this._activeSessionRepository}) {
    _activeStatusSubscription = _activeSessionRepository.statusStream.listen((
      status,
    ) {
      if (status == ActiveSessionStatus.analyzed) {
        _analysis = _activeSessionRepository.analysis;
      }

      _status = status;
      notifyListeners();
    });
  }
  
  ActiveSessionStatus get status => _status;
  AnalysisUi get analysisUi => (
    version: _analysis.version ?? 'Unknown Version',
    sessionDuration: _analysis.sessionDuration != null
        ? '${_analysis.sessionDuration!.toStringAsFixed(1)}s'
        : 'Unable to generate',
    intenseDuration: _analysis.intenseDuration != null
        ? '${_analysis.intenseDuration!.toStringAsFixed(1)}s'
        : 'Unable to generate',
    maxGForce: _analysis.maxGForce != null
        ? '${_analysis.maxGForce!.toStringAsFixed(2)} G'
        : 'Unable to generate',
    fatigueIndex: _analysis.fatigueIndex != null
        ? '${(_analysis.fatigueIndex! * 100).toStringAsFixed(0)}%'
        : 'Unable to generate',
    maxGpsSpeed: _analysis.maxGpsSpeed != null
        ? '${_analysis.maxGpsSpeed!.toStringAsFixed(1)} m/s'
        : 'Unreliable gps data',
  );
  
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

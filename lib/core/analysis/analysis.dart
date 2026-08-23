class Analysis {
  final String? version;
  final double? sessionDuration;
  final double? intenseDuration;
  final double? maxGForce;
  final double? fatigueIndex;
  final double? maxGpsSpeed;

  Analysis({
    this.version,
    this.sessionDuration,
    this.intenseDuration,
    this.maxGForce,
    this.fatigueIndex,
    this.maxGpsSpeed,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'session_duration': sessionDuration,
    'intense_duration': intenseDuration,
    'max_g_force': maxGForce,
    'fatigue_index': fatigueIndex,
    'max_gps_speed': maxGpsSpeed,
  };
}

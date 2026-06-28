sealed class SensorException implements Exception {
  final String message;
  const SensorException(this.message);

  @override
  String toString() => message;
}

class ServiceAlreadyActiveException extends SensorException {
  const ServiceAlreadyActiveException() : super('Sensors tracking are already active.');
}

class GpsDisabledException extends SensorException {
  const GpsDisabledException() : super('Gps is disabled. The app needs gps to work.');
}

class GpsDeniedException extends SensorException {
  const GpsDeniedException() : super('Gps access is denied. The app needs gps to work.');
}

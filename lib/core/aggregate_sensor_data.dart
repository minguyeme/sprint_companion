typedef Vector3D = ({double x, double y, double z});
typedef GpsData = ({
  double longitude,
  double latitude,
  double altitude,
  double gpsAccuracy,
  double speed,
  double speedAccuracy,
  double heading,
});

/// Data model containing a snapshot of GPS, accelerometer and gyroscope sensor data.
class AggregateSensorData {
  final DateTime masterTimestamp;

  final DateTime gpsTimestamp;
  final GpsData  gps;

  final DateTime rawAccelTimestamp;
  final Vector3D rawAccel;

  final DateTime cleanAccelTimestamp;
  final Vector3D cleanAccel;

  final DateTime gyroTimestamp;
  final Vector3D gyro;

  AggregateSensorData({
    required this.masterTimestamp,
    required this.gpsTimestamp,
    required this.gps,
    required this.rawAccelTimestamp,
    required this.rawAccel,
    required this.cleanAccelTimestamp,
    required this.cleanAccel,
    required this.gyroTimestamp,
    required this.gyro,
  });
}

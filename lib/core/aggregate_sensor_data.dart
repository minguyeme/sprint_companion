typedef Vector3D = ({double x, double y, double z});
typedef GpsSpeed = ({double speed, double speedAccuracy});

/// Data model containing a snapshot of GPS, accelerometer and gyroscope sensor data.
/// Timestamped in milliseconds since unix epoch.
class AggregateSensorData {
  final int gpsTimestamp;
  final GpsSpeed gps;

  final int rawAccelTimestamp;
  final Vector3D rawAccel;

  final int cleanAccelTimestamp;
  final Vector3D cleanAccel;

  final int gyroTimestamp;
  final Vector3D gyro;

  AggregateSensorData({
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

typedef TimestampedVector3D = ({double x, double y, double z, int timestamp});
typedef TimestampedGpsSpeed = ({
  double speed,
  double accuracy,
  int timestamp,
});

/// Data model containing a snapshot of GPS, accelerometer and gyroscope sensor data.
/// Timestamped in milliseconds since unix epoch.
class AggregateSensorData {
  final TimestampedVector3D rawAccel;
  final TimestampedVector3D cleanAccel;
  final TimestampedVector3D gyro;
  final TimestampedGpsSpeed gps;

  AggregateSensorData({
    required this.gps,
    required this.rawAccel,
    required this.cleanAccel,
    required this.gyro,
  });
}

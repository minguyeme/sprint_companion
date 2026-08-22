typedef TimestampedVector3D = ({double x, double y, double z, int timestamp});
typedef TimestampedGpsSpeed = ({double speed, double accuracy, int timestamp});

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

  Map<String, dynamic> toJson() => {
    'raw_accel_timestamp': rawAccel.timestamp,
    'raw_accel_x': rawAccel.x,
    'raw_accel_y': rawAccel.y,
    'raw_accel_z': rawAccel.z,
    'clean_accel_timestamp': cleanAccel.timestamp,
    'clean_accel_x': cleanAccel.x,
    'clean_accel_y': cleanAccel.y,
    'clean_accel_z': cleanAccel.z,
    'gyro_timestamp': gyro.timestamp,
    'gyro_x': gyro.x,
    'gyro_y': gyro.y,
    'gyro_z': gyro.z,
    'gps_timestamp': gps.timestamp,
    'gps_speed': gps.speed,
    'gps_accuracy': gps.accuracy,
  };
}

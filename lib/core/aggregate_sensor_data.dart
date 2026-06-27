typedef Vector3D = ({double x, double y, double z});
typedef GpsSpeed = ({double speed, double speedAccuracy});

/// Data model containing a snapshot of GPS, accelerometer and gyroscope sensor data.
class AggregateSensorData {
  final int masterTimestamp;

  final GpsSpeed speed;

  final int rawAccelTimestamp;
  final Vector3D rawAccel;

  final int cleanAccelTimestamp;
  final Vector3D cleanAccel;

  final int gyroTimestamp;
  final Vector3D gyro;

  AggregateSensorData({
    required this.masterTimestamp,
    required this.speed,
    required this.rawAccelTimestamp,
    required this.rawAccel,
    required this.cleanAccelTimestamp,
    required this.cleanAccel,
    required this.gyroTimestamp,
    required this.gyro,
  });
}

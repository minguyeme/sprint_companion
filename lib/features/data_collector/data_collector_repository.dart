import 'dart:async';
import '../../core/aggregate_sensor_data.dart';
import '../../core/sensor_service.dart';

enum SessionError { activeService, gpsDisabled, gpsDenied, unknown }

class DataCollectorRepository {
  final _sensorService = SensorService();

  StreamSubscription<AggregateSensorData>? _sensorStream;

  Future<({bool isSucessful, String? errorMessage})> initialiseSession() async {
    try {
      await _sensorService.initialiseSensor();
    } catch (exception) {
      return (isSucessful: false, errorMessage: exception.toString());
    }
    return (isSucessful: true, errorMessage: null);
  }
}

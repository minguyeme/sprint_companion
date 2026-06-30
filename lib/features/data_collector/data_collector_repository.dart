import 'dart:io';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/aggregate_sensor_data.dart';
import '../../core/sensor_service.dart';

enum CollectorError { activeService, gpsDisabled, gpsDenied, unknown }

class DataCollectorRepository {
  final _sensorService = SensorService();
  StreamSubscription<AggregateSensorData>? _sensorStream;
  List<List<num>> _sensorCache = [];

  Future<({bool isSucessful, CollectorError? error})>
  initialiseSession() async {
    try {
      await _sensorService.initialiseSensor();
    } catch (exception, stackTrace) {
      developer.log(
        'Initialisation failed',
        error: exception,
        stackTrace: stackTrace,
      );
      return (
        isSucessful: false,
        error: switch (exception) {
          ServiceAlreadyActiveException() => CollectorError.activeService,
          GpsDisabledException() => CollectorError.gpsDisabled,
          GpsDeniedException() => CollectorError.gpsDenied,
          _ => CollectorError.unknown,
        },
      );
    }

    return (isSucessful: true, error: null);
  }

  void _clearCache() {
    _sensorCache = [];
  }
}

import 'classifier_service.dart';
import '../sensor_capture/aggregate_sensor_data.dart';

class SessionSample {
  final AggregateSensorData data;
  final Classification classification;

  SessionSample({required this.data, required this.classification});

  Map<String, dynamic> toJson() => {
    'data': data.toJson(),
    'classification': classification.toJson(),
  };
}

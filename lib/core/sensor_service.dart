import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();

  bool isReady = false;

  factory SensorService() => _instance;

  SensorService._internal();
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'features/data_collector/data_collector_repository.dart';
import 'features/data_collector/data_collector_view.dart';
import 'core/file_storage/file_management_repository.dart';
import 'core/file_storage/file_service.dart';
import 'core/sensor_capture/sensor_service.dart';
import 'core/desktop_mock/mock_file_service.dart';
import 'core/desktop_mock/mock_sensor_service.dart';

void main() {
  final FileService fileService;
  final SensorService sensorService;

  if (Platform.isAndroid) {
    fileService = FileService();
    sensorService = SensorService();
  } else {
    fileService = MockFileService();
    sensorService = MockSensorService();
  }
  final fileRepository = FileManagementRepository(fileService: fileService);
  final collectorRepository = DataCollectorRepository(
    sensorService: sensorService,
    fileService: fileService,
  );

  runApp(
    MyApp(
      fileRepository: fileRepository,
      collectorRepository: collectorRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final FileManagementRepository fileRepository;
  final DataCollectorRepository collectorRepository;

  const MyApp({
    super.key,
    required this.fileRepository,
    required this.collectorRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sprint Companion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: DataCollectorView(
        fileRepository: fileRepository,
        collectorRepository: collectorRepository,
      ),
    );
  }
}

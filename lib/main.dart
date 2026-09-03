import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/home/home_view/home_view.dart';
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

  runApp(
    MultiProvider(
      providers: [
        Provider<FileService>.value(value: fileService),
        Provider<SensorService>.value(value: sensorService),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.blueAccent,
    brightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sprint Companion',
      theme: ThemeData(                        
        colorScheme: colorScheme,
        appBarTheme: AppBarTheme(centerTitle: true),
        cardTheme: CardThemeData(
          color: colorScheme.surfaceContainer,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
        ),
        inputDecorationTheme: InputDecorationThemeData(
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(23)),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(23)),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(23)),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
        ),
      ),
      home: const HomeView(),
    );
  }
}

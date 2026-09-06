import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/sensor_capture/sensor_service.dart';
import '../../../core/file_storage/file_service.dart';
import '../../../core/analysis/classifier_service.dart';
import '../../../core/analysis/analyzer_service.dart';
import '../active_session_repository.dart';
import '../active_session_view_model.dart';
import 'widgets/active_session_primary_button.dart';

class ActiveSessionView extends StatelessWidget {
  const ActiveSessionView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<ActiveSessionViewModel>(
        create: (context) {
          final classifierService = ClassifierService();
          final analyzerService = AnalyzerService();

          final activeSessionRepository = ActiveSessionRepository(
            fileService: context.read<FileService>(),
            sensorService: context.read<SensorService>(),
            classifierService: classifierService,
            analyzerService: analyzerService,
          );

          return ActiveSessionViewModel(
            activeSessionRepository: activeSessionRepository,
          )..initialize();
        },
        child: const _ActiveSessionContent(),
      );
}

class _ActiveSessionContent extends StatelessWidget {
  const _ActiveSessionContent();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Active Session')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: mediaQuery.size.height * 0.04,
            horizontal: mediaQuery.size.width * 0.06,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [const ActiveSessionPrimaryButton()],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/file_storage/file_service.dart';
import '../../../core/file_storage/file_management_repository.dart';
import '../../../core/sensor_capture/sensor_service.dart';
import '../data_collector_view_model.dart';
import '../data_collector_repository.dart';
import 'widgets/primary_action_button.dart';
import 'widgets/cache_info.dart';
import 'widgets/expanded_datasets_list.dart';
import 'widgets/status_message_card.dart';

class DataCollectorView extends StatelessWidget {
  const DataCollectorView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DataCollectorViewModel>(
      create: (context) {
        final fileService = context.read<FileService>();
        final sensorService = context.read<SensorService>();

        final fileRepository = FileManagementRepository(
          fileService: fileService,
        );
        final collectorRepository = DataCollectorRepository(
          sensorService: sensorService,
          fileService: fileService,
        );

        return DataCollectorViewModel(
          fileRepository: fileRepository,
          collectorRepository: collectorRepository,
        )..initialiseScreen();
      },
      child: const _DataCollectorContent(),
    );
  }
}

class _DataCollectorContent extends StatelessWidget {
  const _DataCollectorContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final viewModel = context.watch<DataCollectorViewModel>();

    final (bgColor, fgColor) = switch (viewModel.collectorStatus) {
      CollectorStatus.inactive => (
        theme.colorScheme.surfaceContainer,
        theme.colorScheme.onSurface,
      ),
      CollectorStatus.initialising => (
        theme.colorScheme.surfaceContainer,
        theme.colorScheme.onSurface,
      ),
      CollectorStatus.idle => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      CollectorStatus.recording => (
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
      ),
      CollectorStatus.cached => (
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
      ),
      CollectorStatus.processing => (
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Collector'),
        backgroundColor: bgColor,
        foregroundColor: fgColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: mediaQuery.size.height * 0.04,
            horizontal: mediaQuery.size.width * 0.06,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: viewModel.nameController,
                decoration: InputDecoration(
                  labelText: 'Trial Identification',
                  hintText: 'walk_sprint_walk',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StatusMessageCard(viewModel: viewModel),
              const SizedBox(height: 16),
              PrimaryActionButton(viewModel: viewModel),
              const SizedBox(height: 12),
              CacheInfo(viewModel: viewModel),
              const SizedBox(height: 16),
              ExpandedDatasetsList(viewModel: viewModel),
            ],
          ),
        ),
      ),
    );
  }
}

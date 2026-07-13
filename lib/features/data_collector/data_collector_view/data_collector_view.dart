import 'package:flutter/material.dart';
import '../../../core/file_storage/file_management_repository.dart';
import '../data_collector_view_model.dart';
import '../data_collector_repository.dart';
import 'widgets/primary_action_button.dart';
import 'widgets/cache_info.dart';
import 'widgets/flexible_datasets_list.dart';

class DataCollectorView extends StatefulWidget {
  final FileManagementRepository fileRepository;
  final DataCollectorRepository collectorRepository;

  const DataCollectorView({
    super.key,
    required this.fileRepository,
    required this.collectorRepository,
  });

  @override
  State<DataCollectorView> createState() => _DataCollectorViewState();
}

class _DataCollectorViewState extends State<DataCollectorView> {
  late final DataCollectorViewModel _viewModel = DataCollectorViewModel(
    fileRepository: widget.fileRepository,
    collectorRepository: widget.collectorRepository,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _viewModel.initialiseScreen(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) {
            final (
              statusLabel,
              bgColor,
              fgColor,
            ) = switch (_viewModel.collectorStatus) {
              CollectorStatus.inactive => (
                'Uninitialised',
                theme.colorScheme.surfaceContainer,
                theme.colorScheme.onSurface,
              ),
              CollectorStatus.initialising => (
                'Initialising',
                theme.colorScheme.surfaceContainer,
                theme.colorScheme.onSurface,
              ),
              CollectorStatus.idle => (
                'Idle',
                theme.colorScheme.primaryContainer,
                theme.colorScheme.onPrimaryContainer,
              ),
              CollectorStatus.recording => (
                'Recording',
                theme.colorScheme.tertiaryContainer,
                theme.colorScheme.onTertiaryContainer,
              ),
              CollectorStatus.cached => (
                'Cached',
                theme.colorScheme.secondaryContainer,
                theme.colorScheme.onSecondaryContainer,
              ),
              CollectorStatus.processing => (
                'Processing',
                theme.colorScheme.secondaryContainer,
                theme.colorScheme.onSecondaryContainer,
              ),
            };

            return AppBar(
              title: Text('Data Collector: $statusLabel'),
              backgroundColor: bgColor,
              foregroundColor: fgColor,
            );
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: mediaQuery.size.width * 0.04,
            horizontal: mediaQuery.size.height * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _viewModel.nameController,
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
              PrimaryActionButton(viewModel: _viewModel),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CacheInfo(viewModel: _viewModel),
                    FlexibleDatasetsList(
                      viewModel: _viewModel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

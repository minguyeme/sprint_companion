import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data_collector_view_model.dart';
import 'data_collector_repository.dart';
import '../../core/file_storage/file_management_repository.dart';

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
      (_) => _viewModel.initialiseScreen(
        uiOnCollectorError: _handleCollectorError,
        uiOnFileError: _handleFileError,
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _handleFileError(FileManagementError error) {
    //TODO: implement file error handling
  }

  void _handleCollectorError(CollectorError error) {
    //TODO: implement collector error handling
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final double universalHorizontalPadding = mediaQuery.size.width * 0.04;
    final double universalVerticalPadding = mediaQuery.size.height * 0.02;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Data Collector'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: universalVerticalPadding,
            horizontal: universalHorizontalPadding,
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
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(13)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(13)),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              Spacer(),
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, child) {
                  final (
                    buttonLabel,
                    bgColor,
                    fgColor,
                    action,
                  ) = switch (_viewModel.collectorStatus) {
                    CollectorStatus.inactive => (
                      const Text('Initialise Sensors'),
                      theme.colorScheme.surfaceContainer,
                      theme.colorScheme.onSurface,
                      () => _viewModel.initialiseScreen(
                        uiOnFileError: _handleFileError,
                        uiOnCollectorError: _handleCollectorError,
                      ),
                    ),
                    CollectorStatus.initialising => (
                      const Text('Initialise Sensors'),
                      theme.colorScheme.surfaceContainer,
                      theme.colorScheme.onSurface,
                      null,
                    ),
                    CollectorStatus.idle => (
                      const Text('Start Recording'),
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.onPrimaryContainer,
                      () => _viewModel.handlePrimaryButtonPress(
                        uiOnError: _handleCollectorError,
                      ),
                    ),
                    CollectorStatus.recording => (
                      const Text('Stop Recording'),
                      theme.colorScheme.tertiaryContainer,
                      theme.colorScheme.onTertiaryContainer,
                      () => _viewModel.handlePrimaryButtonPress(
                        uiOnError: _handleCollectorError,
                      ),
                    ),
                    CollectorStatus.cached => (
                      const Text('Save Recording'),
                      theme.colorScheme.secondaryContainer,
                      theme.colorScheme.onSecondaryContainer,
                      () => _viewModel.handlePrimaryButtonPress(
                        uiOnError: _handleCollectorError,
                      ),
                    ),
                    CollectorStatus.processing => (
                      const Text('Save Recording'),
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.onPrimaryContainer,
                      null,
                    ),
                  };
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(13)),
                      boxShadow: [
                        if (action == null)
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.4),
                            blurStyle: BlurStyle.outer,
                            blurRadius: 15,
                          ),
                      ],
                    ),
                    child: FilledButton.tonal(
                      onPressed: action == null
                          ? null
                          : () async {
                              await HapticFeedback.heavyImpact();
                              action();
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(
                          mediaQuery.textScaler.scale(64),
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(13)),
                        ),
                        backgroundColor: bgColor,
                        foregroundColor: fgColor,
                        disabledBackgroundColor: bgColor.withValues(
                          alpha: 0.12,
                        ),
                        disabledForegroundColor: fgColor.withValues(
                          alpha: 0.38,
                        ),
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      child: buttonLabel,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

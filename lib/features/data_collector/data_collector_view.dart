import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sprint_companion/core/file_storage/managed_file_data.dart';
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

  void _showRenameDialog(BuildContext context, ManagedFileData file) {
    final renameController = TextEditingController(text: file.name);
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(13)),
          ),
          title: Text('Rename Dataset'),
          content: TextField(
            controller: renameController,
            autofocus: true, 
            decoration: InputDecoration(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            TextButton(
              onPressed: () {
                final newCleanName = renameController.text.trim();
                if (newCleanName.isNotEmpty && newCleanName != file.name) {
                  _viewModel.handleRename(
                    file,
                    name: newCleanName,
                    uiOnError: _handleFileError,
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      renameController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final double universalHorizontalPadding = mediaQuery.size.width * 0.04;
    final double universalVerticalPadding = mediaQuery.size.height * 0.02;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
                      theme.colorScheme.secondaryContainer,
                      theme.colorScheme.onSecondaryContainer,
                      null,
                    ),
                  };
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(13)),
                      boxShadow: [
                        if (action == null)
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CacheInfo(
                      viewModel: _viewModel,
                      theme: theme,
                      mediaQuery: mediaQuery,
                    ),
                    Flexible(
                      fit: FlexFit.loose,
                      child: ListenableBuilder(
                        listenable: _viewModel,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(13),
                              ),
                            ),
                            child: ListView.builder(
                              itemCount: _viewModel.savedDatasets.length,
                              itemBuilder: (context, index) {
                                final file = _viewModel.savedDatasets[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: mediaQuery.textScaler.scale(12),
                                    vertical: mediaQuery.textScaler.scale(4),
                                  ),
                                  title: InkWell(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(13),
                                    ),
                                    onTap: () =>
                                        _showRenameDialog(context, file),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: mediaQuery.textScaler.scale(
                                          4,
                                        ),
                                      ),
                                      child: Text(
                                        file.name,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${(file.sizeInBytes / 1024).toStringAsFixed(1)} KB',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: mediaQuery.textScaler.scale(8),
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.share_rounded,
                                          color: theme.colorScheme.secondary,
                                        ),
                                        onPressed: () {
                                          _viewModel.handleShare(
                                            file,
                                            uiOnResult: (isSucessful) {
                                              if (isSucessful) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Shared sucessfully!',
                                                    ),
                                                    backgroundColor: theme
                                                        .colorScheme
                                                        .tertiaryContainer,
                                                    duration: Duration(
                                                      seconds: 3,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color:
                                              theme.colorScheme.errorContainer,
                                        ),
                                        onPressed: () {
                                          _viewModel.handleDelete(
                                            file,
                                            uiOnError: _handleFileError,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
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

class CacheInfo extends StatelessWidget {
  const CacheInfo({
    super.key,
    required this._viewModel,
    required this.theme,
    required this.mediaQuery,
  });

  final DataCollectorViewModel _viewModel;
  final ThemeData theme;
  final MediaQueryData mediaQuery;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: ((context, child) {
        final (:maxSpeed, :maxSpeedAccuracy, :rows) = _viewModel.cacheInfo;
        if (_viewModel.collectorStatus != CollectorStatus.cached) {
          return SizedBox.shrink();
        }
        return Card(
          color: theme.colorScheme.surfaceContainer,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(13)),
          ),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Trial Metrics',
              labelStyle: theme.textTheme.titleLarge?.copyWith(
                color: theme.textTheme.labelLarge?.color,
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(13)),
              ),
            ),
            isHovering: true,
            child: Column(
              spacing: mediaQuery.textScaler.scale(16),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL ROWS',
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      rows,
                      style: theme.textTheme.titleLarge!.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAX VELOCITY',
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      maxSpeed,
                      style: theme.textTheme.titleLarge!.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      maxSpeedAccuracy,
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

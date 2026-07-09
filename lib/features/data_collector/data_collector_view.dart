import 'package:flutter/material.dart';
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
            children: [const Text('Placeholder')],
          ),
        ),
      ),
    );
  }
}

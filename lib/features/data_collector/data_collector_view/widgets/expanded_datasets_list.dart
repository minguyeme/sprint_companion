import 'package:flutter/material.dart';
import '../../../../core/file_storage/managed_file_data.dart';
import '../../data_collector_view_model.dart';
import 'rename_dialog.dart';

class ExpandedDatasetsList extends StatelessWidget {
  const ExpandedDatasetsList({super.key, required this._viewModel});

  final DataCollectorViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text('Datasets', style: theme.textTheme.titleLarge),
          Expanded(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, child) {
                if (_viewModel.savedDatasets.isEmpty) {
                  return Center(
                    child: Text(
                      'No Datasets',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: _viewModel.savedDatasets.length,
                  separatorBuilder: (context, child) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final file = _viewModel.savedDatasets[index];
                    return _DatasetCard(file: file, viewModel: _viewModel);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DatasetCard extends StatelessWidget {
  const _DatasetCard({required this.file, required this.viewModel});

  final ManagedFileData file;
  final DataCollectorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () async {
          String? name = (await showDialog<String>(
            context: context,
            builder: (context) => RenameDialog(originalName: file.name),
          ))?.trim();
          if (name == null || name.isEmpty) {
            name = file.name;
          }
          viewModel.handleRename(file, name: name);
        },
        child: ListTile(
          title: Text(
            file.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text('${(file.sizeInBytes / 1024).toStringAsFixed(1)} KB'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.ios_share_rounded,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () => viewModel.handleShare(file),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                onPressed: () => viewModel.handleDelete(file),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../data_collector_view_model.dart';

class FlexibleDatasetsList extends StatelessWidget {
  const FlexibleDatasetsList({super.key, required this._viewModel});

  final DataCollectorViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Datasets',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.textTheme.labelLarge?.color,
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, child) {
              return ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 0),
                itemCount: _viewModel.savedDatasets.length,
                itemBuilder: (context, index) {
                  final file = _viewModel.savedDatasets[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    title: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(13)),
                      onTap: () {
                        final renameController = TextEditingController(
                          text: file.name,
                        );
                        showDialog<void>(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: Text('Rename Dataset'),
                              content: TextField(
                                controller: renameController,
                                autofocus: true,
                                decoration: InputDecoration(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final newCleanName = renameController.text
                                        .trim();
                                    if (newCleanName.isNotEmpty &&
                                        newCleanName != file.name) {
                                      _viewModel.handleRename(
                                        file,
                                        name: newCleanName,
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
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: mediaQuery.textScaler.scale(4),
                        ),
                        child: Text(
                          file.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
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
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            _viewModel.handleShare(file);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.errorContainer,
                          ),
                          onPressed: () {
                            _viewModel.handleDelete(file);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// class RenameDialog extends StatefulWidget {
//   final String originalName;

//   RenameDialog({super.key, required this.originalName});

//   @override
//   State<StatefulWidget> createState() => _RenameDialogState();
// }

// class _RenameDialogState extends State<RenameDialog> {
  

//   @override
//   Widget build(BuildContext context) {
//     throw UnimplementedError();
//   }

// }

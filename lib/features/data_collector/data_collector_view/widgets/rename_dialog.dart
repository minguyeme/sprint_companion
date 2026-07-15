import 'package:flutter/material.dart';

class RenameDialog extends StatefulWidget {
  const RenameDialog({super.key, required this.originalName});

  final String originalName;

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.originalName);
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Rename Dataset'),
      content: TextField(controller: _renameController, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, widget.originalName),
          child: Text(
            'Cancel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _renameController.text),
          child: Text(
            'Save',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

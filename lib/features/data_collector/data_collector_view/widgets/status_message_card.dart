import 'package:flutter/material.dart';
import '../../data_collector_view_model.dart';

class StatusMessageCard extends StatefulWidget {
  const StatusMessageCard({super.key, required this.viewModel});

  final DataCollectorViewModel viewModel;

  @override
  State<StatusMessageCard> createState() => _StatusMessageCardState();
}

class _StatusMessageCardState extends State<StatusMessageCard> {
  static const _defaultMessage = 'Operational';
  String _displayMessage = _defaultMessage;
  bool _isFailure = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        _displayMessage = widget.viewModel.statusMessage ?? _defaultMessage;
        _isFailure = widget.viewModel.isFailure;

        return Card(
          child: ListTile(
            leading: Icon(
              _isFailure
                  ? Icons.error_outline_rounded
                  : Icons.info_outline_rounded,
              color: _isFailure
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _displayMessage,
                key: ValueKey(_displayMessage),
              ),
            ),
          ),
        );
      },
    );
  }
}

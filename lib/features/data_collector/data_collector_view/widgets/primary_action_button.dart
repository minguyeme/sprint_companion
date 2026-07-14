import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data_collector_view_model.dart';
import '../../data_collector_repository.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({super.key, required this._viewModel});

  final DataCollectorViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final (
          buttonIcon,
          buttonLabel,
          bgColor,
          fgColor,
          action,
        ) = switch (_viewModel.collectorStatus) {
          CollectorStatus.inactive => (
            Icons.sensors_rounded,
            const Text('Initialise Sensors'),
            theme.colorScheme.surfaceContainer,
            theme.colorScheme.onSurface,
            _viewModel.initialiseScreen,
          ),
          CollectorStatus.initialising => (
            Icons.sensors_rounded,
            const Text('Initialise Sensors'),
            theme.colorScheme.surfaceContainer,
            theme.colorScheme.onSurface,
            null,
          ),
          CollectorStatus.idle => (
            Icons.play_arrow_rounded,
            const Text('Start Recording'),
            theme.colorScheme.primaryContainer,
            theme.colorScheme.onPrimaryContainer,
            _viewModel.handlePrimaryButtonPress,
          ),
          CollectorStatus.recording => (
            Icons.stop_rounded,
            const Text('Stop Recording'),
            theme.colorScheme.tertiaryContainer,
            theme.colorScheme.onTertiaryContainer,
            _viewModel.handlePrimaryButtonPress,
          ),
          CollectorStatus.cached => (
            Icons.save_alt_rounded,
            const Text('Save Recording'),
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.onSecondaryContainer,
            _viewModel.handlePrimaryButtonPress,
          ),
          CollectorStatus.processing => (
            Icons.save_alt_rounded,
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurStyle: BlurStyle.outer,
                  blurRadius: 15,
                ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: action == null
                ? null
                : () async {
                    await HapticFeedback.heavyImpact();
                    action();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              disabledBackgroundColor: bgColor.withValues(alpha: 0.12),
              disabledForegroundColor: fgColor.withValues(alpha: 0.38),
            ),
            icon: Icon(buttonIcon),
            label: buttonLabel,
          ),
        );
      },
    );
  }
}

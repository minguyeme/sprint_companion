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
    final mediaQuery = MediaQuery.of(context);

    return ListenableBuilder(
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
            _viewModel.initialiseScreen,
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
            _viewModel.handlePrimaryButtonPress,
          ),
          CollectorStatus.recording => (
            const Text('Stop Recording'),
            theme.colorScheme.tertiaryContainer,
            theme.colorScheme.onTertiaryContainer,
            _viewModel.handlePrimaryButtonPress,
          ),
          CollectorStatus.cached => (
            const Text('Save Recording'),
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.onSecondaryContainer,
            _viewModel.handlePrimaryButtonPress,
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
              minimumSize: Size.fromHeight(mediaQuery.textScaler.scale(64)),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(13)),
              ),
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              disabledBackgroundColor: bgColor.withValues(alpha: 0.12),
              disabledForegroundColor: fgColor.withValues(alpha: 0.38),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            child: buttonLabel,
          ),
        );
      },
    );
  }
}

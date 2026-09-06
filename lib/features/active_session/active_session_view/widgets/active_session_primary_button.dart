import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../active_session_view_model.dart';
import '../../active_session_repository.dart';

class ActiveSessionPrimaryButton extends StatelessWidget {
  const ActiveSessionPrimaryButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final status = context.select<ActiveSessionViewModel, ActiveSessionStatus>(
      (viewModel) => viewModel.status,
    );

    final viewModel = context.read<ActiveSessionViewModel>();

    final (
      buttonIcon,
      buttonLabel,
      bgColor,
      fgColor,
      action,
    ) = switch (status) {
      ActiveSessionStatus.inactive => (
        Icons.sensors_rounded,
        'Initialize Sensors',
        theme.colorScheme.surfaceContainer,
        theme.colorScheme.onSurface,
        viewModel.initialize,
      ),
      ActiveSessionStatus.initializing => (
        Icons.sensors_rounded,
        'Initializing Sensors',
        theme.colorScheme.surfaceContainer,
        theme.colorScheme.onSurface,
        null,
      ),
      ActiveSessionStatus.idle => (
        Icons.play_arrow_rounded,
        'Start Capturing',
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
        viewModel.handlePrimaryButtonPress,
      ),
      ActiveSessionStatus.capturing => (
        Icons.stop_rounded,
        'Stop Capturing',
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
        viewModel.handlePrimaryButtonPress,
      ),
      ActiveSessionStatus.analyzing => (
        Icons.save_alt_rounded,
        'Analyzing Capture',
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
        null,
      ),
      ActiveSessionStatus.analyzed => (
        Icons.save_alt_rounded,
        'Save Analysis Log',
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
        viewModel.handlePrimaryButtonPress,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius:
            (theme.filledButtonTheme.style?.shape?.resolve({})
                    as RoundedRectangleBorder?)
                ?.borderRadius,
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
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(buttonIcon, key: ValueKey(buttonIcon)),
        ),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(buttonLabel, key: ValueKey(buttonLabel)),
        ),
      ),
    );
  }
}

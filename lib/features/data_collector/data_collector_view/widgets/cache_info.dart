import 'package:flutter/material.dart';
import '../../data_collector_view_model.dart';
import '../../data_collector_repository.dart';

class CacheInfo extends StatelessWidget {
  final DataCollectorViewModel _viewModel;

  const CacheInfo({super.key, required this._viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: ((context, child) {
        if (_viewModel.collectorStatus != CollectorStatus.cached) {
          return SizedBox.shrink();
        }
        final (:maxSpeed, :maxSpeedAccuracy, :rows) = _viewModel.cacheInfo;

        return Card(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Trial Metrics',
              labelStyle: theme.textTheme.titleLarge?.copyWith(
                color: theme.textTheme.labelLarge?.color,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    (theme.cardTheme.shape as RoundedRectangleBorder)
                            .borderRadius
                        as BorderRadius,
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MetricTile(label: 'TOTAL ROWS', data: rows),
                MetricTile(
                  label: 'MAX SPEED',
                  data: maxSpeed,
                  subtitle: maxSpeedAccuracy,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class MetricTile extends StatelessWidget {
  final String label;
  final String data;
  final String? subtitle;

  const MetricTile({
    super.key,
    required this.label,
    required this.data,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          data,
          style: theme.textTheme.titleLarge!.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.labelSmall!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.normal,
            ),
          ),
      ],
    );
  }
}

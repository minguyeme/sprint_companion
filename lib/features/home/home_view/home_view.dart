import 'package:flutter/material.dart';
import 'package:sprint_companion/features/active_session/active_session_view/active_session_view.dart';
import '../../data_collector/data_collector_view/data_collector_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sprint Companion'),
        backgroundColor: theme.colorScheme.secondaryContainer,
        foregroundColor: theme.colorScheme.onSecondaryContainer,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: mediaQuery.size.height * 0.04,
            horizontal: mediaQuery.size.width * 0.06,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ActiveSessionView(),
                    ),
                  );
                },
                label: const Text('Start Active Session'),
                icon: Icon(Icons.run_circle_outlined),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {},
                label: const Text('Start Saved Session'),
                icon: Icon(Icons.save_outlined),
              ),
              const SizedBox(height: 32),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DataCollectorView(),
                      ),
                    );
                  },
                  label: const Text('Data Collector'),
                  icon: Icon(Icons.dataset_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

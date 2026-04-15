import 'package:flutter/material.dart';
import 'data/guide_data.dart';
import 'data/guide_data_faux.dart';
import 'data/guide_data_laef.dart';
import 'models/task_model.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();

  final routes = [
    GuideRoute(id: 'doubleshine', name: 'Doubleshine', sections: buildGuideData()),
    GuideRoute(id: 'laef', name: 'Laef', sections: buildLaefGuideData()),
    GuideRoute(id: 'faux', name: 'Faux', sections: buildFauxGuideData()),
  ];

  // Restore saved completion state into all route tasks.
  final completedIds = storage.getCompletedTaskIds();
  for (final route in routes) {
    for (final section in route.sections) {
      for (final task in section.tasks) {
        if (completedIds.contains(task.id)) {
          task.isCompleted = true;
        }
      }
    }
  }

  runApp(LeaguesPlannerApp(routes: routes, storage: storage));
}

class LeaguesPlannerApp extends StatelessWidget {
  final List<GuideRoute> routes;
  final StorageService storage;

  const LeaguesPlannerApp({
    super.key,
    required this.routes,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leagues 6 Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeScreen(routes: routes, storage: storage),
    );
  }
}

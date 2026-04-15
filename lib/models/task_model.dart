class GuideTask {
  final String id;
  final String name;
  final String? description;
  final int points;
  final TaskDifficulty difficulty;
  final List<String> tips;
  bool isCompleted;

  GuideTask({
    required this.id,
    required this.name,
    this.description,
    this.points = 10,
    this.difficulty = TaskDifficulty.easy,
    this.tips = const [],
    this.isCompleted = false,
  });
}

class GuideSection {
  final String id;
  final String name;
  final String? subtitle;
  final int? taskCountAfter;
  final String? tierInfo;
  final List<String> notes;
  final List<GuideTask> tasks;

  GuideSection({
    required this.id,
    required this.name,
    this.subtitle,
    this.taskCountAfter,
    this.tierInfo,
    this.notes = const [],
    required this.tasks,
  });

  int get completedCount => tasks.where((t) => t.isCompleted).length;
  double get progress =>
      tasks.isEmpty ? 0 : completedCount / tasks.length;
}

enum TaskDifficulty {
  easy(10, 'Easy'),
  medium(30, 'Medium'),
  hard(80, 'Hard'),
  elite(200, 'Elite'),
  master(400, 'Master');

  final int defaultPoints;
  final String label;
  const TaskDifficulty(this.defaultPoints, this.label);
}

class GuideRoute {
  final String id;
  final String name;
  final List<GuideSection> sections;
  const GuideRoute({
    required this.id,
    required this.name,
    required this.sections,
  });
}

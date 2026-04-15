import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _completedKey = 'completed_tasks';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Set<String> getCompletedTaskIds() {
    final list = _prefs.getStringList(_completedKey) ?? [];
    return list.toSet();
  }

  Future<void> toggleTask(String taskId, bool completed) async {
    final set = getCompletedTaskIds();
    if (completed) {
      set.add(taskId);
    } else {
      set.remove(taskId);
    }
    await _prefs.setStringList(_completedKey, set.toList());
  }

  Future<void> clearAll() async {
    await _prefs.remove(_completedKey);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:osrs_leagues6_planner/data/guide_data.dart';

void main() {
  test('Guide data loads correctly', () {
    final sections = buildGuideData();
    expect(sections.isNotEmpty, true);
    expect(sections.first.tasks.isNotEmpty, true);
  });
}

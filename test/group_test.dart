import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'common.dart';

void main() {
  late TestService testService;
  late List<String> notificationLog;

  setUp(() {
    testService = TestService();
    notificationLog = [];
  });

  test('should add dependencies to groups correctly', () {
    final listener1 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener1:$aspect'));
    final listener2 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener2:$aspect'));
    final listener3 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener3:$aspect'));

    // Add listeners to different groups
    testService.addDependency(listener1, 'aspect1', group: 'group1');
    testService.addDependency(listener2, 'aspect2', group: 'group1');
    testService.addDependency(listener3, 'aspect3', group: 'group2');

    // Verify groups exist
    expect(testService.hasDependencyGroup('group1'), true);
    expect(testService.hasDependencyGroup('group2'), true);
    expect(testService.hasDependencyGroup('group3'), false);

    // Verify group counts
    expect(testService.getDependentsCountInGroup('group1'), 2);
    expect(testService.getDependentsCountInGroup('group2'), 1);
    expect(testService.getDependentsCountInGroup('group3'), 0);

    // Verify all groups are listed
    expect(testService.dependencyGroups, containsAll(['group1', 'group2']));
  });

  test('should notify dependents in specific groups only', () {
    final listener1 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener1:$aspect'));
    final listener2 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener2:$aspect'));
    final listener3 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener3:$aspect'));

    // Add listeners to different groups
    testService.addDependency(listener1, 'aspect1', group: 'group1');
    testService.addDependency(listener2, 'aspect2', group: 'group1');
    testService.addDependency(listener3, 'aspect3', group: 'group2');

    // Notify only group1
    testService.notifyGroup('group1');

    // Verify only group1 listeners were notified
    expect(notificationLog, hasLength(2));
    expect(notificationLog, containsAll(['listener1:aspect1', 'listener2:aspect2']));
    expect(notificationLog, isNot(contains('listener3:aspect3')));

    // Clear log and notify group2
    notificationLog.clear();
    testService.notifyGroup('group2');

    // Verify only group2 listener was notified
    expect(notificationLog, hasLength(1));
    expect(notificationLog, contains('listener3:aspect3'));
  });

  test('should clean up groups when removing dependencies', () {
    final listener1 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener1:$aspect'));
    final listener2 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener2:$aspect'));

    // Add listeners to groups
    testService.addDependency(listener1, 'aspect1', group: 'group1');
    testService.addDependency(listener2, 'aspect2', group: 'group2');

    expect(testService.dependencyGroups, hasLength(2));

    // Remove a dependency
    testService.removeDependency(listener1);

    // Verify group1 is cleaned up but group2 remains
    expect(testService.hasDependencyGroup('group1'), false);
    expect(testService.hasDependencyGroup('group2'), true);
    expect(testService.dependencyGroups, hasLength(1));
  });

  test('should clear entire dependency groups', () {
    final listener1 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener1:$aspect'));
    final listener2 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener2:$aspect'));
    final listener3 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener3:$aspect'));

    // Add listeners to groups
    testService.addDependency(listener1, 'aspect1', group: 'group1');
    testService.addDependency(listener2, 'aspect2', group: 'group1');
    testService.addDependency(listener3, 'aspect3', group: 'group2');

    // Clear group1
    testService.clearDependencyGroup('group1');

    // Verify group1 is gone but group2 remains
    expect(testService.hasDependencyGroup('group1'), false);
    expect(testService.hasDependencyGroup('group2'), true);
    expect(testService.getDependentsCountInGroup('group2'), 1);

    // Try to notify group1 - should have no effect
    testService.notifyGroup('group1');
    expect(notificationLog, isEmpty);

    // Notify group2 - should still work
    testService.notifyGroup('group2');
    expect(notificationLog, contains('listener3:aspect3'));
  });

  test('should handle non-existent groups gracefully', () {
    // Try to notify a non-existent group
    expect(() => testService.notifyGroup('nonExistentGroup'), returnsNormally);

    // Try to clear a non-existent group
    expect(() => testService.clearDependencyGroup('nonExistentGroup'), returnsNormally);

    // Check count for non-existent group
    expect(testService.getDependentsCountInGroup('nonExistentGroup'), 0);
  });

  test('should clear previous group when setting new group', () {
    final listener1 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener1:$aspect'));

    // Initially add to group1
    testService.addDependency(listener1, 'aspect1', group: 'group1');
    expect(testService.hasDependencyGroup('group1'), true);
    expect(testService.getDependentsCountInGroup('group1'), 1);

    // Move to group2 - should automatically remove from group1
    testService.addDependency(listener1, 'aspect1', group: 'group2');

    // Verify group1 is cleaned up and group2 has the listener
    expect(testService.hasDependencyGroup('group1'), false);
    expect(testService.hasDependencyGroup('group2'), true);
    expect(testService.getDependentsCountInGroup('group1'), 0);
    expect(testService.getDependentsCountInGroup('group2'), 1);

    // Verify only group2 gets notified
    testService.notifyGroup('group1');
    expect(notificationLog, isEmpty);

    testService.notifyGroup('group2');
    expect(notificationLog, contains('listener1:aspect1'));
  });

  test('should handle setting dependency without group after being in a group', () {
    final listener1 = MvcDependableFunctionListener((aspect) => notificationLog.add('listener1:$aspect'));

    // Initially add to group1
    testService.addDependency(listener1, 'aspect1', group: 'group1');
    expect(testService.hasDependencyGroup('group1'), true);
    expect(testService.getDependentsCountInGroup('group1'), 1);

    // Set dependency without group - should remove from group1
    testService.addDependency(listener1, 'aspect1');

    // Verify group1 is cleaned up
    expect(testService.hasDependencyGroup('group1'), false);
    expect(testService.getDependentsCountInGroup('group1'), 0);

    // Verify group notification doesn't work but global notification does
    testService.notifyGroup('group1');
    expect(notificationLog, isEmpty);

    notificationLog.clear();
    testService.update(() {}); // This calls notifyAllDependents
    expect(notificationLog, contains('listener1:aspect1'));
  });
}

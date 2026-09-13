import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutor_bloom/main.dart';

void main() {
  test('September enrollment has no June dues and persists through backup', () {
    final s = Student(
      'kid',
      'September kid',
      'Math',
      '',
      1500,
      5,
      {},
      joiningMonth: DateTime(2026, 9),
    );
    expect(s.feeFor(DateTime(2026, 6)), 0);
    expect(s.balanceFor(DateTime(2026, 6)), 0);
    expect(s.activeIn(DateTime(2026, 6)), false);
    expect(s.balanceFor(DateTime(2026, 9)), 1500);
    expect(s.balanceFor(DateTime(2027, 1)), 1500);
    final restored = Student.fromJson(jsonDecode(jsonEncode(s.toJson())));
    expect(restored.joiningMonth, DateTime(2026, 9));
    expect(restored.balanceFor(DateTime(2026, 6)), 0);
  });
  test(
    'Legacy migration respects creation date and earlier recorded payments',
    () {
      final old = Student(
        DateTime(2026, 9, 5).microsecondsSinceEpoch.toString(),
        'Kid',
        '',
        '',
        1500,
        5,
        {},
      ).toJson()..remove('joiningMonth');
      expect(Student.fromJson(old).joiningMonth, DateTime(2026, 9));
      old['payments'] = {'2026-06': 1500};
      expect(Student.fromJson(old).joiningMonth, DateTime(2026, 6));
    },
  );
  testWidgets('Before joining, dashboard and reminders exclude student', (
    tester,
  ) async {
    final now = DateTime.now();
    final s = Student(
      'kid',
      'September kid',
      'Math',
      '',
      1500,
      5,
      {},
      joiningMonth: DateTime(now.year, now.month),
    );
    SharedPreferences.setMockInitialValues({
      'bloom_v1': jsonEncode({
        'students': [s.toJson()],
        'demo': false,
      }),
    });
    await tester.pumpWidget(const BloomApp());
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
    }
    expect(find.text('of ₹0 expected'), findsOneWidget);
    expect(find.text('0 of 0 paid'), findsOneWidget);
    await tester.tap(find.text('Reminders').last);
    await tester.pumpAndSettle();
    expect(find.text('September kid'), findsNothing);
    await tester.tap(find.text('Students').last);
    await tester.pumpAndSettle();
    expect(find.text('Not joined yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Demo navigation and recording a payment update totals', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BloomApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Explore a sample classroom'),
      300,
    );
    await tester.tap(find.text('Explore a sample classroom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Students').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rohan Mehta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();
    expect(find.text('Payment recorded'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('bloom_v1'), contains('Rohan Mehta'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Small phone dashboard has no layout errors', (tester) async {
    tester.view.physicalSize = const Size(320, 710);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BloomApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

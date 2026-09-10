import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/auth/widgets/welcome_header.dart';
import 'package:jup/features/auth/widgets/welcome_header_large.dart';

void main() {
  testWidgets('WelcomeHeader rendert ohne Overflow', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Column(children: [WelcomeHeader()])),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('WelcomeHeaderLarge rendert ohne Overflow', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: WelcomeHeaderLarge())),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

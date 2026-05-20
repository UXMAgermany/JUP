import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/shorts/models/shorts_model.dart';
import 'package:jup/features/shorts/widgets/shorts_card.dart';
import 'package:jup/features/files/models/file_model.dart';

void main() {
  group('ShortsCard Widget Tests', () {
    late ShortsEntry testShorts;

    setUp(() {
      testShorts = ShortsEntry(
        documentId: 'test-id-123',
        title: 'Test Short',
        viewCount: 42,
        createdAt: DateTime(2024, 1, 1),
        video: StrapiFile(
          id: 1,
          documentId: 'video-123',
          name: 'test.mp4',
          path: '/uploads/test.mp4',
          url: 'http://example.com/video.mp4',
          width: 1080,
          height: 1920,
        ),
      );
    });

    Widget createWidgetUnderTest({
      required ShortsEntry shortsEntry,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShortsCard(shortsEntry: shortsEntry, onTap: onTap),
          ),
        ),
      );
    }

    testWidgets('should display title and view count', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump(); // Let the widget build

      // Title appears once below the video frame
      expect(find.text('Test Short'), findsOneWidget);
      expect(find.text('42 mal angesehen'), findsOneWidget);
    });

    testWidgets('should display view count of 0', (WidgetTester tester) async {
      final shortsWithNoViews = ShortsEntry(
        documentId: 'test-id-123',
        title: 'Test Short',
        viewCount: 0,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(shortsEntry: shortsWithNoViews),
      );
      await tester.pump();

      expect(find.text('0 mal angesehen'), findsOneWidget);
    });

    testWidgets('should have correct aspect ratio', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      final aspectRatio = find.byType(AspectRatio);
      expect(aspectRatio, findsOneWidget);

      final AspectRatio aspectRatioWidget = tester.widget(aspectRatio);
      expect(aspectRatioWidget.aspectRatio, 9 / 16);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        createWidgetUnderTest(
          shortsEntry: testShorts,
          onTap: () => tapped = true,
        ),
      );
      await tester.pump();

      // Tap at the top of the visible area which is part of the AspectRatio/video
      await tester.tapAt(const Offset(400, 100));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('should handle shorts without video', (
      WidgetTester tester,
    ) async {
      final shortsWithoutVideo = ShortsEntry(
        documentId: 'test-id-123',
        title: 'Test Short',
        viewCount: 42,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(shortsEntry: shortsWithoutVideo),
      );
      await tester.pump();

      // Should not crash and still display title below the video frame
      expect(find.text('Test Short'), findsOneWidget);
    });

    testWidgets('should handle shorts with null title', (
      WidgetTester tester,
    ) async {
      final shortsWithoutTitle = ShortsEntry(
        documentId: 'test-id-123',
        title: null,
        viewCount: 42,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(shortsEntry: shortsWithoutTitle),
      );
      await tester.pump();

      // Should not crash
      expect(find.text('42 mal angesehen'), findsOneWidget);
    });

    testWidgets('should show placeholder initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      // The video will show either a loading indicator or placeholder with play icon
      // Since thumbnail generation happens async, we may see loading first
      final playIconOrLoading = find.byWidgetPredicate(
        (widget) =>
            widget is Icon && widget.icon == Icons.play_circle_filled ||
            widget is CircularProgressIndicator,
      );
      expect(playIconOrLoading, findsAtLeastNWidgets(1));
    });

    testWidgets('should display in column layout', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      final column = find.byType(Column);
      expect(column, findsWidgets);
    });

    testWidgets('should have rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      final clipRRect = find.descendant(
        of: find.byType(AspectRatio),
        matching: find.byType(ClipRRect),
      );

      expect(clipRRect, findsOneWidget);
      final ClipRRect clipRRectWidget = tester.widget(clipRRect.first);
      expect(clipRRectWidget.borderRadius, isNotNull);
    });

    testWidgets('should handle large view counts', (WidgetTester tester) async {
      final shortsWithManyViews = ShortsEntry(
        documentId: 'test-id-123',
        title: 'Popular Short',
        viewCount: 1000000,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(shortsEntry: shortsWithManyViews),
      );
      await tester.pump();

      expect(find.text('1000000 mal angesehen'), findsOneWidget);
    });

    testWidgets('should handle long titles', (WidgetTester tester) async {
      final shortsWithLongTitle = ShortsEntry(
        documentId: 'test-id-123',
        title:
            'This is a very long title that might overflow the text widget if not handled properly',
        viewCount: 42,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(shortsEntry: shortsWithLongTitle),
      );
      await tester.pump();

      // Should not throw overflow error
      expect(tester.takeException(), isNull);
    });
  });
}

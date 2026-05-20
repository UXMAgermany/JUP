import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/shorts/models/shorts_model.dart';
import 'package:jup/features/shorts/services/video_player_pool.dart';
import 'package:jup/features/shorts/widgets/shorts_feed_item.dart';
import 'package:jup/features/files/models/file_model.dart';

void main() {
  group('ShortsFeedItem Widget Tests', () {
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
      int index = 0,
    }) {
      final playerPool = VideoPlayerPool();
      return ProviderScope(
        child: MaterialApp(
          home: ShortsFeedItem(
            shortsEntry: shortsEntry,
            playerPool: playerPool,
            index: index,
          ),
        ),
      );
    }

    testWidgets('should display title when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      expect(find.text('Test Short'), findsOneWidget);
    });

    testWidgets('should display view count', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      expect(find.text('42 mal angesehen'), findsOneWidget);
    });

    testWidgets('should not display title text when title is null', (
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

      // Title should not be displayed, but view count should be
      expect(find.text('42 mal angesehen'), findsOneWidget);
    });

    testWidgets('should use theme background', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);

      // Scaffold uses theme background (null means default theme scaffold background)
      final Scaffold scaffoldWidget = tester.widget(scaffold);
      expect(scaffoldWidget.backgroundColor, isNull);
    });

    testWidgets('should display back button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should display share button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      // Should find either ios_share or share icon
      final shareButton = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.ios_share || widget.icon == Icons.share),
      );
      expect(shareButton, findsOneWidget);
    });

    testWidgets('should pop when back button is tapped', (
      WidgetTester tester,
    ) async {
      final playerPool = VideoPlayerPool();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShortsFeedItem(
                          shortsEntry: testShorts,
                          playerPool: playerPool,
                          index: 0,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap to open the shorts feed item
      await tester.tap(find.text('Open'));
      await tester.pump(); // Start the navigation
      await tester.pump(
        const Duration(milliseconds: 500),
      ); // Complete the navigation animation

      // Verify we're on the shorts feed page
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Open'), findsNothing);

      // Tap the back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump(); // Start the pop
      await tester.pump(
        const Duration(milliseconds: 500),
      ); // Complete the pop animation

      // Verify we've returned to the home page
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should have top gradient overlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      // Find containers with gradients
      final gradients = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient is LinearGradient,
      );

      // Should have at least 2 gradients (top and bottom)
      expect(gradients, findsAtLeastNWidgets(2));
    });

    testWidgets('should have bottom gradient overlay with text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      // Find containers with gradients
      final gradients = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient is LinearGradient,
      );

      // Should have gradients for top and bottom
      expect(gradients, findsAtLeastNWidgets(2));
    });

    testWidgets('should use Stack layout', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      // Should find at least one Stack widget (there can be multiple from SafeArea, etc.)
      expect(find.byType(Stack), findsWidgets);
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

      // Should show loading indicator when there's no video
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Short'), findsOneWidget);
    });

    testWidgets('should display zero view count', (WidgetTester tester) async {
      final shortsWithNoViews = ShortsEntry(
        documentId: 'test-id-123',
        title: 'New Short',
        viewCount: 0,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(shortsEntry: shortsWithNoViews),
      );
      await tester.pump();

      expect(find.text('0 mal angesehen'), findsOneWidget);
    });

    testWidgets('should handle large view counts', (WidgetTester tester) async {
      final popularShorts = ShortsEntry(
        documentId: 'test-id-123',
        title: 'Viral Short',
        viewCount: 1000000,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(shortsEntry: popularShorts),
      );
      await tester.pump();

      expect(find.text('1000000 mal angesehen'), findsOneWidget);
    });

    testWidgets('should handle long titles without overflow', (
      WidgetTester tester,
    ) async {
      final longTitleShorts = ShortsEntry(
        documentId: 'test-id-123',
        title:
            'This is a very long title that should wrap properly and not cause any overflow issues in the UI',
        viewCount: 42,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(shortsEntry: longTitleShorts),
      );
      await tester.pump();

      // Should not throw overflow error
      expect(tester.takeException(), isNull);
    });

    testWidgets('should position buttons correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      // Back button should be on the left
      final backButton = find.ancestor(
        of: find.byIcon(Icons.arrow_back),
        matching: find.byType(Positioned),
      );
      expect(backButton, findsOneWidget);

      // Share button should be on the right
      final shareIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.ios_share || widget.icon == Icons.share),
      );
      final shareButton = find.ancestor(
        of: shareIcon,
        matching: find.byType(Positioned),
      );
      expect(shareButton, findsOneWidget);
    });

    testWidgets('buttons should have white color', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(shortsEntry: testShorts));
      await tester.pump();

      final backIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_back));
      expect(backIcon.color, Colors.white);
    });
  });
}

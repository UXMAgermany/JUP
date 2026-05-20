import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/features/news/widgets/news_card.dart';

void main() {
  group('NewsCard Widget Tests', () {
    late NewsEntry testNews;

    setUp(() {
      testNews = NewsEntry(
        documentId: 'test-id-123',
        category: NewsCategory.sport,
        title: 'Test News Title',
        subTitle: 'Test Subtitle',
        text: 'This is a test news article text that provides more details.',
        author: 'Test Author',
        createdAt: DateTime(2024, 10, 15),
        imageUrl: 'http://example.com/test.jpg',
      );
    });

    Widget createWidgetUnderTest({
      required NewsEntry newsEntry,
      bool showMedia = true,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: NewsCard(
              header: newsEntry.title,
              subhead: newsEntry.subTitle,
              text: newsEntry.text,
              date: '15.10.24',
              author: newsEntry.author,
              category: newsEntry.category,
              showMedia: showMedia,
              imageUrl: newsEntry.imageUrl,
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    testWidgets('should display title, subtitle, and author', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(newsEntry: testNews));
      await tester.pump();

      expect(find.text('Test News Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
    });

    testWidgets('should display category label', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(newsEntry: testNews));
      await tester.pump();

      // Sport category should have 'Sport' label
      expect(find.text('Sport'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        createWidgetUnderTest(newsEntry: testNews, onTap: () => tapped = true),
      );
      await tester.pump();

      // Tap the first InkWell (the main card InkWell, not the one in the Chip)
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('should display date', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(newsEntry: testNews));
      await tester.pump();

      expect(find.text('15.10.24'), findsOneWidget);
    });

    testWidgets('should show media when showMedia is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(newsEntry: testNews, showMedia: true),
      );
      await tester.pump();

      // Should find a container with the image
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should not show media when showMedia is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(newsEntry: testNews, showMedia: false),
      );
      await tester.pump();

      // CachedNetworkImage should not be present
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('should handle news without image', (
      WidgetTester tester,
    ) async {
      final newsWithoutImage = NewsEntry(
        documentId: 'test-id-123',
        category: NewsCategory.music,
        title: 'Test News',
        text: 'Test text',
        author: 'Test Author',
        createdAt: DateTime(2024, 10, 15),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(newsEntry: newsWithoutImage),
      );
      await tester.pump();

      // Should not crash
      expect(find.text('Test News'), findsOneWidget);
    });

    testWidgets('should display different labels for different categories', (
      WidgetTester tester,
    ) async {
      // Test music category
      final musicNews = NewsEntry(
        documentId: 'test-id-123',
        category: NewsCategory.music,
        title: 'Music News',
        text: 'Test text',
        author: 'Test Author',
        createdAt: DateTime(2024, 10, 15),
      );

      await tester.pumpWidget(createWidgetUnderTest(newsEntry: musicNews));
      await tester.pump();

      expect(find.text('Musik'), findsOneWidget);
    });

    testWidgets('should display Sonstiges label for other category', (
      WidgetTester tester,
    ) async {
      final otherNews = NewsEntry(
        documentId: 'test-id-other',
        category: NewsCategory.other,
        title: 'Other News',
        text: 'Test text',
        author: 'Test Author',
        createdAt: DateTime(2024, 10, 15),
      );

      await tester.pumpWidget(createWidgetUnderTest(newsEntry: otherNews));
      await tester.pump();

      expect(find.text('Sonstiges'), findsOneWidget);
    });

    testWidgets('should have rounded corners by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(newsEntry: testNews));
      await tester.pump();

      // Get the first InkWell (the main card InkWell, not the one in the Chip)
      final inkWell = tester.widget<InkWell>(find.byType(InkWell).first);
      expect(inkWell.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('should handle long text content', (WidgetTester tester) async {
      final newsWithLongText = NewsEntry(
        documentId: 'test-id-123',
        category: NewsCategory.events,
        title: 'Test News',
        text: 'This is a very long text ' * 50,
        author: 'Test Author',
        createdAt: DateTime(2024, 10, 15),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(newsEntry: newsWithLongText),
      );
      await tester.pump();

      // Should not throw overflow error
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display subtitle when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(newsEntry: testNews));
      await tester.pump();

      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('should use text as fallback when no subtitle', (
      WidgetTester tester,
    ) async {
      final newsWithoutSubtitle = NewsEntry(
        documentId: 'test-id-123',
        category: NewsCategory.food,
        title: 'Food News',
        text: 'Delicious food article',
        author: 'Food Critic',
        createdAt: DateTime(2024, 10, 15),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(newsEntry: newsWithoutSubtitle),
      );
      await tester.pump();

      // Should display the text content
      expect(find.text('Delicious food article'), findsOneWidget);
    });

    testWidgets('should display person icon for author', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(newsEntry: testNews));
      await tester.pump();

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should handle all category types', (
      WidgetTester tester,
    ) async {
      for (var category in NewsCategory.values) {
        final news = NewsEntry(
          documentId: 'test-id-${category.name}',
          category: category,
          title: '${category.name} News',
          text: 'Test text',
          author: 'Test Author',
          createdAt: DateTime(2024, 10, 15),
        );

        await tester.pumpWidget(createWidgetUnderTest(newsEntry: news));
        await tester.pump();

        // Should not crash for any category
        expect(find.text('${category.name} News'), findsOneWidget);
      }
    });
  });
}

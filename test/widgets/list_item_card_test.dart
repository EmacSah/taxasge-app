import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Supposons que ListItemCard sera dans:
// import 'package:taxasge/widgets/list_item_card.dart'; 

// Définition d'un ListItemCard factice pour que le test puisse s'exécuter
// Remplace cela par l'importation réelle une fois le widget créé.
class ListItemCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final Color? iconColor;

  const ListItemCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.leadingIcon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ListTile(
        leading: leadingIcon != null ? Icon(leadingIcon, color: iconColor ?? Theme.of(context).primaryColor) : null,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
// Fin du ListItemCard factice


// Un widget wrapper pour fournir MaterialApp et le thème
Widget makeTestableWidget({required Widget child}) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('ListItemCard Tests', () {
    testWidgets('displays title and subtitle, and handles tap', (WidgetTester tester) async {
      String? tappedId;
      const String testTitle = 'Test Title';
      const String testSubtitle = 'Test Subtitle';
      const String itemId = 'item-123';

      await tester.pumpWidget(makeTestableWidget(
        child: ListItemCard(
          title: testTitle,
          subtitle: testSubtitle,
          onTap: () {
            tappedId = itemId;
          },
          leadingIcon: Icons.folder,
        ),
      ));

      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testSubtitle), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(tappedId, itemId);
    });

    testWidgets('displays only title if subtitle is null', (WidgetTester tester) async {
      String? tappedId;
      const String testTitle = 'Only Title';
      const String itemId = 'item-456';

      await tester.pumpWidget(makeTestableWidget(
        child: ListItemCard(
          title: testTitle,
          onTap: () {
            tappedId = itemId;
          },
        ),
      ));

      expect(find.text(testTitle), findsOneWidget);
      expect(find.text('Test Subtitle'), findsNothing); // S'assurer que le sous-titre n'est pas là
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      
      await tester.tap(find.byType(ListTile));
      await tester.pump();
      expect(tappedId, itemId);
    });
    
    testWidgets('displays leading icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(
        child: ListItemCard(
          title: "Title with Icon",
          onTap: () {},
          leadingIcon: Icons.business,
          iconColor: Colors.green,
        ),
      ));
      
      final iconFinder = find.byIcon(Icons.business);
      expect(iconFinder, findsOneWidget);
      
      final Icon iconWidget = tester.widget(iconFinder);
      expect(iconWidget.color, Colors.green);
    });

    testWidgets('does not display leading icon when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(
        child: ListItemCard(
          title: "Title without Icon",
          onTap: () {},
        ),
      ));
      
      // On s'attend à ne pas trouver d'icône spécifique, mais l'icône "trailing" sera là.
      // Donc, on vérifie l'absence d'une icône "leading" spécifique.
      expect(find.byIcon(Icons.folder), findsNothing);
      expect(find.byIcon(Icons.business), findsNothing);
    });
  });
}

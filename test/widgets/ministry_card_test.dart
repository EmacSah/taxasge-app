import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:taxasge/theme/extensions.dart';
import 'package:taxasge/theme/custom_widgets_styles.dart';

void main() {
  testWidgets('ministryCard displays title and icon', (tester) async {
    const title = 'TRANSPORTE';
    const icon = Icons.train;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomWidgetStyles.ministryCard(
            title: title,
            icon: icon,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text(title), findsOneWidget);
    expect(find.byIcon(icon), findsOneWidget);
  });
}

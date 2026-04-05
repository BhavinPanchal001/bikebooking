import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:bikebooking/features/home/presentation/widgets/product_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the normalized lifecycle label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ProductStatusBadge(status: ProductStatus.sold),
              ProductStatusBadge(status: 'completed'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Sold'), findsNWidgets(2));
  });
}

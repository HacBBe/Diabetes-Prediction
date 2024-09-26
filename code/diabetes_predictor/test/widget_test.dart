import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diabetes_predictor/main.dart';

void main() {
  testWidgets('Diabetes Predictor form widgets test',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that all input fields and the button are present
    expect(find.text('Số lần mang thai'), findsOneWidget);
    expect(find.text('Đường huyết'), findsOneWidget);
    expect(find.text('Huyết áp'), findsOneWidget);
    expect(find.text('Độ dày da'), findsOneWidget);
    expect(find.text('Insulin'), findsOneWidget);
    expect(find.text('Chỉ số BMI'), findsOneWidget);
    expect(find.text('Chỉ số gia đình'), findsOneWidget);
    expect(find.text('Tuổi'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Simulate user input
    await tester.enterText(
        find.byType(TextFormField).at(0), '1'); // Số lần mang thai
    await tester.enterText(
        find.byType(TextFormField).at(1), '120'); // Đường huyết
    await tester.enterText(find.byType(TextFormField).at(2), '70'); // Huyết áp
    await tester.enterText(find.byType(TextFormField).at(3), '20'); // Độ dày da
    await tester.enterText(find.byType(TextFormField).at(4), '90'); // Insulin
    await tester.enterText(
        find.byType(TextFormField).at(5), '25'); // Chỉ số BMI
    await tester.enterText(
        find.byType(TextFormField).at(6), '0.5'); // Chỉ số gia đình
    await tester.enterText(find.byType(TextFormField).at(7), '30'); // Tuổi

    // Tap the 'Dự đoán' button and trigger a frame
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify that the form submission logic is triggered
    // You can add more specific checks here based on what your app does after form submission
  });
}

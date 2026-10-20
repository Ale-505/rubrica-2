import 'package:flutter_test/flutter_test.dart';
import 'package:parking_uni/main.dart';

void main() {
  testWidgets('ParkingUni smoke test and initial load', (WidgetTester tester) async {
    // Construir la aplicación ParkingUni
    await tester.pumpWidget(const ParkingUniApp());

    // Verificar que el título principal esté presente
    expect(find.text('ParkingUni'), findsWidgets);
    expect(find.text('Disponibilidad actual'), findsOneWidget);
    expect(find.text('Total espacios'), findsOneWidget);
  });
}

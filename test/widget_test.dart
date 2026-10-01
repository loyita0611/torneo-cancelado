import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_cancelado/app.dart';

void main() {
  testWidgets('La app arranca y muestra el título del torneo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TorneoApp()));

    // Esperar que termine el primer frame y la carga inicial
    await tester.pump(const Duration(milliseconds: 100));

    // El título contiene "TORNEO"
    expect(find.textContaining('TORNEO'), findsOneWidget);
  });
}

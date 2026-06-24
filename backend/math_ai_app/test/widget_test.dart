import 'package:flutter_test/flutter_test.dart';

import 'package:math_ai_app/main.dart';

void main() {
  testWidgets('App loads and basic UI elements exist', (WidgetTester tester) async {
    // Uygulamayı başlat
    await tester.pumpWidget(const MathAIApp());

    // AppBar başlığı var mı?
    expect(find.text('Qwen-VL Matematik Çözücü'), findsOneWidget);

    // Fotoğraf placeholder var mı?
    expect(find.text('Henüz fotoğraf seçilmedi.'), findsOneWidget);

    // Butonlar var mı?
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Galeri'), findsOneWidget);

    // Çöz butonu var mı?
    expect(find.text('Soruyu Çöz!'), findsOneWidget);
  });
}
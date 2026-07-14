import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokolink/main.dart';

void main() {
  testWidgets('SokoLink app boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SokoLinkApp()));
    await tester.pump();
    expect(find.text('SokoLink'), findsWidgets);
  });
}

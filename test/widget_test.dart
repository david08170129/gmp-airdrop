import 'package:flutter_test/flutter_test.dart';

import 'package:gmp_airdrop/main.dart';

void main() {
  testWidgets('GMP Airdrop app renders product home', (tester) async {
    await tester.pumpWidget(const GmpAirdropApp());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Transfer files simply.\nOffline. Fast. Organized.'), findsOneWidget);
    expect(find.text('iPhone • Android • USB-C • Windows'), findsOneWidget);
  });
}

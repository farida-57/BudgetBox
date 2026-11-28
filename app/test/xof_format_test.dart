import 'package:budgetbox/core/format/xof_format.dart';
import 'package:flutter_test/flutter_test.dart';

// \u202F : espace fine insécable (milliers) ; \u00A0 : espace insécable avant la devise.
void main() {
  group('formatXof', () {
    test('sépare les milliers à la française', () {
      expect(formatXof(10000), '10\u202F000\u00A0XOF');
      expect(formatXof(1234567), '1\u202F234\u202F567\u00A0XOF');
    });

    test('n\'ajoute pas de séparateur sous 1 000', () {
      expect(formatXof(0), '0\u00A0XOF');
      expect(formatXof(999), '999\u00A0XOF');
      expect(formatXof(1000), '1\u202F000\u00A0XOF');
    });

    test('garde le signe d\'un montant négatif', () {
      expect(formatXof(-3333), '-3\u202F333\u00A0XOF');
    });

    test(
      'formate exactement un très grand entier (aucun arrondi flottant)',
      () {
        expect(
          formatXof(9007199254740991),
          '9\u202F007\u202F199\u202F254\u202F740\u202F991\u00A0XOF',
        );
      },
    );
  });
}

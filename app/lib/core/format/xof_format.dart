/// Présentation française d'un montant XOF entier : `10000` → « 10 000 XOF ».
///
/// Le formatage travaille sur les chiffres de l'entier (aucune conversion
/// en `double`), avec l'espace fine insécable (U+202F) comme séparateur
/// de milliers et une espace insécable (U+00A0) avant la devise, comme
/// le fait la locale `fr`.
library;

const _thousandsSeparator = '\u202F';
const _currencySpace = '\u00A0';

String formatXof(int amount, {String currency = 'XOF'}) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  if (amount < 0) {
    buffer.write('-');
  }
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) {
      buffer.write(_thousandsSeparator);
    }
    buffer.write(digits[i]);
  }
  buffer
    ..write(_currencySpace)
    ..write(currency);
  return buffer.toString();
}

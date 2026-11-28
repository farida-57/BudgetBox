/// Lecture stricte des réponses JSON des soldes.
///
/// Un montant XOF doit arriver comme un entier JSON : un nombre décimal
/// (`3333.5`, et même `3333.0`) ou un texte est refusé au lieu d'être converti.
library;

String readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  throw FormatException('Champ "$key" : texte attendu');
}

int readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  throw FormatException('Champ "$key" : entier attendu');
}

List<Map<String, dynamic>> readObjectList(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('Champ "$key" : liste attendue');
  }
  final items = <Map<String, dynamic>>[];
  for (final item in value) {
    if (item is! Map<String, dynamic>) {
      throw FormatException('Champ "$key" : objets attendus');
    }
    items.add(item);
  }
  return items;
}

/// Índice de búsqueda precomputado para la cartera.
///
/// La tokenización y normalización de cada [CobroItem] (acentos, alias de
/// manzana/casa/etapa, palabras sueltas) es costosa: hacerla en cada tecla
/// del buscador multiplica el trabajo por el número de cobros. Este índice
/// se construye UNA vez por carga de datos y luego cada consulta solo
/// compara tokens en memoria.
library;

import '../../features/cartera/models/cartera_models.dart';

/// Normaliza texto para búsqueda insensible a acentos, mayúsculas y diacríticos.
String normalizeSearchText(String input) {
  if (input.isEmpty) return '';
  var text = input.toLowerCase().trim();
  const withAccents = 'áéíóúüñÁÉÍÓÚÜÑ';
  const withoutAccents = 'aeiouunaeiouun';
  for (int i = 0; i < withAccents.length; i++) {
    text = text.replaceAll(withAccents[i], withoutAccents[i]);
  }
  return text;
}

/// Conjunto de tokens normalizados de un cobro, listos para ser consultados.
class CobroSearchEntry {
  final String cobroId;
  final Set<String> words;

  const CobroSearchEntry({required this.cobroId, required this.words});
}

/// Construye las palabras normalizadas de un cobro (incluye alias Mz/Casa/Etapa).
Set<String> buildCobroSearchWords(CobroItem c) {
  final etapaNorm = normalizeSearchText(c.etapa);
  final manzanaNorm = normalizeSearchText(c.manzana);
  final casaNorm = normalizeSearchText(c.casa);
  final nombreNorm = normalizeSearchText(c.nombre);
  final conceptoNorm = normalizeSearchText(c.concepto);
  final tituloNorm = normalizeSearchText(c.tituloCuota);
  final reciboNorm = normalizeSearchText(c.nroRecibo);
  final modalidadNorm = normalizeSearchText(c.modalidad);
  final estadoNorm = normalizeSearchText(c.estado);

  // Derivar letras y dígitos limpios para alias
  final mzChar =
      manzanaNorm.replaceAll(RegExp(r'[^a-z0-9]'), '').replaceFirst('manzana', '');
  final casaDigits = casaNorm.replaceAll(RegExp(r'[^0-9]'), '');
  final etapaDigits = etapaNorm.replaceAll(RegExp(r'[^0-9]'), '');

  final words = <String>{};
  void addWords(String s) {
    if (s.isEmpty) return;
    for (final w in s.split(RegExp(r'[\s,.-]+'))) {
      if (w.isNotEmpty) words.add(w);
    }
  }

  addWords(etapaNorm);
  addWords(manzanaNorm);
  addWords(casaNorm);
  addWords(nombreNorm);
  addWords(conceptoNorm);
  addWords(tituloNorm);
  addWords(reciboNorm);
  addWords(modalidadNorm);
  addWords(estadoNorm);

  // Alias útiles (ej. Mz C -> mzc, mz, c; Casa 1 -> c1, cs1, 1)
  if (mzChar.isNotEmpty) {
    words.addAll([mzChar, 'mz$mzChar', 'mza$mzChar', 'mz', 'mza']);
  }
  if (casaDigits.isNotEmpty) {
    words.addAll([casaDigits, 'c$casaDigits', 'cs$casaDigits']);
  }
  if (etapaDigits.isNotEmpty) {
    words.addAll([etapaDigits, 'et$etapaDigits']);
  }

  return words;
}

/// Índice inmutable cobroId → tokens. Constrúyelo al cargar datos y
/// reutilízalo en cada pulsación del buscador.
class CarteraSearchIndex {
  final Map<String, CobroSearchEntry> _entries;

  CarteraSearchIndex._(this._entries);

  factory CarteraSearchIndex.build(List<CobroItem> cobros) {
    final entries = <String, CobroSearchEntry>{};
    for (final cobro in cobros) {
      entries[cobro.id] = CobroSearchEntry(
        cobroId: cobro.id,
        words: buildCobroSearchWords(cobro),
      );
    }
    return CarteraSearchIndex._(entries);
  }

  /// Comprueba si el cobro con [cobroId] satisface la consulta multi-término.
  /// Cada token del usuario debe coincidir con alguna palabra del registro
  /// (exacta para tokens de 1 carácter, prefijo/subcadena para el resto).
  bool matches(String cobroId, String query) {
    final entry = _entries[cobroId];
    if (entry == null) return false;

    final normQuery = normalizeSearchText(query);
    if (normQuery.isEmpty) return true;

    final tokens = normQuery
        .split(RegExp(r'[\s,.-]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return true;

    for (final token in tokens) {
      final tokenLen = token.length;
      bool tokenMatched = false;

      for (final word in entry.words) {
        if (tokenLen == 1) {
          // Token de 1 caracter: coincidencia exacta de palabra
          if (word == token) {
            tokenMatched = true;
            break;
          }
        } else {
          // Token de 2+ caracteres: prefijo o subcadena
          if (word.contains(token)) {
            tokenMatched = true;
            break;
          }
        }
      }

      if (!tokenMatched) return false;
    }
    return true;
  }
}

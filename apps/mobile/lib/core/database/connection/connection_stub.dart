import 'package:drift/drift.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    throw UnsupportedError(
      'La base de datos SQLite local no está disponible en esta plataforma (Web).',
    );
  });
}

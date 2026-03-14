import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tazakar/infrastructure/database/database_helper.dart';

/// Async provider that initialises and exposes the encrypted SQLCipher DB.
/// All repositories depend on this provider.
final databaseProvider = FutureProvider<Database>((ref) async {
  return DatabaseHelper.database;
});

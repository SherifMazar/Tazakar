import 'dart:developer' as dev;

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// CategorySeeder
// ---------------------------------------------------------------------------
//
// Seeds the 8 system categories into the categories table on every cold
// start. All inserts use INSERT OR IGNORE so the operation is fully
// idempotent — running it on a database that already contains these rows
// is a no-op.
//
// System category rules (enforced here and at the repository layer):
//   • is_system = 1  →  cannot be deleted by the user
//   • id is a stable UUID v5 (namespace + name) so the same logical
//     category always gets the same id across installs and re-installs.
//     This matters for audit_log foreign-key references and any future
//     iCloud/local backup restore.
//
// Colour hex values use the Tazakar palette (DEC-12):
//   Teal   #1ABC9C   Coral  #E8553E
//   Gold   #F0A500   Navy   #0D1117
//   Plus four complementary accent colours for visual variety.
// ---------------------------------------------------------------------------

class CategorySeeder {
  CategorySeeder._();

  // Stable UUID v5 namespace for Tazakar system categories.
  // Changing this value would change all generated IDs — do not modify.
  static const _namespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // UUID namespace:URL

  static final _uuid = const Uuid();

  /// Seeds all 8 system categories.
  /// Safe to call on every app start — uses INSERT OR IGNORE throughout.
  static Future<void> seed(Database db) async {
    dev.log('CategorySeeder: start', name: 'Tazakar.DB');

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      for (final category in _systemCategories(nowMs)) {
        await txn.insert(
          'categories',
          category,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });

    dev.log('CategorySeeder: 8 system categories seeded.', name: 'Tazakar.DB');
  }

  // -------------------------------------------------------------------------
  // System category definitions
  // -------------------------------------------------------------------------
  //
  // Each entry has:
  //   id         — stable UUID v5 derived from the English slug
  //   name_ar    — Arabic label (Modern Standard + common Gulf usage)
  //   name_en    — English label
  //   icon_code  — Material icon codepoint as hex string (e.g. 'e8b8')
  //                resolved in the UI via IconData(int.parse(code, radix: 16))
  //   color_hex  — Category accent colour
  //   is_system  — 1 for all entries here
  //   sort_order — Display order in category picker (ascending)

  static List<Map<String, dynamic>> _systemCategories(int nowMs) => [
        // 1. General — catch-all default
        _row(
          slug: 'general',
          nameAr: 'عام',
          nameEn: 'General',
          iconCode: 'e8b8', // notifications
          colorHex: '#1ABC9C', // Teal
          sortOrder: 1,
          nowMs: nowMs,
        ),

        // 2. Work
        _row(
          slug: 'work',
          nameAr: 'عمل',
          nameEn: 'Work',
          iconCode: 'e8f9', // work
          colorHex: '#0D1117', // Navy
          sortOrder: 2,
          nowMs: nowMs,
        ),

        // 3. Personal
        _row(
          slug: 'personal',
          nameAr: 'شخصي',
          nameEn: 'Personal',
          iconCode: 'e7fd', // person
          colorHex: '#E8553E', // Coral
          sortOrder: 3,
          nowMs: nowMs,
        ),

        // 4. Health
        _row(
          slug: 'health',
          nameAr: 'صحة',
          nameEn: 'Health',
          iconCode: 'e548', // favorite (heart)
          colorHex: '#E53935', // Red accent
          sortOrder: 4,
          nowMs: nowMs,
        ),

        // 5. Shopping
        _row(
          slug: 'shopping',
          nameAr: 'تسوق',
          nameEn: 'Shopping',
          iconCode: 'e8cc', // shopping_cart
          colorHex: '#F0A500', // Gold
          sortOrder: 5,
          nowMs: nowMs,
        ),

        // 6. Travel
        _row(
          slug: 'travel',
          nameAr: 'سفر',
          nameEn: 'Travel',
          iconCode: 'e8b0', // flight_takeoff
          colorHex: '#039BE5', // Blue accent
          sortOrder: 6,
          nowMs: nowMs,
        ),

        // 7. Education
        _row(
          slug: 'education',
          nameAr: 'تعليم',
          nameEn: 'Education',
          iconCode: 'e80c', // school
          colorHex: '#8E24AA', // Purple accent
          sortOrder: 7,
          nowMs: nowMs,
        ),

        // 8. Finance
        _row(
          slug: 'finance',
          nameAr: 'مالية',
          nameEn: 'Finance',
          iconCode: 'e263', // attach_money
          colorHex: '#43A047', // Green accent
          sortOrder: 8,
          nowMs: nowMs,
        ),
      ];

  // -------------------------------------------------------------------------
  // Row builder
  // -------------------------------------------------------------------------

  static Map<String, dynamic> _row({
    required String slug,
    required String nameAr,
    required String nameEn,
    required String iconCode,
    required String colorHex,
    required int sortOrder,
    required int nowMs,
  }) {
    // UUID v5 (SHA-1 namespace + slug) — deterministic, stable across installs.
    final id = _uuid.v5(_namespace, 'tazakar.category.$slug');

    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'icon_code': iconCode,
      'color_hex': colorHex,
      'is_system': 1,
      'sort_order': sortOrder,
      'created_at': nowMs,
    };
  }
}

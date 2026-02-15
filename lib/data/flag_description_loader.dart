/*
 DOC: DataSource
 Title: Flag Description Loader
 Purpose: Loads optional non-color flag descriptions for accessibility support.
*/
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads optional flag descriptions keyed by normalized country name.
Future<Map<String, String>> loadFlagDescriptions() async {
  try {
    final raw = await rootBundle.loadString(
      'assets/metadata/flag_descriptions.json',
    );
    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const {};
    }

    final result = <String, String>{};
    decoded.forEach((key, value) {
      if (value is String) {
        final normalizedKey = key.trim();
        final description = value.trim();
        if (normalizedKey.isNotEmpty && description.isNotEmpty) {
          result[normalizedKey] = description;
        }
      }
    });
    return result;
  } catch (_) {
    // Optional metadata file: failures should not block quiz loading.
    return const {};
  }
}

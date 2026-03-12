import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher._();

  static String hash(String rawPassword) {
    final normalizedPassword = rawPassword.trim();
    return sha256.convert(utf8.encode(normalizedPassword)).toString();
  }

  static bool isSha256Hash(String value) {
    final sha256Pattern = RegExp(r'^[a-f0-9]{64}$');
    return sha256Pattern.hasMatch(value);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:hoque_family_chores/data/auth/apple_nonce.dart';

void main() {
  test('generateNonce returns a string of the requested length', () {
    expect(generateNonce(length: 32).length, 32);
  });

  test('generateNonce returns different values each call', () {
    expect(generateNonce(), isNot(generateNonce()));
  });

  test('sha256OfString matches crypto sha256 hex', () {
    expect(sha256OfString('abc'),
        sha256.convert(utf8.encode('abc')).toString());
  });
}

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

const _charset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';

/// Returns a cryptographically secure random string of ``length`` characters.
///
/// Uses the alphanumeric charset plus ``-`` and ``.`` for compatibility
/// with Apple Sign In's nonce requirement. Each character is randomly
/// selected using ``Random.secure()``.
///
/// :param length: Number of characters to generate. Defaults to 32.
/// :return: A cryptographically secure random string.
String generateNonce({int length = 32}) {
  final random = Random.secure();
  return List.generate(length, (_) => _charset[random.nextInt(_charset.length)])
      .join();
}

/// Returns the hex-encoded SHA-256 digest of the input string.
///
/// Encodes the input string as UTF-8 bytes, computes the SHA-256 hash,
/// and returns the result as a lowercase hexadecimal string.
///
/// :param input: The input string to hash.
/// :return: The hex-encoded SHA-256 hash of the input.
String sha256OfString(String input) =>
    sha256.convert(utf8.encode(input)).toString();

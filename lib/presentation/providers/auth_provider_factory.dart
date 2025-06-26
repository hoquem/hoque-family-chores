import 'auth_provider_base.dart';
import 'auth_provider.dart';
import 'mock_auth_provider.dart';

class AuthProviderFactory {
  static AuthProviderBase create({required bool useMock}) {
    if (useMock) {
      return MockAuthProvider();
    } else {
      return AuthProvider();
    }
  }
} 
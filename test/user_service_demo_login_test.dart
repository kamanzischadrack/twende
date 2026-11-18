import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/core/auth/permissions.dart';
import 'package:twende_flutter/core/mock/mock_data.dart';
import 'package:twende_flutter/services/user_service.dart';

void main() {
  group('mock demo sign-in', () {
    test('valid credentials sign in to the matching role account', () async {
      final account = MockData.demoAccounts.first;

      final result = await UserService.instance.signIn({
        'email': account.email,
        'password': account.password,
      });

      expect(result.status, 200);
      expect(result.user?.email, account.email);
      expect(result.user?.role, appRoleKey(account.role));
    });

    test('rejects a demo email with the wrong password', () async {
      final account = MockData.demoAccounts.first;

      final result = await UserService.instance.signIn({
        'email': account.email,
        'password': 'wrong-password',
      });

      expect(result.status, 401);
      expect(result.user, isNull);
    });
  });
}

import 'package:bikebooking/features/auth/data/models/app_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUserModel', () {
    test('defaults missing account status to active', () {
      final user = AppUserModel.fromMap(
        <String, dynamic>{
          'phoneNumber': '9876543210',
        },
        'user-1',
      );

      expect(user.accountStatus, 'active');
      expect(user.adminBlocked, isFalse);
      expect(user.isBlocked, isFalse);
    });

    test('treats blocked account status as blocked access', () {
      final user = AppUserModel.fromMap(
        <String, dynamic>{
          'phoneNumber': '9876543210',
          'accountStatus': 'blocked',
        },
        'user-2',
      );

      expect(user.accountStatus, 'blocked');
      expect(user.isBlocked, isTrue);
    });

    test('treats adminBlocked flag as blocked even when status says active',
        () {
      final user = AppUserModel.fromMap(
        <String, dynamic>{
          'phoneNumber': '9876543210',
          'accountStatus': 'active',
          'adminBlocked': true,
          'adminBlockedBy': 'admin@example.com',
        },
        'user-3',
      );

      expect(user.accountStatus, 'blocked');
      expect(user.adminBlocked, isTrue);
      expect(user.adminBlockedBy, 'admin@example.com');
      expect(user.isBlocked, isTrue);
    });
  });
}

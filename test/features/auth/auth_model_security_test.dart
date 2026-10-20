import 'package:flutter_test/flutter_test.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel Security and Profile Mapping Tests', () {
    test('toJson excludes plaintext password by default', () {
      final user = UserModel(
        id: 'user-uuid-1234',
        name: 'Alice Owner',
        email: 'alice@voryn.com',
        phone: '+1234567890',
        role: 'owner',
        userid: 'alice_owner',
        ownerId: 'user-uuid-1234',
        authUserId: 'auth-uuid-9999',
        password: 'super_secret_password',
      );

      final json = user.toJson();

      // Password MUST NOT be in serialized JSON
      expect(json.containsKey('password'), isFalse);
      expect(json['id'], equals('user-uuid-1234'));
      expect(json['owner_id'], equals('user-uuid-1234'));
      expect(json['auth_user_id'], equals('auth-uuid-9999'));
      expect(json['email'], equals('alice@voryn.com'));
      expect(json['role'], equals('owner'));
    });

    test(
      'toJson can include password only when explicitly requested for internal testing',
      () {
        final user = UserModel(id: 'user-uuid-1234', password: 'test_password');

        final json = user.toJson(includePassword: true);
        expect(json['password'], equals('test_password'));
      },
    );

    test(
      'fromJson correctly maps auth_user_id and preserves public.users.id and owner_id',
      () {
        final backendRow = {
          'id': 'db-user-uuid-001',
          'userid': 'owner_01',
          'name': 'Bob Owner',
          'email': 'bob@voryn.com',
          'phone': '9876543210',
          'role': 'owner',
          'owner_id': 'db-user-uuid-001',
          'auth_user_id': 'supabase-auth-user-id-555',
          'password': 'hashed_or_legacy_password',
          'status': 'active',
          'is_active': true,
          'permissions': ['view_tasks', 'add_tasks'],
          'businessPermissions': {
            'biz-1': ['view_tasks'],
          },
        };

        final model = UserModel.fromJson(backendRow);

        expect(model.id, equals('db-user-uuid-001'));
        expect(model.ownerId, equals('db-user-uuid-001'));
        expect(model.authUserId, equals('supabase-auth-user-id-555'));
        expect(model.email, equals('bob@voryn.com'));
        expect(model.role, equals('owner'));
        expect(model.isOwner, isTrue);
        expect(model.isStaff, isFalse);
        expect(model.customPermissions, contains('view_tasks'));
        expect(model.businessPermissions.containsKey('biz-1'), isTrue);
      },
    );

    test('Staff profile preserves existing ownerId relationship', () {
      final staffRow = {
        'id': 'staff-uuid-002',
        'userid': 'staff_john',
        'name': 'John Staff',
        'email': 'john@voryn.com',
        'role': 'staff',
        'owner_id': 'db-user-uuid-001', // References owner
        'auth_user_id': 'supabase-auth-user-id-777',
      };

      final staff = UserModel.fromJson(staffRow);

      expect(staff.id, equals('staff-uuid-002'));
      expect(staff.ownerId, equals('db-user-uuid-001'));
      expect(staff.isStaff, isTrue);
      expect(staff.isOwner, isFalse);
    });

    test('copyWith properly copies authUserId and other fields', () {
      final user = UserModel(
        id: 'u1',
        email: 'test@voryn.com',
        authUserId: 'auth-1',
      );

      final updated = user.copyWith(authUserId: 'auth-2');

      expect(updated.id, equals('u1'));
      expect(updated.email, equals('test@voryn.com'));
      expect(updated.authUserId, equals('auth-2'));
    });
  });
}

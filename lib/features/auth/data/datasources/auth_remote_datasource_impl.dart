import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'auth_remote_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabase;

  AuthRemoteDataSourceImpl({required this.supabase});

  @override
  Future<Map<String, dynamic>?> getUserByUserId(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('userid', userId.trim())
          .maybeSingle()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw ServerException(
                'Server is taking too long to respond. Please try again.',
              );
            },
          );

      if (response == null) {
        throw UserNotFoundException();
      }

      final userMap = Map<String, dynamic>.from(response);
      try {
        print("user map:-${userMap['id'].toString()}");
        final permsResponse = await supabase
            .from('staff_permissions')
            .select()
            .eq('user_id', userMap['id'])
            .timeout(const Duration(seconds: 10));

        final bizPerms = <String, List<String>>{};
        for (var row in permsResponse) {
          final bizId = row['business_id']?.toString() ?? '';
          if (bizId.isEmpty) continue;

          final perms = <String>[];
          if (row['can_view_tasks'] == true) perms.add('view_tasks');
          if (row['can_add_tasks'] == true) perms.add('add_tasks');
          if (row['can_view_accounts'] == true) perms.add('view_accounts');
          bizPerms[bizId] = perms;
        }

        final flatPerms = <String>{};
        for (var perms in bizPerms.values) {
          flatPerms.addAll(perms);
        }

        userMap['permissions'] = flatPerms.toList();
        userMap['businessPermissions'] = bizPerms;
      } catch (e) {
        print("error:-${e.toString()}");
        // If staff_permissions query fails, continue without permissions
      }

      return userMap;
    } on AppAuthException {
      rethrow;
    } catch (e) {
      print("error in user id:-${e.toString()}");
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection')) {
        throw NetworkException();
      } else if (errorStr.contains('timeout')) {
        throw ServerException(
          'Server is taking too long to respond. Please try again.',
        );
      }
      throw ServerException();
    }
  }

  @override
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    final response = await supabase
        .from('users')
        .select()
        .eq('userid', userId)
        .eq('password', oldPassword)
        .maybeSingle();

    if (response == null) {
      throw Exception('Incorrect old password.');
    }

    await supabase
        .from('users')
        .update({'password': newPassword})
        .eq('userid', userId);

    return true;
  }
}

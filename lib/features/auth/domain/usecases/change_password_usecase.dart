import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase({required this.repository});

  Future<bool> execute(String userId, String oldPassword, String newPassword) {
    return repository.changePassword(userId, oldPassword, newPassword);
  }
}

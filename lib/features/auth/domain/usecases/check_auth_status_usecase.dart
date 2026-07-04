import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase({required this.repository});

  Future<UserModel?> execute() {
    return repository.checkAuthStatus();
  }
}

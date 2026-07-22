import 'package:bizos/features/contacts/domain/entities/contact_enitiy.dart';
import 'package:bizos/features/contacts/domain/repositories/contact_repository.dart';

class PickContact {
  final ContactRepository contactRepository;
  PickContact(this.contactRepository);
  Future<ContactEnitiy?> call() async {
    return await contactRepository.pickContact();
  }
}

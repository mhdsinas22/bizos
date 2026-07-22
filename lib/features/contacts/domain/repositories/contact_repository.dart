import 'package:bizos/features/contacts/domain/entities/contact_enitiy.dart';

abstract class ContactRepository {
  Future<ContactEnitiy?> pickContact();
}

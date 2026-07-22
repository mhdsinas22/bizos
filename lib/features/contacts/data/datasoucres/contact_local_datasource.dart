import 'package:bizos/features/contacts/domain/entities/contact_enitiy.dart';

abstract class ContactLocalDatasource {
  Future<ContactEnitiy?> pickSingleContact();
}

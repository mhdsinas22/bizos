import 'package:bizos/features/contacts/data/datasoucres/contact_local_datasource.dart';
import 'package:bizos/features/contacts/domain/entities/contact_enitiy.dart';
import 'package:bizos/features/contacts/domain/repositories/contact_repository.dart';

class ContactRepositoriesImpl implements ContactRepository {
  final ContactLocalDatasource contactLocalDatasource;
  ContactRepositoriesImpl(this.contactLocalDatasource);
  @override
  Future<ContactEnitiy?> pickContact() async {
    return await contactLocalDatasource.pickSingleContact();
  }
}

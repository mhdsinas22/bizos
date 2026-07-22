import 'package:bizos/features/contacts/data/datasoucres/contact_local_datasource.dart';
import 'package:bizos/features/contacts/domain/entities/contact_enitiy.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

class ContactLocalDatasourceImpl implements ContactLocalDatasource {
  final FlutterNativeContactPicker _picker = FlutterNativeContactPicker();
  @override
  Future<ContactEnitiy?> pickSingleContact() async {
    final contact = await _picker.selectContact();
    if (contact != null &&
        contact.phoneNumbers != null &&
        contact.phoneNumbers!.isNotEmpty) {
      return ContactEnitiy(
        name: contact.fullName ?? "No Name",
        phoneNumber: contact.phoneNumbers!.first,
      );
    }
    return null;
  }
}

import 'package:bizos/features/contacts/domain/entities/contact_enitiy.dart';

enum contactstatus { initail, loading, selected, failure }

class ContactState {
  final contactstatus status;
  final ContactEnitiy? contact;
  final String? errormessage;
  const ContactState({
    this.status = contactstatus.initail,
    this.contact,
    this.errormessage,
  });
  ContactState copyWith({
    contactstatus? status,
    ContactEnitiy? contact,
    String? errormessage,
  }) {
    return ContactState(
      status: status ?? this.status,
      contact: contact ?? this.contact,
      errormessage: errormessage ?? this.errormessage,
    );
  }
}

import 'package:bizos/features/contacts/domain/entities/contact_enitiy.dart';

enum ContactStatus { initial, loading, selected, failure }

class ContactState {
  final ContactStatus status;
  final ContactEnitiy? contact;
  final String? errormessage;
  const ContactState({
    this.status = ContactStatus.initial,
    this.contact,
    this.errormessage,
  });
  ContactState copyWith({
    ContactStatus? status,
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

import 'package:bizos/features/contacts/domain/usecases/pick_contact.dart';
import 'package:bizos/features/contacts/presentation/bloc/contact_event.dart';
import 'package:bizos/features/contacts/presentation/bloc/contact_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactBloc extends Bloc<ContactEvent, ContactState> {
  final PickContact pickContact;
  ContactBloc(this.pickContact) : super(const ContactState()) {
    on<SelectContactEvent>(_onSelectContact);
  }
  Future<void> _onSelectContact(
    SelectContactEvent event,
    Emitter<ContactState> emit,
  ) async {
    emit(state.copyWith(status: ContactStatus.loading));
    try {
      final contact = await pickContact();
      if (contact != null) {
        emit(state.copyWith(status: ContactStatus.selected, contact: contact));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ContactStatus.failure,
          errormessage: "${e.toString()} Failed to Pick Contact",
        ),
      );
    }
  }
}

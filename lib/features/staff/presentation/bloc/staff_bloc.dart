import 'package:bizos/features/staff/presentation/bloc/staff_event.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/staff/domain/repo/staff_repository.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffRepository staffRepository;

  StaffBloc(this.staffRepository) : super(StaffInitial()) {
    on<FetchStaffEvent>((event, emit) async {
      emit(StaffLoading());
      try {
        final list = await staffRepository.getStaffList(event.ownerId);
        emit(StaffLoaded(list));
      } catch (e) {
        emit(StaffError(_cleanErrorMessage(e)));
      }
    });

    on<CreateStaffEvent>((event, emit) async {
      final previousState = state;
      try {
        await staffRepository.createStaff(
          event.staff,
          event.ownerId,
          event.selectedBusinessIds,
        );
        add(FetchStaffEvent(event.ownerId));
      } catch (e) {
        final cleanMsg = _cleanErrorMessage(e);
        emit(StaffError(cleanMsg));
        if (previousState is StaffLoaded) {
          emit(previousState);
        }
      }
    });

    on<UpdateStaffEvent>((event, emit) async {
      final previousState = state;
      try {
        await staffRepository.updateStaff(
          event.staff,
          event.selectedBusinessIds,
        );
        add(FetchStaffEvent(event.ownerId));
      } catch (e) {
        final cleanMsg = _cleanErrorMessage(e);
        emit(StaffError(cleanMsg));
        if (previousState is StaffLoaded) {
          emit(previousState);
        }
      }
    });

    on<LoadStaffBusinessesEvent>((event, emit) async {
      final currentState = state;
      if (currentState is StaffLoaded) {
        try {
          final businesses =
              await staffRepository.getStaffBusinesses(event.staffId);
          emit(StaffLoaded(currentState.staffList, businesses));
        } catch (e) {
          emit(StaffError(_cleanErrorMessage(e)));
        }
      }
    });

    on<DeleteStaffEvent>((event, emit) async {
      final previousState = state;
      try {
        await staffRepository.deleteStaff(event.userId);
        add(FetchStaffEvent(event.ownerId));
      } catch (e) {
        final cleanMsg = _cleanErrorMessage(e);
        emit(StaffError(cleanMsg));
        if (previousState is StaffLoaded) {
          emit(previousState);
        }
      }
    });

    on<FetchStaffByBusinessEvent>((event, emit) async {
      emit(StaffLoading());
      try {
        final list = await staffRepository.getStaffByBusiness(event.businessId);
        emit(StaffLoaded(list));
      } catch (e) {
        emit(StaffError(_cleanErrorMessage(e)));
      }
    });
  }

  static String _cleanErrorMessage(dynamic error) {
    var msg = error.toString().trim();
    while (msg.startsWith('Exception: ')) {
      msg = msg.substring(11).trim();
    }
    return msg;
  }
}


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
        emit(StaffError(e.toString()));
      }
    });

    on<CreateStaffEvent>((event, emit) async {
      emit(StaffLoading());
      try {
        await staffRepository.createStaff(
          event.staff,
          event.ownerId,
          event.selectedBusinessIds,
        );
        add(FetchStaffEvent(event.ownerId));
      } catch (e) {
        emit(StaffError(e.toString()));
      }
    });

    on<UpdateStaffEvent>((event, emit) async {
      emit(StaffLoading());
      try {
        await staffRepository.updateStaff(event.staff);
        add(FetchStaffEvent(event.ownerId));
      } catch (e) {
        emit(StaffError(e.toString()));
      }
    });

    on<DeleteStaffEvent>((event, emit) async {
      emit(StaffLoading());
      try {
        await staffRepository.deleteStaff(event.userId);
        add(FetchStaffEvent(event.ownerId));
      } catch (e) {
        emit(StaffError(e.toString()));
      }
    });
  }
}

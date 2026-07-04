import 'package:bizos/features/business/domain/repo/business_repository.dart';
import 'package:bizos/features/business/bloc/business_event.dart';
import 'package:bizos/features/business/bloc/business_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusinessBloc extends Bloc<BusinessEvent, BusinessState> {
  final BusinessRepository businessRepository;

  BusinessBloc(this.businessRepository) : super(BusinessInitial()) {
    on<FetchBusinessesEvent>((event, emit) async {
      print("FetchBusinessesEvent");
      emit(BusinessLoading());
      try {
        final businesses = await businessRepository.getBusinesses(
          event.ownerId,
        );
        print("Businesses: ${businesses.length}");
        emit(BusinessLoaded(businesses));
      } catch (e) {
        emit(BusinessError(e.toString()));
      }
    });

    on<CreateBusinessEvent>((event, emit) async {
      emit(BusinessLoading());
      try {
        await businessRepository.createBusiness(event.business);
        add(FetchBusinessesEvent(event.business.ownerId));
      } catch (e) {
        emit(BusinessError(e.toString()));
      }
    });

    on<UpdateBusinessEvent>((event, emit) async {
      emit(BusinessLoading());
      try {
        await businessRepository.updateBusiness(event.business);
        add(FetchBusinessesEvent(event.business.ownerId));
      } catch (e) {
        emit(BusinessError(e.toString()));
      }
    });

    on<DeleteBusinessEvent>((event, emit) async {
      emit(BusinessLoading());
      try {
        await businessRepository.deleteBusiness(event.id);
        add(FetchBusinessesEvent(event.ownerId));
      } catch (e) {
        emit(BusinessError(e.toString()));
      }
    });
  }
}

import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/invoice_settings/domain/entities/invoice_settings_entity.dart';
import 'package:bizos/features/invoice_settings/domain/repositories/invoice_settings_repository.dart';

// EVENTS
abstract class InvoiceSettingsEvent extends Equatable {
  const InvoiceSettingsEvent();
  @override
  List<Object?> get props => [];
}

class FetchInvoiceSettingsEvent extends InvoiceSettingsEvent {
  final String businessId;

  const FetchInvoiceSettingsEvent(this.businessId);

  @override
  List<Object?> get props => [businessId];
}

class SaveInvoiceSettingsEvent extends InvoiceSettingsEvent {
  final InvoiceSettingsEntity settings;

  const SaveInvoiceSettingsEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

class UploadLogoEvent extends InvoiceSettingsEvent {
  final String businessId;
  final File file;
  final InvoiceSettingsEntity currentSettings;

  const UploadLogoEvent({
    required this.businessId,
    required this.file,
    required this.currentSettings,
  });

  @override
  List<Object?> get props => [businessId, file, currentSettings];
}

class DeleteLogoEvent extends InvoiceSettingsEvent {
  final InvoiceSettingsEntity currentSettings;

  const DeleteLogoEvent({required this.currentSettings});

  @override
  List<Object?> get props => [currentSettings];
}

// STATES
abstract class InvoiceSettingsState extends Equatable {
  const InvoiceSettingsState();
  @override
  List<Object?> get props => [];
}

class InvoiceSettingsInitial extends InvoiceSettingsState {}

class InvoiceSettingsLoading extends InvoiceSettingsState {}

class InvoiceSettingsLoaded extends InvoiceSettingsState {
  final InvoiceSettingsEntity settings;

  const InvoiceSettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class InvoiceSettingsSavedSuccess extends InvoiceSettingsState {
  final InvoiceSettingsEntity settings;

  const InvoiceSettingsSavedSuccess(this.settings);

  @override
  List<Object?> get props => [settings];
}

class LogoUploadingState extends InvoiceSettingsState {
  final InvoiceSettingsEntity currentSettings;

  const LogoUploadingState(this.currentSettings);

  @override
  List<Object?> get props => [currentSettings];
}

class LogoUploadedSuccessState extends InvoiceSettingsState {
  final String logoUrl;
  final InvoiceSettingsEntity settings;

  const LogoUploadedSuccessState({
    required this.logoUrl,
    required this.settings,
  });

  @override
  List<Object?> get props => [logoUrl, settings];
}

class InvoiceSettingsError extends InvoiceSettingsState {
  final String message;

  const InvoiceSettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
class InvoiceSettingsBloc extends Bloc<InvoiceSettingsEvent, InvoiceSettingsState> {
  final InvoiceSettingsRepository repository;

  InvoiceSettingsBloc({required this.repository}) : super(InvoiceSettingsInitial()) {
    on<FetchInvoiceSettingsEvent>(_onFetch);
    on<SaveInvoiceSettingsEvent>(_onSave);
    on<UploadLogoEvent>(_onUploadLogo);
    on<DeleteLogoEvent>(_onDeleteLogo);
  }

  Future<void> _onFetch(
    FetchInvoiceSettingsEvent event,
    Emitter<InvoiceSettingsState> emit,
  ) async {
    emit(InvoiceSettingsLoading());
    try {
      final settings = await repository.getSettings(event.businessId);
      emit(InvoiceSettingsLoaded(settings));
    } catch (e) {
      emit(InvoiceSettingsError(_cleanErrorMessage(e)));
    }
  }

  Future<void> _onSave(
    SaveInvoiceSettingsEvent event,
    Emitter<InvoiceSettingsState> emit,
  ) async {
    emit(InvoiceSettingsLoading());
    try {
      final saved = await repository.saveSettings(event.settings);
      emit(InvoiceSettingsSavedSuccess(saved));
      emit(InvoiceSettingsLoaded(saved));
    } catch (e) {
      emit(InvoiceSettingsError(_cleanErrorMessage(e)));
    }
  }

  Future<void> _onUploadLogo(
    UploadLogoEvent event,
    Emitter<InvoiceSettingsState> emit,
  ) async {
    emit(LogoUploadingState(event.currentSettings));
    try {
      final logoUrl = await repository.uploadLogo(
        businessId: event.businessId,
        file: event.file,
      );
      final updatedSettings = event.currentSettings.copyWith(logoUrl: logoUrl);
      try {
        await repository.saveSettings(updatedSettings);
      } catch (_) {
        // Fallback: settings will also be saved when user submits the form
      }
      emit(LogoUploadedSuccessState(logoUrl: logoUrl, settings: updatedSettings));
      emit(InvoiceSettingsLoaded(updatedSettings));
    } catch (e) {
      emit(InvoiceSettingsError(_cleanErrorMessage(e)));
      emit(InvoiceSettingsLoaded(event.currentSettings));
    }
  }

  Future<void> _onDeleteLogo(
    DeleteLogoEvent event,
    Emitter<InvoiceSettingsState> emit,
  ) async {
    final oldUrl = event.currentSettings.logoUrl;
    final updatedSettings = event.currentSettings.copyWith(logoUrl: '');
    try {
      await repository.saveSettings(updatedSettings);
    } catch (_) {}
    emit(InvoiceSettingsLoaded(updatedSettings));

    if (oldUrl.isNotEmpty) {
      try {
        await repository.deleteLogo(logoUrl: oldUrl);
      } catch (_) {
        // Silently handle logo deletion failure
      }
    }
  }

  String _cleanErrorMessage(dynamic error) {
    final str = error.toString();
    if (str.contains('PostgRESTException') ||
        str.contains('AuthException')) {
      if (str.contains('permission') ||
          str.contains('policy') ||
          str.contains('row-level security') ||
          str.contains('unauthorized') ||
          str.contains('403')) {
        return 'Access denied. You do not have permission to modify invoice settings or upload logos.';
      }
      return 'Database operation failed. Please check your connection and try again.';
    }
    return str.replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
  }
}

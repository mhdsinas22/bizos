import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/staff/data/datasource/staff_remote_datasouceimpl.dart';
import 'package:bizos/features/staff/data/models/staff_business_model.dart';
import 'package:bizos/features/staff/domain/repo/staff_repository.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_event.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStaffRepository implements StaffRepository {
  Exception? createStaffError;
  List<UserModel> staffList = [];

  @override
  Future<void> createStaff(
    UserModel staff,
    String ownerId,
    List<String> selectedBusinessIds,
  ) async {
    if (createStaffError != null) {
      throw createStaffError!;
    }
  }

  @override
  Future<List<UserModel>> getStaffList(String ownerId) async {
    return staffList;
  }

  @override
  Future<void> updateStaff(
    UserModel staff,
    List<String> selectedBusinessIds,
  ) async {}

  @override
  Future<void> deleteStaff(String userId) async {}

  @override
  Future<List<StaffBusinessModel>> getStaffBusinesses(String staffId) async {
    return [];
  }

  @override
  Future<List<UserModel>> getStaffByBusiness(String businessId) async {
    return [];
  }
}

void main() {
  group('StaffRemoteDatasourceImpl.extractErrorMessage Tests', () {
    test('extracts direct error string from Map', () {
      final data = {'error': 'A user with this email address already exists.'};
      expect(
        StaffRemoteDatasourceImpl.extractErrorMessage(data),
        'A user with this email address already exists.',
      );
    });

    test('extracts nested error message from Map', () {
      final data = {
        'error': {'message': 'Email address is invalid.'}
      };
      expect(
        StaffRemoteDatasourceImpl.extractErrorMessage(data),
        'Email address is invalid.',
      );
    });

    test('extracts message key from Map when error key is absent', () {
      final data = {'message': 'Staff creation limit reached.'};
      expect(
        StaffRemoteDatasourceImpl.extractErrorMessage(data),
        'Staff creation limit reached.',
      );
    });

    test('extracts error from JSON string', () {
      const jsonStr = '{"error": "User already registered in the system."}';
      expect(
        StaffRemoteDatasourceImpl.extractErrorMessage(jsonStr),
        'User already registered in the system.',
      );
    });

    test('cleans Exception: prefix from plain string', () {
      const exStr = 'Exception: Network connection timeout';
      expect(
        StaffRemoteDatasourceImpl.extractErrorMessage(exStr),
        'Network connection timeout',
      );
    });

    test('uses fallback when details is null or empty', () {
      expect(
        StaffRemoteDatasourceImpl.extractErrorMessage(
          null,
          'Custom fallback failure',
        ),
        'Custom fallback failure',
      );
    });
  });

  group('StaffBloc Error Handling Tests', () {
    late FakeStaffRepository fakeRepo;
    late StaffBloc staffBloc;

    setUp(() {
      fakeRepo = FakeStaffRepository();
      staffBloc = StaffBloc(fakeRepo);
    });

    tearDown(() {
      staffBloc.close();
    });

    final testStaff = UserModel(
      id: 'staff-1',
      name: 'John Doe',
      email: 'john@example.com',
      phone: '1234567890',
      userId: 'john@example.com',
      password: 'password123',
      role: 'Staff',
      ownerId: 'owner-1',
    );

    test(
      'emits StaffError with clean message without Exception prefix on CreateStaffEvent failure',
      () async {
        fakeRepo.createStaffError = Exception(
          'A user with this email address already exists.',
        );

        expectLater(
          staffBloc.stream,
          emitsInOrder([
            isA<StaffError>().having(
              (e) => e.message,
              'message',
              'A user with this email address already exists.',
            ),
          ]),
        );

        staffBloc.add(CreateStaffEvent(testStaff, 'owner-1', ['biz-1']));
      },
    );

    test(
      'preserves StaffLoaded state after emitting StaffError on CreateStaffEvent failure',
      () async {
        fakeRepo.staffList = [testStaff];
        fakeRepo.createStaffError = Exception(
          'A user with this email address already exists.',
        );

        // First fetch to reach StaffLoaded
        staffBloc.add(FetchStaffEvent('owner-1'));
        await expectLater(
          staffBloc.stream,
          emitsInOrder([
            isA<StaffLoading>(),
            isA<StaffLoaded>(),
          ]),
        );

        // Now create staff fails - should emit StaffError then restore StaffLoaded
        staffBloc.add(CreateStaffEvent(testStaff, 'owner-1', ['biz-1']));
        await expectLater(
          staffBloc.stream,
          emitsInOrder([
            isA<StaffError>().having(
              (e) => e.message,
              'message',
              'A user with this email address already exists.',
            ),
            isA<StaffLoaded>(),
          ]),
        );
      },
    );
  });
}

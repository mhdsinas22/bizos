import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:bizos/features/products_services/presentation/bloc/product_service_bloc.dart';
import 'package:bizos/features/invoice_settings/presentation/bloc/invoice_settings_bloc.dart';
import 'package:bizos/features/invoices/presentation/bloc/invoice_bloc.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_entity.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_item_entity.dart';
import 'package:bizos/features/invoices/presentation/screens/invoice_create_edit_screen.dart';

class FakeCustomerBloc extends Fake implements CustomerBloc {
  final CustomerState _state;
  FakeCustomerBloc([CustomerState? state]) : _state = state ?? CustomerInitial();

  @override
  CustomerState get state => _state;

  @override
  Stream<CustomerState> get stream => Stream.value(_state);

  @override
  void add(CustomerEvent event) {}

  @override
  Future<void> close() async {}
}

class FakeProductServiceBloc extends Fake implements ProductServiceBloc {
  final ProductServiceState _state;
  FakeProductServiceBloc([ProductServiceState? state])
      : _state = state ?? ProductServiceInitial();

  @override
  ProductServiceState get state => _state;

  @override
  Stream<ProductServiceState> get stream => Stream.value(_state);

  @override
  void add(ProductServiceEvent event) {}

  @override
  Future<void> close() async {}
}

class FakeInvoiceSettingsBloc extends Fake implements InvoiceSettingsBloc {
  final InvoiceSettingsState _state;
  FakeInvoiceSettingsBloc([InvoiceSettingsState? state])
      : _state = state ?? InvoiceSettingsInitial();

  @override
  InvoiceSettingsState get state => _state;

  @override
  Stream<InvoiceSettingsState> get stream => Stream.value(_state);

  @override
  void add(InvoiceSettingsEvent event) {}

  @override
  Future<void> close() async {}
}

class FakeInvoiceBloc extends Fake implements InvoiceBloc {
  final InvoiceState _state;
  FakeInvoiceBloc([InvoiceState? state]) : _state = state ?? InvoiceInitial();

  @override
  InvoiceState get state => _state;

  @override
  Stream<InvoiceState> get stream => Stream.value(_state);

  @override
  void add(InvoiceEvent event) {}

  @override
  Future<void> close() async {}
}

Widget createTestApp({
  required Size screenSize,
  CustomerState? customerState,
  ProductServiceState? productServiceState,
  InvoiceSettingsState? invoiceSettingsState,
  InvoiceState? invoiceState,
  InvoiceEntity? invoice,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: screenSize),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CustomerBloc>.value(
            value: FakeCustomerBloc(customerState),
          ),
          BlocProvider<ProductServiceBloc>.value(
            value: FakeProductServiceBloc(productServiceState),
          ),
          BlocProvider<InvoiceSettingsBloc>.value(
            value: FakeInvoiceSettingsBloc(invoiceSettingsState),
          ),
          BlocProvider<InvoiceBloc>.value(
            value: FakeInvoiceBloc(invoiceState),
          ),
        ],
        child: InvoiceCreateEditScreen(
          businessId: 'test-biz-id',
          invoice: invoice,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('InvoiceCreateEditScreen renders with NO overflow on 320px narrow screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestApp(screenSize: const Size(320, 568)),
    );
    await tester.pumpAndSettle();

    expect(find.text('1. Customer & Metadata'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('2. Products & Services'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);
    expect(find.text('3. Summary & Payment Terms'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('InvoiceCreateEditScreen renders with NO overflow on 390px iPhone screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestApp(screenSize: const Size(390, 844)),
    );
    await tester.pumpAndSettle();

    expect(find.text('1. Customer & Metadata'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('2. Products & Services'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);
    expect(find.text('3. Summary & Payment Terms'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('InvoiceCreateEditScreen renders populated invoice with items on narrow 320px screen without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testInvoice = InvoiceEntity(
      id: 'inv-123',
      businessId: 'test-biz-id',
      customerId: 'cust-1',
      customerNameSnapshot: 'Rajesh Enterprise Pvt Ltd International Holdings',
      customerPhoneSnapshot: '+91 9876543210',
      invoiceNumber: 'INV-2026-9999',
      invoiceDate: DateTime(2026, 10, 24),
      dueDate: DateTime(2026, 11, 8),
      status: 'sent',
      paymentStatus: 'unpaid',
      subtotal: 154000.0,
      discountType: 'percentage',
      discountAmount: 10.0,
      taxAmount: 24700.0,
      grandTotal: 163300.0,
      paidAmount: 50000.0,
      balanceAmount: 113300.0,
      notes: 'Payment due upon receipt',
      paymentInstructions: 'UPI / NEFT to HDFC Bank',
      items: [
        const InvoiceItemEntity(
          id: 'item-1',
          invoiceId: 'inv-123',
          productServiceId: 'prod-1',
          itemName: 'Premium Cloud Enterprise Infrastructure Setup & Migration Service',
          description: 'Includes setup, DNS configuration, and automated backups',
          quantity: 2,
          unit: 'units',
          unitPrice: 50000.0,
          taxRate: 18.0,
          taxAmount: 18000.0,
          lineTotal: 118000.0,
        ),
        const InvoiceItemEntity(
          id: 'item-2',
          invoiceId: 'inv-123',
          productServiceId: 'prod-2',
          itemName: 'Monthly Maintenance Support',
          quantity: 3,
          unit: 'hrs',
          unitPrice: 18000.0,
          taxRate: 18.0,
          taxAmount: 9720.0,
          lineTotal: 63720.0,
        ),
      ],
      createdAt: DateTime(2026, 10, 20),
      updatedAt: DateTime(2026, 10, 24),
    );

    await tester.pumpWidget(
      createTestApp(
        screenSize: const Size(320, 600),
        invoice: testInvoice,
      ),
    );
    await tester.pumpAndSettle();

    // Verify items and populated state render with zero overflow
    expect(find.text('Edit Invoice'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.textContaining('Premium Cloud Enterprise'), findsOneWidget);
    expect(find.textContaining('Monthly Maintenance Support'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}

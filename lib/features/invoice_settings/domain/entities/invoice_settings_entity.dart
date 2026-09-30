import 'package:equatable/equatable.dart';

class InvoiceSettingsEntity extends Equatable {
  final String id;
  final String businessId;
  final String businessName;
  final String businessPhone;
  final String businessEmail;
  final String businessAddress;
  final String gstin;
  final String logoUrl;
  final String template; // 'modern', 'classic', 'minimal', 'professional'
  final String primaryColor; // e.g. '#2563EB'
  final String invoicePrefix; // e.g. 'INV-'
  final bool showLogo;
  final bool showTax;
  final String footerText;
  final String paymentInstructions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceSettingsEntity({
    required this.id,
    required this.businessId,
    this.businessName = '',
    this.businessPhone = '',
    this.businessEmail = '',
    this.businessAddress = '',
    this.gstin = '',
    this.logoUrl = '',
    this.template = 'modern',
    this.primaryColor = '#2563EB',
    this.invoicePrefix = 'INV-',
    this.showLogo = true,
    this.showTax = true,
    this.footerText = 'Thank you for your business!',
    this.paymentInstructions = 'Payment via Cash, UPI, or Direct Bank Transfer.',
    required this.createdAt,
    required this.updatedAt,
  });

  InvoiceSettingsEntity copyWith({
    String? id,
    String? businessId,
    String? businessName,
    String? businessPhone,
    String? businessEmail,
    String? businessAddress,
    String? gstin,
    String? logoUrl,
    String? template,
    String? primaryColor,
    String? invoicePrefix,
    bool? showLogo,
    bool? showTax,
    String? footerText,
    String? paymentInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceSettingsEntity(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      businessAddress: businessAddress ?? this.businessAddress,
      gstin: gstin ?? this.gstin,
      logoUrl: logoUrl ?? this.logoUrl,
      template: template ?? this.template,
      primaryColor: primaryColor ?? this.primaryColor,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      showLogo: showLogo ?? this.showLogo,
      showTax: showTax ?? this.showTax,
      footerText: footerText ?? this.footerText,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessId,
        businessName,
        businessPhone,
        businessEmail,
        businessAddress,
        gstin,
        logoUrl,
        template,
        primaryColor,
        invoicePrefix,
        showLogo,
        showTax,
        footerText,
        paymentInstructions,
        createdAt,
        updatedAt,
      ];
}


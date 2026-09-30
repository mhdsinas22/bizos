import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bizos/features/invoice_settings/domain/entities/invoice_settings_entity.dart';

class InvoiceSettingsModel extends InvoiceSettingsEntity {
  const InvoiceSettingsModel({
    required super.id,
    required super.businessId,
    super.businessName = '',
    super.businessPhone = '',
    super.businessEmail = '',
    super.businessAddress = '',
    super.gstin = '',
    super.logoUrl = '',
    super.template = 'modern',
    super.primaryColor = '#2563EB',
    super.invoicePrefix = 'INV-',
    super.showLogo = true,
    super.showTax = true,
    super.footerText = 'Thank you for your business!',
    super.paymentInstructions = 'Payment via Cash, UPI, or Direct Bank Transfer.',
    required super.createdAt,
    required super.updatedAt,
  });

  static String _resolveLogoUrl(String url) {
    if (url.trim().isEmpty) return '';
    if (url.contains('invoice_business_logos')) {
      url = url.replaceAll('invoice_business_logos', 'invoice_business_logs');
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return Supabase.instance.client.storage
        .from('invoice_business_logs')
        .getPublicUrl(url);
  }

  factory InvoiceSettingsModel.fromJson(Map<String, dynamic> json) {
    return InvoiceSettingsModel(
      id: json['id'] as String? ?? '',
      businessId: json['business_id'] as String? ?? '',
      businessName: json['business_name'] as String? ?? '',
      businessPhone: json['business_phone'] as String? ?? '',
      businessEmail: json['business_email'] as String? ?? '',
      businessAddress: json['business_address'] as String? ?? '',
      gstin: json['gstin'] as String? ?? '',
      logoUrl: _resolveLogoUrl(json['logo_url'] as String? ?? ''),
      template: json['template'] as String? ?? 'modern',
      primaryColor: json['primary_color'] as String? ?? '#2563EB',
      invoicePrefix: json['invoice_prefix'] as String? ?? 'INV-',
      showLogo: json['show_logo'] as bool? ?? true,
      showTax: json['show_tax'] as bool? ?? true,
      footerText: json['footer_text'] as String? ?? 'Thank you for your business!',
      paymentInstructions: json['payment_instructions'] as String? ??
          'Payment via Cash, UPI, or Direct Bank Transfer.',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'business_id': businessId,
      'business_name': businessName,
      'business_phone': businessPhone,
      'business_email': businessEmail,
      'business_address': businessAddress,
      'gstin': gstin,
      'logo_url': logoUrl,
      'template': template,
      'primary_color': primaryColor,
      'invoice_prefix': invoicePrefix,
      'show_logo': showLogo,
      'show_tax': showTax,
      'footer_text': footerText,
      'payment_instructions': paymentInstructions,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id.trim().isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  @override
  InvoiceSettingsModel copyWith({
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
    return InvoiceSettingsModel(
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

  factory InvoiceSettingsModel.fromEntity(InvoiceSettingsEntity entity) {
    return InvoiceSettingsModel(
      id: entity.id,
      businessId: entity.businessId,
      businessName: entity.businessName,
      businessPhone: entity.businessPhone,
      businessEmail: entity.businessEmail,
      businessAddress: entity.businessAddress,
      gstin: entity.gstin,
      logoUrl: entity.logoUrl,
      template: entity.template,
      primaryColor: entity.primaryColor,
      invoicePrefix: entity.invoicePrefix,
      showLogo: entity.showLogo,
      showTax: entity.showTax,
      footerText: entity.footerText,
      paymentInstructions: entity.paymentInstructions,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

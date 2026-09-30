import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/skeleton_loader.dart';
import 'package:bizos/core/widgets/error_state.dart';
import 'package:bizos/features/invoice_settings/domain/entities/invoice_settings_entity.dart';
import 'package:bizos/features/invoice_settings/presentation/bloc/invoice_settings_bloc.dart';
import 'package:bizos/features/invoice_settings/presentation/widgets/brand_color_picker_widget.dart';
import 'package:bizos/features/invoice_settings/presentation/widgets/business_logo_upload_widget.dart';
import 'package:bizos/features/invoice_settings/presentation/widgets/invoice_live_preview_widget.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  final String businessId;

  const InvoiceSettingsScreen({super.key, required this.businessId});

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _gstinController;
  late TextEditingController _prefixController;
  late TextEditingController _footerController;
  late TextEditingController _paymentInstructionsController;

  String _selectedTemplate = 'modern';
  String _selectedColor = '#2563EB';
  String _logoUrl = '';
  bool _showLogo = true;
  bool _showTax = true;

  final List<Map<String, String>> _templates = const [
    {'id': 'modern', 'name': 'Modern', 'desc': 'Vibrant header banner with accent summary'},
    {'id': 'classic', 'name': 'Classic', 'desc': 'Traditional centered header with elegant borders'},
    {'id': 'minimal', 'name': 'Minimal', 'desc': 'Clean, frameless design focusing on typography'},
    {'id': 'professional', 'name': 'Professional', 'desc': 'Executive layout with structured metadata'},
  ];

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _gstinController = TextEditingController();
    _prefixController = TextEditingController(text: 'INV-');
    _footerController = TextEditingController();
    _paymentInstructionsController = TextEditingController();

    context.read<InvoiceSettingsBloc>().add(FetchInvoiceSettingsEvent(widget.businessId));
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _prefixController.dispose();
    _footerController.dispose();
    _paymentInstructionsController.dispose();
    super.dispose();
  }

  void _populateFields(InvoiceSettingsEntity settings) {
    _businessNameController.text = settings.businessName;
    _phoneController.text = settings.businessPhone;
    _emailController.text = settings.businessEmail;
    _addressController.text = settings.businessAddress;
    _gstinController.text = settings.gstin;
    _prefixController.text = settings.invoicePrefix.isNotEmpty ? settings.invoicePrefix : 'INV-';
    _footerController.text = settings.footerText;
    _paymentInstructionsController.text = settings.paymentInstructions;
    _selectedTemplate = settings.template;
    _selectedColor = settings.primaryColor.isNotEmpty ? settings.primaryColor : '#2563EB';
    _logoUrl = settings.logoUrl;
    _showLogo = settings.showLogo;
    _showTax = settings.showTax;
  }

  InvoiceSettingsEntity _getCurrentFormEntity(String id) {
    return InvoiceSettingsEntity(
      id: id,
      businessId: widget.businessId,
      businessName: _businessNameController.text.trim(),
      businessPhone: _phoneController.text.trim(),
      businessEmail: _emailController.text.trim(),
      businessAddress: _addressController.text.trim(),
      gstin: _gstinController.text.trim(),
      logoUrl: _logoUrl.trim(),
      template: _selectedTemplate,
      primaryColor: _selectedColor,
      invoicePrefix: _prefixController.text.trim().isNotEmpty
          ? _prefixController.text.trim()
          : 'INV-',
      showLogo: _showLogo,
      showTax: _showTax,
      footerText: _footerController.text.trim(),
      paymentInstructions: _paymentInstructionsController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _saveSettings(String existingId) {
    if (!_formKey.currentState!.validate()) return;
    final entity = _getCurrentFormEntity(existingId);
    context.read<InvoiceSettingsBloc>().add(SaveInvoiceSettingsEvent(entity));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Branding & Customization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Reload Settings',
            onPressed: () => context
                .read<InvoiceSettingsBloc>()
                .add(FetchInvoiceSettingsEvent(widget.businessId)),
          ),
        ],
      ),
      body: BlocConsumer<InvoiceSettingsBloc, InvoiceSettingsState>(
        listener: (context, state) {
          if (state is InvoiceSettingsSavedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invoice Branding saved successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is InvoiceSettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is InvoiceSettingsLoading && state is! InvoiceSettingsLoaded) {
            return const SkeletonListLoader(itemCount: 4, itemHeight: 120);
          } else if (state is InvoiceSettingsError && state is! InvoiceSettingsLoaded) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context
                  .read<InvoiceSettingsBloc>()
                  .add(FetchInvoiceSettingsEvent(widget.businessId)),
            );
          }

          InvoiceSettingsEntity? settings;
          if (state is InvoiceSettingsLoaded) {
            settings = state.settings;
          } else if (state is InvoiceSettingsSavedSuccess) {
            settings = state.settings;
          } else if (state is LogoUploadingState) {
            settings = state.currentSettings;
          } else if (state is LogoUploadedSuccessState) {
            settings = state.settings;
          }

          settings ??= InvoiceSettingsEntity(
            id: '',
            businessId: widget.businessId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          if (_businessNameController.text.isEmpty && settings.businessName.isNotEmpty) {
            _populateFields(settings);
          }

          final currentEntity = _getCurrentFormEntity(settings.id);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final formContent = _buildForm(context, settings!.id, isDark, currentEntity);
              final previewContent = InvoiceLivePreviewWidget(settings: currentEntity);

              if (isWide) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(child: formContent),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Live Invoice Preview',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              previewContent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExpansionTile(
                        initiallyExpanded: true,
                        leading: const Icon(Icons.remove_red_eye_outlined),
                        title: const Text(
                          'Live Invoice Preview',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Tap to toggle live preview card'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: previewContent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      formContent,
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    String settingsId,
    bool isDark,
    InvoiceSettingsEntity currentEntity,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Invoice Appearance
          _buildSectionHeader('1. Invoice Appearance', Icons.palette_outlined),
          const SizedBox(height: 10),

          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Invoice Template',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _templates.map((tpl) {
                    final selected = _selectedTemplate == tpl['id'];
                    return ChoiceChip(
                      label: Text(tpl['name']!),
                      avatar: selected ? const Icon(Icons.check, size: 16) : null,
                      selected: selected,
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedTemplate = tpl['id']!;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Brand Color',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),

                BrandColorPickerWidget(
                  currentColorHex: _selectedColor,
                  onColorChanged: (hex) {
                    setState(() {
                      _selectedColor = hex;
                    });
                  },
                ),
                const SizedBox(height: 24),

                BusinessLogoUploadWidget(
                  businessId: widget.businessId,
                  currentSettings: currentEntity,
                  onLogoUrlChanged: (url) {
                    setState(() {
                      _logoUrl = url;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Business Information
          _buildSectionHeader('2. Business Header Information', Icons.storefront_outlined),
          const SizedBox(height: 10),

          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _businessNameController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Business Name *',
                    hintText: 'e.g. Acme Services Pvt Ltd',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter business name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _addressController,
                  onChanged: (_) => setState(() {}),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Business Address',
                    hintText: 'Street address, city, state, pincode',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _gstinController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'GSTIN / Tax Identification Number',
                    hintText: 'e.g. 29ABCDE1234F1Z5',
                    prefixIcon: const Icon(Icons.receipt_long),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Invoice Configuration
          _buildSectionHeader('3. Invoice Options & Format', Icons.settings_outlined),
          const SizedBox(height: 10),

          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _prefixController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Invoice Number Prefix',
                    hintText: 'INV-',
                    prefixIcon: const Icon(Icons.tag),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                SwitchListTile(
                  title: const Text('Show Business Logo on Invoice'),
                  subtitle: const Text('Displays your uploaded logo in the header'),
                  value: _showLogo,
                  activeTrackColor: AppTheme.primaryColor,
                  onChanged: (val) => setState(() => _showLogo = val),
                ),

                SwitchListTile(
                  title: const Text('Show Tax Column & Breakdown'),
                  subtitle: const Text('Includes tax rates and GST details on items'),
                  value: _showTax,
                  activeTrackColor: AppTheme.primaryColor,
                  onChanged: (val) => setState(() => _showTax = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 4: Terms & Footer
          _buildSectionHeader('4. Payment Terms & Footer', Icons.article_outlined),
          const SizedBox(height: 10),

          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _paymentInstructionsController,
                  onChanged: (_) => setState(() {}),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Payment Instructions & Bank Details',
                    hintText: 'UPI ID: example@upi\nBank: HDFC Bank | A/C: 1234567890 | IFSC: HDFC0001234',
                    prefixIcon: const Icon(Icons.account_balance),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _footerController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Invoice Footer Text',
                    hintText: 'Thank you for your business!',
                    prefixIcon: const Icon(Icons.short_text),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _saveSettings(settingsId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text(
                'Save Invoice Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

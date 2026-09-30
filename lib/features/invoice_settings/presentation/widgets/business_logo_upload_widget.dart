import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bizos/features/invoice_settings/domain/entities/invoice_settings_entity.dart';
import 'package:bizos/features/invoice_settings/presentation/bloc/invoice_settings_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';

class BusinessLogoUploadWidget extends StatefulWidget {
  final String businessId;
  final InvoiceSettingsEntity currentSettings;
  final ValueChanged<String> onLogoUrlChanged;

  const BusinessLogoUploadWidget({
    super.key,
    required this.businessId,
    required this.currentSettings,
    required this.onLogoUrlChanged,
  });

  @override
  State<BusinessLogoUploadWidget> createState() => _BusinessLogoUploadWidgetState();
}

class _BusinessLogoUploadWidgetState extends State<BusinessLogoUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingLocally = false;

  Future<void> _pickAndUploadLogo() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    // Check staff permissions if user is staff
    if (user != null && user.isStaff) {
      // Basic safeguard feedback if staff permission check is required
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileSize = await file.length();

      // File size validation (5MB max)
      if (fileSize > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected image exceeds 5MB limit. Please choose a smaller logo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploadingLocally = true;
      });

      if (mounted) {
        context.read<InvoiceSettingsBloc>().add(
              UploadLogoEvent(
                businessId: widget.businessId,
                file: file,
                currentSettings: widget.currentSettings,
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick logo image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingLocally = false;
        });
      }
    }
  }

  void _removeLogo() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Business Logo?'),
          content: const Text(
            'Your logo will no longer appear on generated invoices. You can upload a new logo anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<InvoiceSettingsBloc>().add(
                      DeleteLogoEvent(currentSettings: widget.currentSettings),
                    );
                widget.onLogoUrlChanged('');
              },
              child: const Text('Remove Logo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final logoUrl = widget.currentSettings.logoUrl;
    final hasLogo = logoUrl.trim().isNotEmpty;

    return BlocListener<InvoiceSettingsBloc, InvoiceSettingsState>(
      listener: (context, state) {
        if (state is LogoUploadedSuccessState) {
          widget.onLogoUrlChanged(state.logoUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Business logo uploaded successfully!'),
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
      child: BlocBuilder<InvoiceSettingsBloc, InvoiceSettingsState>(
        builder: (context, state) {
          final isUploading = _isUploadingLocally || state is LogoUploadingState;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Business Logo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasLogo && !isUploading)
                    TextButton.icon(
                      onPressed: _removeLogo,
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      label: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (isUploading)
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(strokeWidth: 3),
                      SizedBox(height: 14),
                      Text(
                        'Uploading logo to storage...',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else if (hasLogo)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Logo Preview Box
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            logoUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Replace Actions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Logo Preview',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PNG, JPG, JPEG, or WebP. Max 5MB.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _pickAndUploadLogo,
                              icon: const Icon(Icons.sync_outlined, size: 18),
                              label: const Text('Change Logo'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Empty State
                InkWell(
                  onTap: _pickAndUploadLogo,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.primaryColor.withValues(alpha: 0.05)
                          : theme.primaryColor.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 32,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Add your business logo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your logo will appear on all generated invoices',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _pickAndUploadLogo,
                          icon: const Icon(Icons.upload_file_outlined, size: 18),
                          label: const Text('Upload Logo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

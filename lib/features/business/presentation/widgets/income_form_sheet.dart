import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/responsive_breakpoints.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:bizos/features/attachments/domain/repositories/attachment_repository.dart';
import 'package:bizos/features/attachments/domain/usecases/delete_attachment_usecase.dart';
import 'package:bizos/features/attachments/domain/usecases/get_attachments_usecase.dart';
import 'package:bizos/features/attachments/domain/usecases/upload_attachment_usecase.dart';
import 'package:bizos/features/attachments/presentation/bloc/attachment_cubit.dart';
import 'package:bizos/features/attachments/presentation/bloc/attachment_state.dart';
import 'package:bizos/features/attachments/presentation/widgets/attachment_grid.dart';
import 'package:bizos/features/attachments/presentation/widgets/attachment_picker.dart';
import 'package:bizos/features/attachments/presentation/widgets/attachment_preview.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/domain/entities/category_entity.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_event.dart';
import 'package:bizos/features/finance/presentation/widgets/category_dropdown_field.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_dropdown_field.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_helper.dart';

class IncomeFormSheet extends StatefulWidget {
  final String businessId;
  final IncomeModel? income;
  final UserModel user;
  final VoidCallback onSave;

  const IncomeFormSheet({
    super.key,
    required this.businessId,
    this.income,
    required this.user,
    required this.onSave,
  });

  @override
  State<IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends State<IncomeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();
  String _paymentMethod = PaymentMethodHelper.defaultMethod;
  DateTime _date = DateTime.now();

  File? _pickedFile;
  String? _pickedFileName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.income != null) {
      _amountController.text = widget.income!.amount.toString();
      _categoryController.text = widget.income!.category;
      _descController.text = widget.income!.description;
      _paymentMethod = PaymentMethodHelper.sanitize(widget.income!.paymentMethod);
      _date = widget.income!.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final isEditing = widget.income != null;
        final amt = double.parse(_amountController.text.trim());
        final incomeId = isEditing ? widget.income!.id : const Uuid().v4();

        final inc = IncomeModel(
          id: incomeId,
          businessId: widget.businessId,
          amount: amt,
          category: _categoryController.text.trim(),
          paymentMethod: PaymentMethodHelper.sanitize(_paymentMethod),
          description: _descController.text.trim(),
          date: _date,
          createdByUserId: isEditing
              ? widget.income!.createdByUserId
              : widget.user.id,
          createdByName: isEditing
              ? widget.income!.createdByName
              : widget.user.name,
        );

        if (isEditing) {
          context.read<FinanceBloc>().add(UpdateIncomeEvent(inc));
        } else {
          context.read<FinanceBloc>().add(AddIncomeEvent(inc));
        }

        // Upload attachment if user picked a new file
        if (_pickedFile != null && _pickedFileName != null) {
          final attachmentRepo = context.read<AttachmentRepository>();
          final uploadUseCase = UploadAttachmentUseCase(attachmentRepo);

          try {
            await uploadUseCase(
              businessId: widget.businessId,
              entityType: 'income',
              entityId: incomeId,
              file: _pickedFile!,
              fileName: _pickedFileName!,
              userId: widget.user.id,
            );
          } catch (uploadError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Income saved, but receipt upload failed: $uploadError'),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          }
        }

        widget.onSave();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving income record: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.income != null;
    final attachmentRepo = context.read<AttachmentRepository>();

    return BlocProvider(
      create: (context) {
        final cubit = AttachmentCubit(
          uploadAttachmentUseCase: UploadAttachmentUseCase(attachmentRepo),
          getAttachmentsUseCase: GetAttachmentsUseCase(attachmentRepo),
          deleteAttachmentUseCase: DeleteAttachmentUseCase(attachmentRepo),
        );
        if (isEditing) {
          cubit.loadAttachments(
            entityType: 'income',
            entityId: widget.income!.id,
          );
        }
        return cubit;
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: ResponsiveCenterBody(
            maxWidth: ResponsiveBreakpoints.maxFormWidth,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Income Record' : 'Record Inward Payment',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _amountController,
                    label: 'Inward Amount',
                    hint: '0.00',
                    prefixIcon: Icons.monetization_on_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(val.trim()) == null) {
                        return 'Please enter a valid numeric value';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CategoryDropdownField(
                    businessId: widget.businessId,
                    userId: widget.user.id,
                    type: CategoryType.income,
                    initialValue: _categoryController.text.isNotEmpty
                        ? _categoryController.text
                        : null,
                    onChanged: (val) {
                      _categoryController.text = val;
                    },
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please specify category'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  PaymentMethodDropdownField(
                    initialValue: _paymentMethod,
                    onChanged: (val) {
                      setState(() {
                        _paymentMethod = val;
                      });
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Payment Method is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _descController,
                    label: 'Description',
                    hint: 'Detailed notes on the invoice or payment source...',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_today,
                      color: AppTheme.success,
                    ),
                    title: const Text(
                      'Transaction Date',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(DateFormat.yMMMd().format(_date)),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 3650),
                          ),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _date = picked;
                          });
                        }
                      },
                      child: const Text('Change Date'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Existing attachments list if editing
                  if (isEditing)
                    BlocBuilder<AttachmentCubit, AttachmentState>(
                      builder: (context, state) {
                        if (state is AttachmentLoaded && state.attachments.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: AttachmentGrid(
                              attachments: state.attachments,
                              isEditable: true,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                  // Attach Receipt Section
                  const Text(
                    'Receipt Attachment',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (_pickedFile != null && _pickedFileName != null)
                    AttachmentPreview(
                      file: _pickedFile!,
                      fileName: _pickedFileName!,
                      onRemove: () {
                        setState(() {
                          _pickedFile = null;
                          _pickedFileName = null;
                        });
                      },
                      onReplace: (newFile, newFileName) {
                        setState(() {
                          _pickedFile = newFile;
                          _pickedFileName = newFileName;
                        });
                      },
                    )
                  else
                    AttachmentPicker(
                      onImagePicked: (file, fileName) {
                        setState(() {
                          _pickedFile = file;
                          _pickedFileName = fileName;
                        });
                      },
                    ),

                  const SizedBox(height: 24),
                  CustomButton(
                    text: _isSaving
                        ? 'Saving...'
                        : (isEditing ? 'Save Changes' : 'Record Inflow'),
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

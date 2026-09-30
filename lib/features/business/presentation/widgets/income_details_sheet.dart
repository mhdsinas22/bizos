import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/utils/responsive_breakpoints.dart';
import 'package:bizos/core/widgets/responsive_layout.dart';
import 'package:bizos/features/attachments/domain/repositories/attachment_repository.dart';
import 'package:bizos/features/attachments/domain/usecases/delete_attachment_usecase.dart';
import 'package:bizos/features/attachments/domain/usecases/get_attachments_usecase.dart';
import 'package:bizos/features/attachments/domain/usecases/upload_attachment_usecase.dart';
import 'package:bizos/features/attachments/presentation/bloc/attachment_cubit.dart';
import 'package:bizos/features/attachments/presentation/bloc/attachment_state.dart';
import 'package:bizos/features/attachments/presentation/widgets/attachment_grid.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_helper.dart';

class IncomeDetailsSheet extends StatelessWidget {
  final IncomeModel income;

  const IncomeDetailsSheet({super.key, required this.income});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<AttachmentRepository>();
    final methodIcon = PaymentMethodHelper.getIcon(income.paymentMethod);

    return BlocProvider(
      create: (context) => AttachmentCubit(
        uploadAttachmentUseCase: UploadAttachmentUseCase(repo),
        getAttachmentsUseCase: GetAttachmentsUseCase(repo),
        deleteAttachmentUseCase: DeleteAttachmentUseCase(repo),
      )..loadAttachments(entityType: 'income', entityId: income.id),
      child: Builder(
        builder: (context) {
          return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Income Details',
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
                    // Amount banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Inward Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(income.amount),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('Category'),
                      subtitle: Text(income.category),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(methodIcon),
                      title: const Text('Payment Method'),
                      subtitle: Text(income.paymentMethod),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Description'),
                      subtitle: Text(
                        income.description.isNotEmpty
                            ? income.description
                            : 'No description provided',
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Transaction Date'),
                      subtitle: Text(DateFormat.yMMMMd().format(income.date)),
                    ),
                    if (income.createdByName != null &&
                        income.createdByName!.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Recorded By'),
                        subtitle: Text(income.createdByName!),
                      ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    // Attachments Section
                    BlocConsumer<AttachmentCubit, AttachmentState>(
                      listener: (context, state) {
                        if (state is AttachmentError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is AttachmentLoading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (state is AttachmentLoaded) {
                          if (state.attachments.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                'No receipt or attachments linked to this income record.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }
                          return AttachmentGrid(
                            attachments: state.attachments,
                            isEditable: true,
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

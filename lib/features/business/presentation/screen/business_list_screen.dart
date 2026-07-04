import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/business/bloc/business_event.dart';
import 'package:bizos/features/business/bloc/business_state.dart';
import 'package:bizos/features/business/presentation/widgets/business_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/business/presentation/screen/business_detail_screen.dart';

class BusinessListScreen extends StatefulWidget {
  const BusinessListScreen({super.key});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<BusinessBloc>().add(
        FetchBusinessesEvent(authState.user.userId),
      );
    }
  }

  void _showBusinessForm({BusinessModel? business}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BusinessFormSheet(
        business: business,
        onSave: () {
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            context.read<BusinessBloc>().add(
              FetchBusinessesEvent(authState.user.userId),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(BusinessModel business) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Business?'),
        content: Text(
          'Are you sure you want to permanently delete "${business.name}"? This will also delete all associated tasks, income, and expenses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                context.read<BusinessBloc>().add(
                  DeleteBusinessEvent(business.id, authState.user.userId),
                );
              }
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;

    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final isOwner = user?.isOwner ?? false;

    return Scaffold(
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _showBusinessForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Business'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: BlocBuilder<BusinessBloc, BusinessState>(
        builder: (context, state) {
          if (state is BusinessLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BusinessError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is BusinessLoaded) {
            final list = state.businesses;
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.storefront,
                title: 'No Businesses Yet',
                message: isOwner
                    ? 'Start by creating your first business to manage operations.'
                    : 'Contact your owner administrator to configure businesses.',
                actionLabel: isOwner ? 'Create Business' : null,
                onActionPressed: isOwner ? () => _showBusinessForm() : null,
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: list.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 3 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 180,
              ),
              itemBuilder: (context, index) {
                final biz = list[index];

                return Hero(
                  tag: 'biz-${biz.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: GlassCard(
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => BusinessDetailScreen(
                                  business: biz,
                                  bussinessids: biz.id,
                                ),
                              ),
                            )
                            .then((_) {
                              // Trigger reload after coming back in case values changed
                              if (user != null) {
                                context.read<BusinessBloc>().add(
                                  FetchBusinessesEvent(user.userId),
                                );
                              }
                            });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  biz.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isOwner)
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          _showBusinessForm(business: biz),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppTheme.error,
                                      ),
                                      onPressed: () => _confirmDelete(biz),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              biz.type,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Text(
                              biz.notes.isNotEmpty
                                  ? biz.notes
                                  : 'No extra notes provided.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Divider(),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                biz.phone,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  biz.address,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ----------------- SHEET FORM -----------------

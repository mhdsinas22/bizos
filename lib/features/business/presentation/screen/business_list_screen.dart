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
import 'package:bizos/core/widgets/error_state.dart';
import 'package:bizos/core/widgets/skeleton_loader.dart';
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
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: SkeletonListLoader(itemCount: 4, itemHeight: 140),
            );
          }

          if (state is BusinessError) {
            return ErrorStateWidget(
              title: 'Unable to Load Businesses',
              message: state.message,
              onRetry: () {
                if (user != null) {
                  context.read<BusinessBloc>().add(
                    FetchBusinessesEvent(user.userId),
                  );
                }
              },
            );
          }

          if (state is BusinessLoaded) {
            final list = state.businesses;
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.storefront_rounded,
                title: 'No Businesses Registered',
                message: isOwner
                    ? 'Create your first business to manage operations and finances.'
                    : 'Your owner has not assigned any businesses yet.',
                actionLabel: isOwner ? 'Add Business' : null,
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
                mainAxisExtent: 170,
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
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isOwner)
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    size: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (val) {
                                    if (val == 'edit') _showBusinessForm(business: biz);
                                    if (val == 'delete') _confirmDelete(biz);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 16),
                                          SizedBox(width: 8),
                                          Text('Edit Business', style: TextStyle(fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.error),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: AppTheme.error, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              biz.type,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Text(
                              biz.notes.isNotEmpty
                                  ? biz.notes
                                  : 'No notes added for this business.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 12,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                biz.phone.isNotEmpty ? biz.phone : 'N/A',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  biz.address.isNotEmpty ? biz.address : 'N/A',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 11,
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

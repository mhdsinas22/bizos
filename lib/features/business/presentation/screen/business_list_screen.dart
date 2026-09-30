import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/business/bloc/business_event.dart';
import 'package:bizos/features/business/bloc/business_state.dart';
import 'package:bizos/features/business/presentation/widgets/business_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
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
      backgroundColor: Colors.transparent,
      floatingActionButton: isOwner
          ? Container(
              margin: const EdgeInsets.only(bottom: 16, right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                elevation: 0,
                hoverElevation: 0,
                focusElevation: 0,
                highlightElevation: 0,
                onPressed: () => _showBusinessForm(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Add Business',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : null,
      body: BlocBuilder<BusinessBloc, BusinessState>(
        builder: (context, state) {
          if (state is BusinessLoading) {
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: SkeletonListLoader(itemCount: 4, itemHeight: 160),
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

            return RefreshIndicator(
              color: AppTheme.primaryColor,
              backgroundColor: theme.cardColor,
              onRefresh: () async {
                if (user != null) {
                  context.read<BusinessBloc>().add(
                    FetchBusinessesEvent(user.userId),
                  );
                }
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: list.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        child: EmptyState(
                          icon: Icons.storefront_rounded,
                          title: 'No Businesses Registered',
                          message: isOwner
                              ? 'Create your first business to manage operations and finances.'
                              : 'Your owner has not assigned any businesses yet.',
                          actionLabel: isOwner ? 'Add Business' : null,
                          onActionPressed: isOwner
                              ? () => _showBusinessForm()
                              : null,
                        ),
                      ),
                    )
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Businesses',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Managing ${list.length} active ${list.length == 1 ? 'business' : 'businesses'}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          sliver: isTablet
                              ? SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        mainAxisExtent: 220,
                                      ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildBusinessCard(
                                      context,
                                      list[index],
                                      isOwner,
                                      index,
                                    ),
                                    childCount: list.length,
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: _buildBusinessCard(
                                        context,
                                        list[index],
                                        isOwner,
                                        index,
                                      ),
                                    );
                                  }, childCount: list.length),
                                ),
                        ),
                      ],
                    ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBusinessCard(
    BuildContext context,
    BusinessModel biz,
    bool isOwner,
    int index,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Hero(
        tag: 'biz-${biz.id}',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
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
                    if (!mounted) return;
                    final authState = context.read<AuthBloc>().state;
                    if (authState is Authenticated) {
                      context.read<BusinessBloc>().add(
                        FetchBusinessesEvent(authState.user.userId),
                      );
                    }
                  });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? theme.cardColor.withValues(alpha: 0.6)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black26
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            biz.name.isNotEmpty
                                ? biz.name[0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title & Chip
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              biz.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.08),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                biz.type,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Options Menu
                      if (isOwner)
                        SizedBox(
                          height: 32,
                          width: 32,
                          child: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              size: 20,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showBusinessForm(business: biz);
                              }
                              if (val == 'delete') {
                                _confirmDelete(biz);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 10),
                                    Text(
                                      'Edit',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppTheme.error,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: AppTheme.error,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  if (biz.notes.isNotEmpty)
                    Text(
                      biz.notes,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.black87,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'No notes added',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  // Divider
                  Divider(
                    height: 24,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),

                  // Compact Info Row
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppTheme.primaryColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        biz.phone.isNotEmpty ? biz.phone : 'N/A',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.primaryColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          biz.address.isNotEmpty ? biz.address : 'N/A',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }
}

// ----------------- SHEET FORM -----------------

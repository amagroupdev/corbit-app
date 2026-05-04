import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/support/data/models/ticket_model.dart';
import 'package:orbit_app/features/support/presentation/controllers/support_controller.dart';
import 'package:orbit_app/routing/route_names.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Lists support tickets owned by the authenticated user. A floating
/// action button opens [CreateTicketScreen]; pull-to-refresh re-fetches
/// the first page.
class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() =>
      _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supportListControllerProvider.notifier).load();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(supportListControllerProvider.notifier).refresh();
  }

  Future<void> _openCreate() async {
    await context.pushNamed(RouteNames.createSupportTicket);
    // Always refresh on return — success path may have created a row.
    if (mounted) {
      await ref.read(supportListControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final state = ref.watch(supportListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(t.translate('supportTicketsTitle')),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(t.translate('supportTicketCreate')),
      ),
      body: _buildBody(state, t),
    );
  }

  Widget _buildBody(SupportListState state, AppLocalizations t) {
    if (state.isLoading && state.items.isEmpty) {
      return AppLoading.listShimmer();
    }
    if (state.hasError && state.items.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(supportListControllerProvider.notifier).load(),
      );
    }
    if (state.isEmpty) {
      return AppEmptyState(
        icon: Icons.support_agent_outlined,
        title: t.translate('supportTicketEmpty'),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _TicketCard(ticket: state.items[i]),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final SupportTicketModel ticket;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (ticket.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(ticket.createdAt!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(ticket: ticket, t: t),
            ],
          ),
          if (ticket.message != null && ticket.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              ticket.message!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.ticket, required this.t});
  final SupportTicketModel ticket;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final String label;
    if (ticket.isClosed) {
      background = AppColors.surfaceVariant;
      foreground = AppColors.textSecondary;
      label = t.translate('supportTicketStatusClosed');
    } else {
      background = AppColors.primarySurface;
      foreground = AppColors.primary;
      label = t.translate('supportTicketStatusOpen');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/notification_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/services/notification_helper_service.dart';
import '../utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationHelperService _helperService = NotificationHelperService();

  // Map each notification type to an icon and color
  static IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentConfirmed:
        return Icons.event_available_rounded;
      case NotificationType.appointmentDeclined:
        return Icons.event_busy_rounded;
      case NotificationType.appointmentCompleted:
        return Icons.check_circle_rounded;
      case NotificationType.newNoteAdded:
        return Icons.note_add_rounded;
      case NotificationType.followUpScheduled:
        return Icons.repeat_rounded;
      case NotificationType.medicineReminder:
        return Icons.medication_rounded;
      case NotificationType.newHireRequest:
        return Icons.person_add_rounded;
      case NotificationType.newAppointmentRequest:
        return Icons.event_rounded;
      case NotificationType.patientMissedMedicine:
        return Icons.medication_liquid_rounded;
      case NotificationType.newVitalAdded:
        return Icons.monitor_heart_rounded;
      case NotificationType.emergencySOSTriggered:
        return Icons.sos_rounded;
    }
  }

  static Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentConfirmed:
        return AppColors.success;
      case NotificationType.appointmentDeclined:
        return AppColors.error;
      case NotificationType.appointmentCompleted:
        return AppColors.primary;
      case NotificationType.newNoteAdded:
        return AppColors.info;
      case NotificationType.followUpScheduled:
        return AppColors.secondary;
      case NotificationType.medicineReminder:
        return AppColors.primary;
      case NotificationType.newHireRequest:
        return AppColors.purple;
      case NotificationType.newAppointmentRequest:
        return AppColors.secondary;
      case NotificationType.patientMissedMedicine:
        return AppColors.warning;
      case NotificationType.newVitalAdded:
        return AppColors.info;
      case NotificationType.emergencySOSTriggered:
        return AppColors.error;
    }
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday, ${DateFormat('h:mm a').format(dt)}';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  Future<void> _markAllRead(String uid, List<NotificationModel> items) async {
    final hasUnread = items.any((n) => !n.isRead);
    if (!hasUnread) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications are already read',
              style: GoogleFonts.poppins()),
          backgroundColor: AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await _helperService.markAllAsRead(uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('All marked as read', style: GoogleFonts.poppins()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = context.read<AppAuthProvider>().uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Notifications',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: uid == null
          ? Center(
              child: Text('Not signed in',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary)))
          : StreamBuilder<List<NotificationModel>>(
              stream: _helperService.getUserNotifications(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 72,
                            color: AppColors.textLight
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('No notifications yet',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text(
                            'You\'ll see appointment updates\nand alerts here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textLight)),
                      ],
                    ),
                  );
                }

                final unread =
                    notifications.where((n) => !n.isRead).toList();
                final read =
                    notifications.where((n) => n.isRead).toList();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Mark all read action
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${notifications.length} notification${notifications.length != 1 ? 's' : ''}',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _markAllRead(uid, notifications),
                              icon: const Icon(Icons.done_all_rounded,
                                  size: 16),
                              label: Text('Mark all read',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Unread section
                    if (unread.isNotEmpty) ...[
                      SliverToBoxAdapter(
                          child: _sectionHeader(context, 'New')),
                      SliverPadding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _NotificationTile(
                              notification: unread[i],
                              timeLabel: _timeAgo(unread[i].createdAt),
                              icon: _iconFor(unread[i].type),
                              color: _colorFor(unread[i].type),
                              onTap: () =>
                                  _helperService.markAsRead(unread[i].id),
                            ),
                            childCount: unread.length,
                          ),
                        ),
                      ),
                    ],

                    // Read section
                    if (read.isNotEmpty) ...[
                      SliverToBoxAdapter(
                          child: _sectionHeader(context, 'Earlier')),
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _NotificationTile(
                              notification: read[i],
                              timeLabel: _timeAgo(read[i].createdAt),
                              icon: _iconFor(read[i].type),
                              color: _colorFor(read[i].type),
                              onTap: null,
                            ),
                            childCount: read.length,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight.withValues(alpha: 0.7),
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Single Notification Tile ──────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final String timeLabel;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.notification,
    required this.timeLabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRead = notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? theme.cardTheme.color
              : (isDark
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead
                ? AppColors.textLight.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [
            if (!isRead)
              BoxShadow(
                color: AppColors.primary
                    .withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.body,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 4),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

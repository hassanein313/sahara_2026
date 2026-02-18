import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../constants/app_colors.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';

/// صفحة الإشعارات - النسخة المطورة
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _activeFilter = 'الكل';
  final _filters = ['الكل', 'تنبيهات', 'نجاح', 'أخطاء', 'معلومات'];

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer2<FuelProvider, ThemeProvider>(
        builder: (context, provider, themeProvider, _) {
      final allNotifications = provider.notifications;
      final unreadCount = provider.unreadNotifications;

      // تصفية الإشعارات
      final filtered = _activeFilter == 'الكل'
          ? allNotifications
          : allNotifications.where((n) {
              switch (_activeFilter) {
                case 'تنبيهات':
                  return n.type == NotificationType.warning;
                case 'نجاح':
                  return n.type == NotificationType.success;
                case 'أخطاء':
                  return n.type == NotificationType.error;
                case 'معلومات':
                  return n.type == NotificationType.info;
                default:
                  return true;
              }
            }).toList();

      // تقسيم حسب اليوم
      final today = <AppNotification>[];
      final yesterday = <AppNotification>[];
      final older = <AppNotification>[];
      final now = DateTime.now();
      for (var n in filtered) {
        final diff = now.difference(n.date);
        if (diff.inHours < 24) {
          today.add(n);
        } else if (diff.inHours < 48) {
          yesterday.add(n);
        } else {
          older.add(n);
        }
      }

      return Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.getPageGradient(context))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ===== الهيدر =====
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('الإشعارات',
                        style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.getAccent(context).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text('$unreadCount جديد',
                            style: GoogleFonts.cairo(
                                color: AppColors.getAccent(context),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  Text('متابعة تنبيهات النظام والتحديثات',
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: Colors.grey[500])),
                ]),
                Row(children: [
                  if (unreadCount > 0)
                    _actionBtn(
                        'تحديد الكل كمقروء',
                        Icons.done_all,
                        AppColors.getAccent(context),
                        () => provider.markAllNotificationsAsRead()),
                  const SizedBox(width: 12),
                  _actionBtn('مسح المقروءة', Icons.delete_sweep,
                      Colors.grey[600]!, () {}),
                ]),
              ]),
              const SizedBox(height: 24),

              // ===== ملخص الإشعارات =====
              Row(children: [
                _summaryCard('الكل', '${allNotifications.length}',
                    Icons.notifications, Colors.grey),
                const SizedBox(width: 12),
                _summaryCard(
                    'تنبيهات',
                    '${allNotifications.where((n) => n.type == NotificationType.warning).length}',
                    Icons.warning,
                    AppColors.getWarning(context)),
                const SizedBox(width: 12),
                _summaryCard(
                    'نجاح',
                    '${allNotifications.where((n) => n.type == NotificationType.success).length}',
                    Icons.check_circle,
                    AppColors.getSuccess(context)),
                const SizedBox(width: 12),
                _summaryCard(
                    'أخطاء',
                    '${allNotifications.where((n) => n.type == NotificationType.error).length}',
                    Icons.error,
                    AppColors.getError(context)),
                const SizedBox(width: 12),
                _summaryCard(
                    'معلومات',
                    '${allNotifications.where((n) => n.type == NotificationType.info).length}',
                    Icons.info,
                    AppColors.getInfo(context)),
              ]),
              const SizedBox(height: 24),

              // ===== الفلاتر =====
              Row(
                  children: _filters
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _activeFilter = f),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _activeFilter == f
                                      ? _filterColor(f).withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _activeFilter == f
                                          ? _filterColor(f)
                                          : Colors.grey[700]!),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_activeFilter == f)
                                        Icon(_filterIcon(f),
                                            color: _filterColor(f), size: 14),
                                      if (_activeFilter == f)
                                        const SizedBox(width: 6),
                                      Text(f,
                                          style: GoogleFonts.cairo(
                                              color: _activeFilter == f
                                                  ? _filterColor(f)
                                                  : Colors.grey[500],
                                              fontWeight: _activeFilter == f
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 12)),
                                    ]),
                              ),
                            ),
                          ))
                      .toList()),
              const SizedBox(height: 24),

              // ===== قائمة الإشعارات حسب الوقت =====
              if (today.isNotEmpty) ...[
                _sectionHeader('اليوم', today.length),
                const SizedBox(height: 12),
                ...today.map((n) => _notifCard(n, provider)),
              ],
              if (yesterday.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionHeader('أمس', yesterday.length),
                const SizedBox(height: 12),
                ...yesterday.map((n) => _notifCard(n, provider)),
              ],
              if (older.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionHeader('أقدم', older.length),
                const SizedBox(height: 12),
                ...older.map((n) => _notifCard(n, provider)),
              ],
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(60),
                  child: Column(children: [
                    Icon(Icons.notifications_off,
                        color: Colors.grey[700], size: 60),
                    const SizedBox(height: 16),
                    Text('لا توجد إشعارات',
                        style: GoogleFonts.cairo(
                            fontSize: 18, color: Colors.grey[600])),
                  ]),
                ),
            ]),
          ),
        ),
      );
    });
  }

  Widget _summaryCard(String label, String count, IconData icon, Color color) {
    final isActive = (_activeFilter == label) ||
        (_activeFilter == 'الكل' && label == 'الكل');
    return Expanded(
        child: GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color:
                  isActive ? color.withOpacity(0.4) : const Color(0xFF2D3748)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(count,
              style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[500])),
        ]),
      ),
    ));
  }

  Widget _notifCard(AppNotification n, FuelProvider provider) {
    final color = _typeColor(n.type);
    final icon = _typeIcon(n.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          if (!n.isRead) provider.markNotificationAsRead(n.id);
        },
        child: Container(
          decoration: BoxDecoration(
            color: n.isRead ? AppColors.getSurface(context) : AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: n.isRead
                    ? const Color(0xFF2D3748)
                    : color.withOpacity(0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // أيقونة
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              // المحتوى
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(n.title,
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: n.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 14))),
                      if (!n.isRead)
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle)),
                    ]),
                    const SizedBox(height: 4),
                    Text(n.message,
                        style: GoogleFonts.cairo(
                            color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.access_time,
                          color: Colors.grey[700], size: 14),
                      const SizedBox(width: 4),
                      Text(_timeAgo(n.date),
                          style: GoogleFonts.cairo(
                              color: Colors.grey[600], fontSize: 11)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(_typeLabel(n.type),
                            style:
                                GoogleFonts.cairo(color: color, fontSize: 10)),
                      ),
                    ]),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Row(children: [
      Text(title,
          style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400])),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: const Color(0xFF252830),
            borderRadius: BorderRadius.circular(10)),
        child: Text('$count',
            style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Container(height: 1, color: Colors.grey[800])),
    ]);
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.cairo(color: color, fontSize: 12)),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('d/M/yyyy').format(time);
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return AppColors.getSuccess(context);
      case NotificationType.warning:
        return AppColors.getWarning(context);
      case NotificationType.error:
        return AppColors.getError(context);
      case NotificationType.info:
        return AppColors.getInfo(context);
    }
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  String _typeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return 'نجاح';
      case NotificationType.warning:
        return 'تنبيه';
      case NotificationType.error:
        return 'خطأ';
      case NotificationType.info:
        return 'معلومات';
    }
  }

  Color _filterColor(String f) {
    switch (f) {
      case 'تنبيهات':
        return AppColors.getWarning(context);
      case 'نجاح':
        return AppColors.getSuccess(context);
      case 'أخطاء':
        return AppColors.getError(context);
      case 'معلومات':
        return AppColors.getInfo(context);
      default:
        return AppColors.getAccent(context);
    }
  }

  IconData _filterIcon(String f) {
    switch (f) {
      case 'تنبيهات':
        return Icons.warning;
      case 'نجاح':
        return Icons.check_circle;
      case 'أخطاء':
        return Icons.error;
      case 'معلومات':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}

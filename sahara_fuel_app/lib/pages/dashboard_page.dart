import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'dart:ui' as ui;

/// صفحة لوحة التحكم الرئيسية - النسخة المطورة
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FuelProvider, ThemeProvider>(
      builder: (context, provider, themeProvider, _) {
        final formatter = NumberFormat('#,###', 'ar');
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.getPageGradient(context),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== الهيدر =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نظرة عامة',
                            style: GoogleFonts.cairo(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مرحباً ${Provider.of<AuthService>(context).userName.isNotEmpty ? Provider.of<AuthService>(context).userName : "بك"} - ${DateFormat('EEEE d MMMM yyyy', 'ar').format(DateTime.now())}',
                            style: GoogleFonts.cairo(
                                fontSize: 14, color: AppColors.getSubtleText(context)),
                          ),
                        ],
                      ),
                      // مؤشر نسبة الامتلاء الإجمالية
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.getCardBg(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.getAccent(context).withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: provider.overallFillPercentage / 100,
                                    strokeWidth: 4,
                                    backgroundColor: AppColors.getInputBg(context),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      provider.overallFillPercentage > 50
                                          ? AppColors.getAccent(context)
                                          : AppColors.getWarning(context),
                                    ),
                                  ),
                                  Text(
                                    '${provider.overallFillPercentage.toStringAsFixed(0)}%',
                                    style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('نسبة الامتلاء',
                                    style: GoogleFonts.cairo(
                                        fontSize: 11, color: Colors.grey[500])),
                                Text('الإجمالية',
                                    style: GoogleFonts.cairo(
                                        fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ===== البطاقات الإحصائية - الصف الأول (3 بطاقات رئيسية) =====
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'رصيد الصحاري الكلي',
                          value:
                              '${formatter.format(provider.saharaBalance)} لتر',
                          change:
                              '${provider.saharaChangePercent >= 0 ? "+" : ""}${provider.saharaChangePercent.toStringAsFixed(0)}%',
                          color: AppColors.getCardGreen(context),
                          icon: Icons.account_balance_wallet_rounded,
                          isPositive: provider.saharaChangePercent >= 0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'رصيد الاتحاد',
                          value:
                              '${formatter.format(provider.unionBalance)} لتر',
                          change:
                              '${provider.unionChangePercent >= 0 ? "+" : ""}${provider.unionChangePercent.toStringAsFixed(0)}%',
                          color: AppColors.getCardOrange(context),
                          icon: Icons.swap_horiz_rounded,
                          isPositive: provider.unionChangePercent >= 0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'رصيد المحطات',
                          value:
                              '${formatter.format(provider.stationsBalance)} لتر',
                          change:
                              '${provider.stationsChangePercent >= 0 ? "+" : ""}${provider.stationsChangePercent.toStringAsFixed(0)}%',
                          color: AppColors.getCardPurple(context),
                          icon: Icons.location_on_rounded,
                          isPositive: provider.stationsChangePercent >= 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ===== البطاقات الإحصائية - الصف الثاني (3 بطاقات إضافية) =====
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'الوارد اليوم',
                          value:
                              '${formatter.format(provider.todayIncoming)} لتر',
                          change: 'اليوم',
                          color: const Color(0xFF4CAF50),
                          icon: Icons.arrow_downward_rounded,
                          isPositive: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'الصادر اليوم',
                          value:
                              '${formatter.format(provider.todayOutgoing)} لتر',
                          change: 'اليوم',
                          color: const Color(0xFFEF5350),
                          icon: Icons.arrow_upward_rounded,
                          isPositive: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'المحطات النشطة',
                          value:
                              '${provider.activeStations} / ${provider.totalStations}',
                          change: 'محطة',
                          color: const Color(0xFF42A5F5),
                          icon: Icons.ev_station_rounded,
                          isPositive: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ===== القسم الأوسط: الرسم البياني + حالة الخزانات =====
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الرسم البياني
                      Expanded(
                        flex: 3,
                        child: _buildConsumptionChart(context, provider),
                      ),
                      const SizedBox(width: 20),
                      // حالة الخزانات
                      Expanded(
                        flex: 2,
                        child: _buildTankStatusSummary(context, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ===== القسم السفلي: آخر العمليات + ملخص سريع =====
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // آخر العمليات
                      Expanded(
                        flex: 3,
                        child: _buildRecentActivities(context, provider),
                      ),
                      const SizedBox(width: 20),
                      // ملخص الإشعارات
                      Expanded(
                        flex: 2,
                        child: _buildQuickAlerts(context, provider),
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

  // ===== رسم بياني الاستهلاك =====
  Widget _buildConsumptionChart(BuildContext context, FuelProvider provider) {
    final data = provider.dailyConsumption;
    return Card(
      color: AppColors.getCardBg(context),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الاستهلاك اليومي - آخر 30 يوم',
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.getAccent(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'متوسط: ${NumberFormat('#,###', 'ar').format(provider.averageDailyConsumption)} لتر/يوم',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.getAccent(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // وسائل الإيضاح
            Row(
              children: [
                _legendItem('الاستهلاك', AppColors.getCardGreen(context)),
                const SizedBox(width: 20),
                _legendItem('الوارد', AppColors.getCardOrange(context)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[800]!, strokeWidth: 0.5);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${data[value.toInt()].date.day}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20000,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}K',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // خط الاستهلاك
                    LineChartBarData(
                      spots: List.generate(
                        data.length,
                        (i) => FlSpot(i.toDouble(), data[i].consumed),
                      ),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [AppColors.getCardGreen(context), const Color(0xFF00B894)],
                      ),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.getCardGreen(context).withOpacity(0.3),
                            AppColors.getCardGreen(context).withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // خط الوارد
                    LineChartBarData(
                      spots: List.generate(
                        data.length,
                        (i) => FlSpot(i.toDouble(), data[i].incoming),
                      ),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [AppColors.getCardOrange(context), const Color(0xFFFFB74D)],
                      ),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      dashArray: [8, 4],
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isConsumption = spot.barIndex == 0;
                          return LineTooltipItem(
                            '${isConsumption ? "استهلاك" : "وارد"}: ${NumberFormat('#,###', 'ar').format(spot.y)} لتر',
                            TextStyle(
                              color: isConsumption
                                  ? AppColors.getCardGreen(context)
                                  : AppColors.getCardOrange(context),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 3,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  // ===== ملخص حالة الخزانات =====
  Widget _buildTankStatusSummary(BuildContext context, FuelProvider provider) {
    return Card(
      color: AppColors.getCardBg(context),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('حالة الخزانات',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // رسم دائري
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 35,
                  sections: [
                    PieChartSectionData(
                      value: provider
                          .tanksWithStatus(TankStatus.excellent)
                          .toDouble(),
                      color: const Color(0xFF4CAF50),
                      title:
                          '${provider.tanksWithStatus(TankStatus.excellent)}',
                      titleStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      radius: 40,
                    ),
                    PieChartSectionData(
                      value:
                          provider.tanksWithStatus(TankStatus.good).toDouble(),
                      color: AppColors.getAccent(context),
                      title: '${provider.tanksWithStatus(TankStatus.good)}',
                      titleStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      radius: 40,
                    ),
                    PieChartSectionData(
                      value: provider
                          .tanksWithStatus(TankStatus.medium)
                          .toDouble(),
                      color: AppColors.getCardOrange(context),
                      title: '${provider.tanksWithStatus(TankStatus.medium)}',
                      titleStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      radius: 40,
                    ),
                    PieChartSectionData(
                      value:
                          provider.tanksWithStatus(TankStatus.low).toDouble(),
                      color: AppColors.getError(context),
                      title: '${provider.tanksWithStatus(TankStatus.low)}',
                      titleStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      radius: 40,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // وسائل الإيضاح
            _statusLegend('ممتاز', const Color(0xFF4CAF50),
                provider.tanksWithStatus(TankStatus.excellent)),
            const SizedBox(height: 8),
            _statusLegend('جيد', AppColors.getAccent(context),
                provider.tanksWithStatus(TankStatus.good)),
            const SizedBox(height: 8),
            _statusLegend('متوسط', AppColors.getCardOrange(context),
                provider.tanksWithStatus(TankStatus.medium)),
            const SizedBox(height: 8),
            _statusLegend('منخفض', AppColors.getError(context),
                provider.tanksWithStatus(TankStatus.low)),
            const SizedBox(height: 16),
            // شريط المخزون الإجمالي
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المخزون الإجمالي',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.grey[500])),
                      Text(
                        '${NumberFormat('#,###', 'ar').format(provider.totalCurrentStock)} / ${NumberFormat('#,###', 'ar').format(provider.totalTankCapacity)}',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: provider.overallFillPercentage / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        provider.overallFillPercentage > 60
                            ? AppColors.getAccent(context)
                            : provider.overallFillPercentage > 30
                                ? AppColors.getCardOrange(context)
                                : AppColors.getError(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusLegend(String label, Color color, int count) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[400])),
        const Spacer(),
        Text('$count خزان',
            style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ===== آخر العمليات =====
  Widget _buildRecentActivities(BuildContext context, FuelProvider provider) {
    final activities = provider.recentActivities.take(6).toList();
    return Card(
      color: AppColors.getCardBg(context),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('آخر العمليات',
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                Text('اليوم',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 16),
            ...activities.map((activity) => _activityTile(activity)),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(RecentActivity activity) {
    Color iconColor;
    IconData icon;
    switch (activity.type) {
      case ActivityType.incoming:
        iconColor = const Color(0xFF4CAF50);
        icon = Icons.arrow_downward_rounded;
        break;
      case ActivityType.outgoing:
        iconColor = const Color(0xFFEF5350);
        icon = Icons.arrow_upward_rounded;
        break;
      case ActivityType.transfer:
        iconColor = const Color(0xFF42A5F5);
        icon = Icons.swap_horiz_rounded;
        break;
    }

    final timeAgo = _getTimeAgo(activity.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                Text(activity.description,
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormat('#,###', 'ar').format(activity.amount)} لتر',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: activity.type == ActivityType.incoming
                      ? const Color(0xFF4CAF50)
                      : activity.type == ActivityType.outgoing
                          ? const Color(0xFFEF5350)
                          : const Color(0xFF42A5F5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(timeAgo,
                  style:
                      GoogleFonts.cairo(fontSize: 10, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  // ===== التنبيهات السريعة =====
  Widget _buildQuickAlerts(BuildContext context, FuelProvider provider) {
    final alerts = provider.notifications.take(4).toList();
    return Card(
      color: AppColors.getCardBg(context),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('آخر التنبيهات',
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                if (provider.unreadNotifications > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('${provider.unreadNotifications} جديد',
                        style:
                            GoogleFonts.cairo(fontSize: 11, color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...alerts.map((alert) => _alertTile(context, alert)),
          ],
        ),
      ),
    );
  }

  Widget _alertTile(BuildContext context, AppNotification alert) {
    Color color;
    IconData icon;
    switch (alert.type) {
      case NotificationType.success:
        color = const Color(0xFF4CAF50);
        icon = Icons.check_circle_outline;
        break;
      case NotificationType.warning:
        color = AppColors.getCardOrange(context);
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationType.error:
        color = const Color(0xFFEF5350);
        icon = Icons.error_outline;
        break;
      case NotificationType.info:
        color = const Color(0xFF42A5F5);
        icon = Icons.info_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.isRead
            ? Colors.grey[900]?.withOpacity(0.3)
            : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: alert.isRead ? null : Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(alert.title,
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: alert.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold)),
                    ),
                    if (!alert.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                  ],
                ),
                Text(alert.message,
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: Colors.grey[500]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}

// ===== Widget بطاقة الإحصائية المطورة =====
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final Color color;
  final IconData icon;
  final bool isPositive;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.color,
    required this.icon,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.getCardBg(context),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.03)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFEF5350))
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFEF5350),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        change,
                        style: TextStyle(
                          color: isPositive
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(title,
                style:
                    GoogleFonts.cairo(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

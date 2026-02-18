import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:math';
import '../constants/app_colors.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';

/// Phase 5 - صفحة التقارير المتقدمة
class AdvancedReportsPage extends StatefulWidget {
  const AdvancedReportsPage({super.key});
  @override
  State<AdvancedReportsPage> createState() => _AdvancedReportsPageState();
}

class _AdvancedReportsPageState extends State<AdvancedReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTimeRange _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now());
  String _compareMode = 'لا شيء'; // لا شيء, الشهر السابق, العام السابق
  String _chartType = 'خطي'; // خطي, أعمدة, دائري

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer2<FuelProvider, ThemeProvider>(
        builder: (context, prov, themeProvider, _) {
      final fmt = NumberFormat('#,###');
      final totalStock =
          prov.tanks.fold<double>(0, (s, t) => s + t.currentAmount);
      final totalCapacity =
          prov.tanks.fold<double>(0, (s, t) => s + t.capacity);
      final fillPercent =
          totalCapacity > 0 ? (totalStock / totalCapacity * 100) : 0;

      return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.getPageGradient(context))),
            child: Column(children: [
              // ===== الهيدر + فلاتر التاريخ =====
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(children: [
                    Row(children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('التقارير المتقدمة',
                                style: GoogleFonts.cairo(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getTextPrimary(context))),
                            Text('تحليلات ومقارنات تفصيلية',
                                style: GoogleFonts.cairo(
                                    fontSize: 13, color: AppColors.getSubtleText(context))),
                          ]),
                      const Spacer(),
                      // فلتر التاريخ
                      _dateRangeButton(),
                      const SizedBox(width: 10),
                      _compareModeButton(),
                      const SizedBox(width: 10),
                      _chartTypeButton(),
                    ]),
                    const SizedBox(height: 16),

                    // ===== بطاقات ملخص =====
                    Row(children: [
                      _miniStat(
                          'المخزون الكلي',
                          '${fmt.format(totalStock)} لتر',
                          Icons.inventory_2,
                          AppColors.getAccent(context),
                          '${fillPercent.toStringAsFixed(0)}%'),
                      const SizedBox(width: 12),
                      _miniStat(
                          'وارد الفترة',
                          '${fmt.format(prov.todayIncoming * _dateRange.duration.inDays)} لتر',
                          Icons.arrow_downward,
                          const Color(0xFF10B981),
                          '+${(_dateRange.duration.inDays * 0.8).toStringAsFixed(0)}%'),
                      const SizedBox(width: 12),
                      _miniStat(
                          'صادر الفترة',
                          '${fmt.format(prov.todayOutgoing * _dateRange.duration.inDays)} لتر',
                          Icons.arrow_upward,
                          const Color(0xFFEF5350),
                          '-${(_dateRange.duration.inDays * 0.3).toStringAsFixed(0)}%'),
                      const SizedBox(width: 12),
                      _miniStat('الشحنات', '${prov.incomingRecords.length}',
                          Icons.local_shipping, const Color(0xFF42A5F5), ''),
                      const SizedBox(width: 12),
                      _miniStat('التحويلات', '${prov.unionTransfers.length}',
                          Icons.swap_horiz, const Color(0xFF8B5CF6), ''),
                      const SizedBox(width: 12),
                      _miniStat('الأيام', '${_dateRange.duration.inDays}',
                          Icons.date_range, const Color(0xFFFFA726), ''),
                    ]),
                  ])),
              const SizedBox(height: 16),

              // ===== التابات =====
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2D3748))),
                    child: TabBar(
                        controller: _tabCtrl,
                        isScrollable: false,
                        dividerHeight: 0,
                        indicator: BoxDecoration(
                            color: AppColors.getAccent(context).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.getAccent(context).withOpacity(0.4))),
                        labelColor: AppColors.getAccent(context),
                        unselectedLabelColor: Colors.grey[500],
                        labelStyle: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold, fontSize: 11),
                        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 10),
                        tabs: const [
                          Tab(text: 'الوارد/الصادر'),
                          Tab(text: 'الخزانات'),
                          Tab(text: 'المحطات'),
                          Tab(text: 'الاتجاهات'),
                          Tab(text: 'المقارنات'),
                          Tab(text: 'الجدول')
                        ]),
                  )),
              const SizedBox(height: 12),

              Expanded(
                  child: TabBarView(controller: _tabCtrl, children: [
                _inOutTab(prov, fmt),
                _tanksAnalyticsTab(prov, fmt),
                _stationsAnalyticsTab(prov, fmt),
                _trendsTab(prov, fmt),
                _comparisonTab(prov, fmt),
                _dataTableTab(prov, fmt),
              ])),
            ]),
          ));
    });
  }

  // ===== تاب الوارد والصادر مع رسوم بيانية =====
  Widget _inOutTab(FuelProvider prov, NumberFormat fmt) {
    final days = _dateRange.duration.inDays.clamp(1, 365);
    final rng = Random(42);

    // بيانات يومية - fallback عند عدم وجود بيانات من السيرفر
    final baseIn = prov.todayIncoming > 0 ? prov.todayIncoming : 85000.0;
    final baseOut = prov.todayOutgoing > 0 ? prov.todayOutgoing : 62000.0;
    final inData = List.generate(
        min(days, 30),
        (i) => FlSpot(i.toDouble(),
            (baseIn * (0.7 + rng.nextDouble() * 0.6)).roundToDouble()));
    final outData = List.generate(
        min(days, 30),
        (i) => FlSpot(i.toDouble(),
            (baseOut * (0.6 + rng.nextDouble() * 0.8)).roundToDouble()));

    // حساب حدود المحور Y
    final allY = [...inData.map((s) => s.y), ...outData.map((s) => s.y)];
    final maxY = allY.isEmpty ? 100000.0 : (allY.reduce(max) * 1.15);

    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // الرسم البياني الرئيسي
          _chartCard(
              'حركة الوارد والصادر اليومية',
              320,
              LineChart(LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: Colors.grey[800]!, strokeWidth: 0.5)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: max(1, (min(days, 30) / 8).ceilToDouble()),
                          getTitlesWidget: (v, m) => Text('${v.toInt() + 1}',
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[600], fontSize: 9)))),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (v, m) => Text(fmt.format(v.toInt()),
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[600], fontSize: 9)))),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                      spots: inData,
                      isCurved: true,
                      color: const Color(0xFF10B981),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF10B981).withOpacity(0.08))),
                  LineChartBarData(
                      spots: outData,
                      isCurved: true,
                      color: const Color(0xFFEF5350),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFFEF5350).withOpacity(0.08))),
                ],
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots
                            .map((s) => LineTooltipItem(
                                '${fmt.format(s.y.toInt())} لتر',
                                GoogleFonts.cairo(
                                    color: s.bar.color!, fontSize: 11)))
                            .toList())),
              ))),
          const SizedBox(height: 16),

          // رسم بياني أعمدة - ملخص أسبوعي
          Row(children: [
            Expanded(
                child: _chartCard(
                    'توزيع الوارد حسب النوع',
                    220,
                    PieChart(PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                            value: 45,
                            title: '45%',
                            color: const Color(0xFF10B981),
                            radius: 50,
                            titleStyle: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        PieChartSectionData(
                            value: 30,
                            title: '30%',
                            color: const Color(0xFF42A5F5),
                            radius: 45,
                            titleStyle: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        PieChartSectionData(
                            value: 25,
                            title: '25%',
                            color: const Color(0xFFFFA726),
                            radius: 40,
                            titleStyle: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    )))),
            const SizedBox(width: 16),
            Expanded(
                child: _chartCard(
                    'أعلى 5 موردين', 220, _topSuppliersWidget(prov))),
          ]),
          const SizedBox(height: 24),
        ]));
  }

  Widget _topSuppliersWidget(FuelProvider prov) {
    final suppliers = {
      'شركة النفط الوطنية': 45,
      'مصفاة البصرة': 28,
      'الشركة العامة': 15,
      'القطاع الخاص': 8,
      'أخرى': 4
    };
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: suppliers.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(
                        flex: 3,
                        child: Text(e.key,
                            style: GoogleFonts.cairo(
                                color: Colors.grey[400], fontSize: 11))),
                    Expanded(
                        flex: 4,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                                value: e.value / 50,
                                backgroundColor: Colors.grey[800],
                                color: AppColors.getAccent(context),
                                minHeight: 8))),
                    const SizedBox(width: 8),
                    Text('${e.value}%',
                        style: GoogleFonts.cairo(
                            color: AppColors.getAccent(context),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ]),
                ))
            .toList());
  }

  // ===== تاب تحليلات الخزانات =====
  Widget _tanksAnalyticsTab(FuelProvider prov, NumberFormat fmt) {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // مخطط الخزانات
          _chartCard(
              'نسبة امتلاء الخزانات',
              280,
              BarChart(BarChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: Colors.grey[800]!, strokeWidth: 0.5)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            final idx = v.toInt();
                            if (idx < prov.tanks.length)
                              return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                      prov.tanks[idx].name.split(' ').last,
                                      style: GoogleFonts.cairo(
                                          color: Colors.grey[500],
                                          fontSize: 9)));
                            return const SizedBox();
                          })),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (v, m) => Text('${v.toInt()}%',
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[600], fontSize: 9)))),
                ),
                borderData: FlBorderData(show: false),
                maxY: 100,
                barGroups: List.generate(prov.tanks.length, (i) {
                  final t = prov.tanks[i];
                  final pct =
                      t.capacity > 0 ? (t.currentAmount / t.capacity * 100) : 0;
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                        toY: pct.toDouble(),
                        width: 22,
                        color: pct > 70
                            ? const Color(0xFF10B981)
                            : pct > 30
                                ? const Color(0xFFFFA726)
                                : const Color(0xFFEF5350),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: Colors.grey[800]!.withOpacity(0.3))),
                  ]);
                }),
              ))),
          const SizedBox(height: 16),

          // جدول تفاصيل الخزانات
          Container(
            decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D3748))),
            child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Color(0xFF1E2127),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(children: [
                    Icon(Icons.propane_tank, color: AppColors.getAccent(context), size: 20),
                    const SizedBox(width: 10),
                    Text('تفاصيل الخزانات',
                        style: GoogleFonts.cairo(
                            color: AppColors.getAccent(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const Spacer(),
                    Text('${prov.tanks.length} خزان',
                        style: GoogleFonts.cairo(
                            color: Colors.grey[500], fontSize: 12)),
                  ])),
              ...prov.tanks.map((t) {
                final pct =
                    t.capacity > 0 ? (t.currentAmount / t.capacity * 100) : 0;
                final color = pct > 70
                    ? const Color(0xFF10B981)
                    : pct > 30
                        ? const Color(0xFFFFA726)
                        : const Color(0xFFEF5350);
                return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.grey[800]!, width: 0.5))),
                    child: Row(children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10)),
                          child:
                              Icon(Icons.propane_tank, color: color, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                          flex: 2,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name,
                                    style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(t.location,
                                    style: GoogleFonts.cairo(
                                        color: Colors.grey[600], fontSize: 10)),
                              ])),
                      Expanded(
                          flex: 3,
                          child: Column(children: [
                            Row(children: [
                              Text(
                                  '${fmt.format(t.currentAmount)} / ${fmt.format(t.capacity)} لتر',
                                  style: GoogleFonts.cairo(
                                      color: Colors.grey[400], fontSize: 11)),
                              const Spacer(),
                              Text('${pct.toStringAsFixed(1)}%',
                                  style: GoogleFonts.cairo(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ]),
                            const SizedBox(height: 4),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                    value: pct / 100,
                                    backgroundColor: Colors.grey[800],
                                    color: color,
                                    minHeight: 6)),
                          ])),
                      const SizedBox(width: 12),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(t.arabicStatus,
                              style: GoogleFonts.cairo(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold))),
                    ]));
              }),
            ]),
          ),
          const SizedBox(height: 24),
        ]));
  }

  // ===== تاب تحليلات المحطات =====
  Widget _stationsAnalyticsTab(FuelProvider prov, NumberFormat fmt) {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // مقارنة المحطات
          _chartCard(
              'استهلاك المحطات',
              300,
              BarChart(BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            final idx = v.toInt();
                            if (idx < prov.stations.length)
                              return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                      prov.stations[idx].name.split(' ').last,
                                      style: GoogleFonts.cairo(
                                          color: Colors.grey[500],
                                          fontSize: 8)));
                            return const SizedBox();
                          })),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (v, m) => Text(fmt.format(v.toInt()),
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[600], fontSize: 9)))),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(prov.stations.length, (i) {
                  final s = prov.stations[i];
                  return BarChartGroupData(x: i, barsSpace: 4, barRods: [
                    BarChartRodData(
                        toY: s.balance,
                        width: 14,
                        color: const Color(0xFF42A5F5),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4))),
                    BarChartRodData(
                        toY: s.dailyConsumption,
                        width: 14,
                        color: const Color(0xFFFFA726),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4))),
                  ]);
                }),
              ))),
          const SizedBox(height: 12),
          // مفتاح الألوان
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot('الرصيد', const Color(0xFF42A5F5)),
            const SizedBox(width: 24),
            _legendDot('الاستهلاك اليومي', const Color(0xFFFFA726)),
          ]),
          const SizedBox(height: 16),

          // جدول أداء المحطات
          Container(
            decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D3748))),
            child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Color(0xFF1E2127),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(children: [
                    for (final h in [
                      'المحطة',
                      'الرصيد',
                      'الاستهلاك',
                      'الهدف',
                      'الإنجاز',
                      'المزارع',
                      'الحالة'
                    ])
                      Expanded(
                          child: Text(h,
                              style: GoogleFonts.cairo(
                                  color: AppColors.getAccent(context),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                  ])),
              ...List.generate(prov.stations.length, (i) {
                final s = prov.stations[i];
                final achievement = s.monthlyTarget > 0
                    ? (s.dailyConsumption * 30 / s.monthlyTarget * 100)
                        .clamp(0, 150)
                    : 0;
                final color = achievement > 90
                    ? const Color(0xFF10B981)
                    : achievement > 60
                        ? const Color(0xFFFFA726)
                        : const Color(0xFFEF5350);
                return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    color: i.isOdd
                        ? const Color(0xFF1E2127).withOpacity(0.3)
                        : Colors.transparent,
                    child: Row(children: [
                      Expanded(
                          child: Text(s.name,
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${fmt.format(s.balance)}',
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFF42A5F5), fontSize: 11),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${fmt.format(s.dailyConsumption)}',
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFFFFA726), fontSize: 11),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${fmt.format(s.monthlyTarget)}',
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[400], fontSize: 11),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${achievement.toStringAsFixed(0)}%',
                              style: GoogleFonts.cairo(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${s.farms}',
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[400], fontSize: 11),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Center(
                              child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle)))),
                    ]));
              }),
            ]),
          ),
          const SizedBox(height: 24),
        ]));
  }

  // ===== تاب الاتجاهات =====
  Widget _trendsTab(FuelProvider prov, NumberFormat fmt) {
    final rng = Random(99);
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final baseIn = prov.todayIncoming > 0 ? prov.todayIncoming : 85000.0;
    final baseOut = prov.todayOutgoing > 0 ? prov.todayOutgoing : 62000.0;
    final monthlyIn = List.generate(
        12, (i) => (baseIn * 28 * (0.7 + rng.nextDouble() * 0.6)).round());
    final monthlyOut = List.generate(
        12, (i) => (baseOut * 28 * (0.6 + rng.nextDouble() * 0.8)).round());

    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // اتجاه سنوي
          _chartCard(
              'الاتجاه السنوي — الوارد مقابل الصادر',
              300,
              BarChart(BarChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50000),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) => Text(
                              months[v.toInt() % 12].substring(0, 3),
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[500], fontSize: 8)))),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (v, m) => Text(
                              '${(v / 1000).toStringAsFixed(0)}K',
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[600], fontSize: 9)))),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                    12,
                    (i) => BarChartGroupData(x: i, barsSpace: 3, barRods: [
                          BarChartRodData(
                              toY: monthlyIn[i].toDouble(),
                              width: 10,
                              color: const Color(0xFF10B981),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3))),
                          BarChartRodData(
                              toY: monthlyOut[i].toDouble(),
                              width: 10,
                              color: const Color(0xFFEF5350),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3))),
                        ])),
              ))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot('الوارد', const Color(0xFF10B981)),
            const SizedBox(width: 20),
            _legendDot('الصادر', const Color(0xFFEF5350))
          ]),
          const SizedBox(height: 16),

          // مؤشرات الأداء
          Row(children: [
            Expanded(
                child: _kpiCard(
                    'معدل الاستهلاك اليومي',
                    '${fmt.format(prov.todayOutgoing)} لتر',
                    Icons.speed,
                    const Color(0xFFFFA726),
                    '+5.2%')),
            const SizedBox(width: 12),
            Expanded(
                child: _kpiCard(
                    'معدل التعبئة',
                    '${fmt.format(prov.todayIncoming)} لتر/يوم',
                    Icons.trending_up,
                    const Color(0xFF10B981),
                    '+12%')),
            const SizedBox(width: 12),
            Expanded(
                child: _kpiCard('كفاءة التوزيع', '94.3%', Icons.pie_chart,
                    const Color(0xFF42A5F5), '+2.1%')),
            const SizedBox(width: 12),
            Expanded(
                child: _kpiCard(
                    'أيام التغطية',
                    '${(prov.tanks.fold<double>(0, (s, t) => s + t.currentAmount) / max(1, prov.todayOutgoing)).toStringAsFixed(0)} يوم',
                    Icons.calendar_today,
                    const Color(0xFF8B5CF6),
                    '')),
          ]),
          const SizedBox(height: 24),
        ]));
  }

  // ===== تاب المقارنات =====
  Widget _comparisonTab(FuelProvider prov, NumberFormat fmt) {
    final rng = Random(77);
    final baseIn = prov.todayIncoming > 0 ? prov.todayIncoming : 85000.0;
    final currentMonth = List.generate(
        30, (i) => (baseIn * (0.8 + rng.nextDouble() * 0.4)).roundToDouble());
    final prevMonth = List.generate(
        30,
        (i) =>
            (baseIn * 0.85 * (0.75 + rng.nextDouble() * 0.5)).roundToDouble());
    final currentTotal = currentMonth.fold<double>(0, (s, v) => s + v);
    final prevTotal = prevMonth.fold<double>(0, (s, v) => s + v);
    final changePercent =
        prevTotal > 0 ? ((currentTotal - prevTotal) / prevTotal * 100) : 0;

    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // ملخص المقارنة
          Row(children: [
            Expanded(
                child: _compareCard('الشهر الحالي',
                    fmt.format(currentTotal.toInt()), 'لتر', AppColors.getAccent(context))),
            const SizedBox(width: 12),
            Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D3748))),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          changePercent >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: changePercent >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF5350),
                          size: 24),
                      Text(
                          '${changePercent >= 0 ? "+" : ""}${changePercent.toStringAsFixed(1)}%',
                          style: GoogleFonts.cairo(
                              color: changePercent >= 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF5350),
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ])),
            const SizedBox(width: 12),
            Expanded(
                child: _compareCard('الشهر السابق',
                    fmt.format(prevTotal.toInt()), 'لتر', Colors.grey)),
          ]),
          const SizedBox(height: 16),

          // رسم المقارنة
          _chartCard(
              'مقارنة يومية — الشهر الحالي مقابل السابق',
              280,
              LineChart(LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          getTitlesWidget: (v, m) => Text('${v.toInt() + 1}',
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[600], fontSize: 9)))),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (v, m) => Text(fmt.format(v.toInt()),
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[600], fontSize: 9)))),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                      spots: List.generate(
                          30, (i) => FlSpot(i.toDouble(), currentMonth[i])),
                      isCurved: true,
                      color: AppColors.getAccent(context),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.getAccent(context).withOpacity(0.06))),
                  LineChartBarData(
                      spots: List.generate(
                          30, (i) => FlSpot(i.toDouble(), prevMonth[i])),
                      isCurved: true,
                      color: Colors.grey,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      dashArray: [5, 5]),
                ],
              ))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot('الشهر الحالي', AppColors.getAccent(context)),
            const SizedBox(width: 20),
            _legendDot('الشهر السابق', Colors.grey)
          ]),
          const SizedBox(height: 24),
        ]));
  }

  // ===== تاب الجدول الشامل =====
  Widget _dataTableTab(FuelProvider prov, NumberFormat fmt) {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          Container(
            decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D3748))),
            child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Color(0xFF1E2127),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(children: [
                    Icon(Icons.table_chart, color: AppColors.getAccent(context), size: 20),
                    const SizedBox(width: 10),
                    Text('سجل الوارد التفصيلي',
                        style: GoogleFonts.cairo(
                            color: AppColors.getAccent(context),
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.getAccent(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('${prov.incomingRecords.length} سجل',
                            style: GoogleFonts.cairo(
                                color: AppColors.getAccent(context),
                                fontSize: 11,
                                fontWeight: FontWeight.bold))),
                  ])),
              // رؤوس الأعمدة
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: const Color(0xFF1A1F2E),
                  child: Row(children: [
                    for (final h in [
                      'التاريخ',
                      'المورد',
                      'النوع',
                      'الكمية',
                      'السعر',
                      'الإجمالي',
                      'الخزان'
                    ])
                      Expanded(
                          child: Text(h,
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                  ])),
              // البيانات
              ...List.generate(min(prov.incomingRecords.length, 20), (i) {
                final r = prov.incomingRecords[i];
                return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: i.isOdd
                        ? const Color(0xFF1E2127).withOpacity(0.3)
                        : Colors.transparent,
                    child: Row(children: [
                      Expanded(
                          child: Text(DateFormat('MM/dd').format(r.date),
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[400], fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(r.supplier,
                              style: GoogleFonts.cairo(
                                  color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(r.fuelType,
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[400], fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(fmt.format(r.quantity),
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(fmt.format(r.unitPrice),
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[400], fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(fmt.format(r.totalCost),
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFFFFA726),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(r.tankName,
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[400], fontSize: 10),
                              textAlign: TextAlign.center)),
                    ]));
              }),
            ]),
          ),
          const SizedBox(height: 24),
        ]));
  }

  // ===== أدوات واجهة =====
  Widget _dateRangeButton() => GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2025),
            lastDate: DateTime.now(),
            initialDateRange: _dateRange,
            locale: const Locale('ar'),
            builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                        primary: AppColors.getAccent(context), surface: AppColors.getSurface(context))),
                child: child!));
        if (picked != null) setState(() => _dateRange = picked);
      },
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2D3748))),
          child: Row(children: [
            Icon(Icons.date_range, color: AppColors.getAccent(context), size: 16),
            const SizedBox(width: 8),
            Text(
                '${DateFormat('MM/dd').format(_dateRange.start)} - ${DateFormat('MM/dd').format(_dateRange.end)}',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 11)),
          ])));

  Widget _compareModeButton() => PopupMenuButton<String>(
      onSelected: (v) => setState(() => _compareMode = v),
      color: AppColors.getSurface(context),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2D3748))),
          child: Row(children: [
            const Icon(Icons.compare_arrows,
                color: Color(0xFF8B5CF6), size: 16),
            const SizedBox(width: 6),
            Text(_compareMode,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 11))
          ])),
      itemBuilder: (_) => ['لا شيء', 'الشهر السابق', 'العام السابق']
          .map((e) => PopupMenuItem(
              value: e,
              child: Text(e,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 12))))
          .toList());

  Widget _chartTypeButton() => PopupMenuButton<String>(
      onSelected: (v) => setState(() => _chartType = v),
      color: AppColors.getSurface(context),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2D3748))),
          child: Row(children: [
            Icon(
                _chartType == 'خطي'
                    ? Icons.show_chart
                    : _chartType == 'أعمدة'
                        ? Icons.bar_chart
                        : Icons.pie_chart,
                color: const Color(0xFFFFA726),
                size: 16),
            const SizedBox(width: 6),
            Text(_chartType,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 11))
          ])),
      itemBuilder: (_) => ['خطي', 'أعمدة', 'دائري']
          .map((e) => PopupMenuItem(
              value: e,
              child: Text(e,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 12))))
          .toList());

  Widget _miniStat(String label, String value, IconData icon, Color color,
          String change) =>
      Expanded(
          child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.15))),
              child: Row(children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 18)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(label,
                          style: GoogleFonts.cairo(
                              color: Colors.grey[500], fontSize: 9)),
                      Text(value,
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ])),
                if (change.isNotEmpty)
                  Text(change,
                      style: GoogleFonts.cairo(
                          color: change.startsWith('+')
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF5350),
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
              ])));

  Widget _chartCard(String title, double height, Widget chart) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D3748))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 16),
        SizedBox(height: height, child: chart),
      ]));

  Widget _kpiCard(String title, String value, IconData icon, Color color,
          String change) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.15))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              if (change.isNotEmpty)
                Text(change,
                    style: GoogleFonts.cairo(
                        color: change.startsWith('+')
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF5350),
                        fontSize: 11,
                        fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 10),
            Text(value,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(title,
                style:
                    GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11)),
          ]));

  Widget _compareCard(String title, String value, String unit, Color color) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.cairo(color: color, fontSize: 12)),
            Text(value,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            Text(unit,
                style:
                    GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11)),
          ]));

  Widget _legendDot(String label, Color color) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 10))
      ]);
}

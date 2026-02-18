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

/// Phase 8 - لوحة إدارة المحطات
class StationManagerPage extends StatefulWidget {
  const StationManagerPage({super.key});
  @override
  State<StationManagerPage> createState() => _StationManagerPageState();
}

class _StationManagerPageState extends State<StationManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _selectedStation; // null = عرض الكل

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
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
      final stations = prov.stations;
      final totalConsumption =
          stations.fold<double>(0, (s, st) => s + st.dailyConsumption);
      final totalTarget =
          stations.fold<double>(0, (s, st) => s + st.monthlyTarget);
      final totalFarms = prov.totalFarmsCount;

      return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.getPageGradient(context))),
            child: Column(children: [
              // ===== الهيدر =====
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(children: [
                    Row(children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('إدارة المحطات',
                                style: GoogleFonts.cairo(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            Text('مراقبة وإدارة جميع المحطات',
                                style: GoogleFonts.cairo(
                                    fontSize: 13, color: Colors.grey[500])),
                          ]),
                      const Spacer(),
                      // فلتر المحطة
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 0),
                          decoration: BoxDecoration(
                              color: AppColors.getSurface(context),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFF2D3748))),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                            value: _selectedStation,
                            dropdownColor: AppColors.getSurface(context),
                            style: GoogleFonts.cairo(
                                color: Colors.white, fontSize: 12),
                            hint: Text('جميع المحطات',
                                style: GoogleFonts.cairo(
                                    color: AppColors.getAccent(context), fontSize: 12)),
                            items: [
                              DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('جميع المحطات',
                                      style: GoogleFonts.cairo(fontSize: 12))),
                              ...stations.map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Row(children: [
                                    Icon(s.icon, color: s.color, size: 14),
                                    const SizedBox(width: 6),
                                    Text(s.name,
                                        style: GoogleFonts.cairo(fontSize: 12))
                                  ]))),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedStation = v),
                          ))),
                    ]),
                    const SizedBox(height: 16),

                    // إحصائيات سريعة
                    Row(children: [
                      _quickStat('المحطات', '${stations.length}', Icons.store,
                          AppColors.getAccent(context)),
                      const SizedBox(width: 10),
                      _quickStat(
                          'الاستهلاك اليومي',
                          '${fmt.format(totalConsumption)} لتر',
                          Icons.speed,
                          const Color(0xFFFFA726)),
                      const SizedBox(width: 10),
                      _quickStat(
                          'الهدف الشهري',
                          '${fmt.format(totalTarget)} لتر',
                          Icons.flag,
                          const Color(0xFF42A5F5)),
                      const SizedBox(width: 10),
                      _quickStat('المزارع', '$totalFarms', Icons.agriculture,
                          const Color(0xFF10B981)),
                      const SizedBox(width: 10),
                      _quickStat(
                          'الكفاءة',
                          '${(totalConsumption * 30 / max(1, totalTarget) * 100).toStringAsFixed(0)}%',
                          Icons.trending_up,
                          const Color(0xFF8B5CF6)),
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
                            fontWeight: FontWeight.bold, fontSize: 12),
                        tabs: const [
                          Tab(text: 'نظرة عامة'),
                          Tab(text: 'الأداء'),
                          Tab(text: 'التشغيل'),
                          Tab(text: 'المقارنة')
                        ]),
                  )),
              const SizedBox(height: 12),

              Expanded(
                  child: TabBarView(controller: _tabCtrl, children: [
                _overviewTab(prov, fmt, stations),
                _performanceTab(prov, fmt, stations),
                _operationsTab(prov, fmt, stations),
                _comparisonTab(prov, fmt, stations),
              ])),
            ]),
          ));
    });
  }

  // ===== تاب النظرة العامة =====
  Widget _overviewTab(
      FuelProvider prov, NumberFormat fmt, List<StationInfo> stations) {
    final filtered = _selectedStation != null
        ? stations.where((s) => s.id == _selectedStation).toList()
        : stations;
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // بطاقات المحطات
          Wrap(
              spacing: 16,
              runSpacing: 16,
              children:
                  filtered.map((s) => _stationCard(s, fmt, prov)).toList()),
          const SizedBox(height: 24),
        ]));
  }

  Widget _stationCard(StationInfo s, NumberFormat fmt, FuelProvider prov) {
    final achievement = s.monthlyTarget > 0
        ? (s.dailyConsumption * 30 / s.monthlyTarget * 100).clamp(0, 150)
        : 0;
    final color = achievement > 90
        ? const Color(0xFFEF5350)
        : achievement > 70
            ? const Color(0xFFFFA726)
            : const Color(0xFF10B981);
    final coverageDays =
        s.dailyConsumption > 0 ? (s.balance / 1000 / s.dailyConsumption) : 999;

    return Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: s.color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: s.color.withOpacity(0.05), blurRadius: 20)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // رأس البطاقة
          Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: s.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(s.icon, color: s.color, size: 24)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(s.name,
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Row(children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('متصلة',
                        style: GoogleFonts.cairo(
                            color: const Color(0xFF10B981), fontSize: 10)),
                    const SizedBox(width: 10),
                    Text('${s.totalFarms} مزرعة',
                        style: GoogleFonts.cairo(
                            color: Colors.grey[500], fontSize: 10)),
                  ]),
                ])),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: s.change >= 0
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF5350).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('${s.change >= 0 ? "+" : ""}${s.change}%',
                    style: GoogleFonts.cairo(
                        color: s.change >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF5350),
                        fontSize: 11,
                        fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 16),

          // إحصائيات
          Row(children: [
            _miniKPI('الرصيد', FuelProvider.formatNumber(s.balance),
                const Color(0xFF42A5F5)),
            _miniKPI('استهلاك/يوم', '${fmt.format(s.dailyConsumption)}',
                const Color(0xFFFFA726)),
            _miniKPI(
                'التغطية',
                '${coverageDays.toStringAsFixed(0)} يوم',
                coverageDays < 5
                    ? const Color(0xFFEF5350)
                    : const Color(0xFF10B981)),
          ]),
          const SizedBox(height: 12),

          // شريط الإنجاز
          Row(children: [
            Text('الإنجاز الشهري',
                style:
                    GoogleFonts.cairo(color: Colors.grey[500], fontSize: 10)),
            const Spacer(),
            Text('${achievement.toStringAsFixed(0)}%',
                style: GoogleFonts.cairo(
                    color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: (achievement / 100).clamp(0, 1).toDouble(),
                  backgroundColor: Colors.grey[800],
                  color: color,
                  minHeight: 8)),

          const SizedBox(height: 12),
          // التشغيل
          Row(children: [
            _opBadge('مولّد', '${s.generatorHours}h', Icons.electrical_services,
                const Color(0xFFFFA726)),
            const SizedBox(width: 8),
            _opBadge('تدفئة', '${s.heaterHours}h', Icons.thermostat,
                const Color(0xFFEF5350)),
            const Spacer(),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: s.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: s.color.withOpacity(0.2))),
                child: Text('تفاصيل',
                    style: GoogleFonts.cairo(
                        color: s.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold))),
          ]),
        ]));
  }

  // ===== تاب الأداء =====
  Widget _performanceTab(
      FuelProvider prov, NumberFormat fmt, List<StationInfo> stations) {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // مخطط الأداء
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D3748))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مقارنة الأداء بين المحطات',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 20),
                    SizedBox(
                        height: 300,
                        child: BarChart(BarChartData(
                          gridData:
                              FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, m) {
                                      if (v.toInt() < stations.length)
                                        return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                                stations[v.toInt()]
                                                    .name
                                                    .replaceAll('محطة ', ''),
                                                style: GoogleFonts.cairo(
                                                    color: Colors.grey[500],
                                                    fontSize: 8)));
                                      return const SizedBox();
                                    })),
                            leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: (v, m) => Text(
                                        fmt.format(v.toInt()),
                                        style: GoogleFonts.cairo(
                                            color: Colors.grey[600],
                                            fontSize: 9)))),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(stations.length, (i) {
                            final s = stations[i];
                            return BarChartGroupData(
                                x: i,
                                barsSpace: 3,
                                barRods: [
                                  BarChartRodData(
                                      toY: s.dailyConsumption,
                                      width: 12,
                                      color: s.color,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4))),
                                  BarChartRodData(
                                      toY: s.monthlyTarget / 30,
                                      width: 12,
                                      color: Colors.grey[700]!,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4))),
                                ]);
                          }),
                        ))),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _legendDot('الاستهلاك الفعلي', AppColors.getAccent(context)),
                      const SizedBox(width: 20),
                      _legendDot('الهدف اليومي', Colors.grey),
                    ]),
                  ])),
          const SizedBox(height: 16),

          // جدول الأداء
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
                      'يومي',
                      'الهدف',
                      'الإنجاز',
                      'المزارع',
                      'الكفاءة',
                      'التقييم'
                    ])
                      Expanded(
                          child: Text(h,
                              style: GoogleFonts.cairo(
                                  color: AppColors.getAccent(context),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                  ])),
              ...stations.map((s) {
                final ach = s.monthlyTarget > 0
                    ? (s.dailyConsumption * 30 / s.monthlyTarget * 100)
                    : 0;
                final eff = s.generatorHours > 0
                    ? (s.dailyConsumption / s.generatorHours).toStringAsFixed(0)
                    : '-';
                final rating = ach < 70
                    ? '⭐⭐⭐'
                    : ach < 90
                        ? '⭐⭐'
                        : '⭐';
                final color = ach < 70
                    ? const Color(0xFF10B981)
                    : ach < 90
                        ? const Color(0xFFFFA726)
                        : const Color(0xFFEF5350);
                return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.grey[800]!, width: 0.5))),
                    child: Row(children: [
                      Expanded(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Icon(s.icon, color: s.color, size: 14),
                            const SizedBox(width: 4),
                            Flexible(
                                child: Text(s.name.replaceAll('محطة ', ''),
                                    style: GoogleFonts.cairo(
                                        color: Colors.white, fontSize: 10),
                                    overflow: TextOverflow.ellipsis))
                          ])),
                      Expanded(
                          child: Text(fmt.format(s.dailyConsumption),
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFFFFA726), fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(fmt.format(s.monthlyTarget),
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[400], fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${ach.toStringAsFixed(0)}%',
                              style: GoogleFonts.cairo(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${s.totalFarms}',
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[400], fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('$eff لتر/h',
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[400], fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(rating,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10))),
                    ]));
              }),
            ]),
          ),
          const SizedBox(height: 24),
        ]));
  }

  // ===== تاب التشغيل =====
  Widget _operationsTab(
      FuelProvider prov, NumberFormat fmt, List<StationInfo> stations) {
    final totalGen = stations.fold<int>(0, (s, st) => s + st.generatorHours);
    final totalHeat = stations.fold<int>(0, (s, st) => s + st.heaterHours);
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // إحصائيات التشغيل
          Row(children: [
            Expanded(
                child: _opStatCard(
                    'ساعات المولدات',
                    '$totalGen ساعة',
                    Icons.electrical_services,
                    const Color(0xFFFFA726),
                    '${stations.length} محطة')),
            const SizedBox(width: 12),
            Expanded(
                child: _opStatCard(
                    'ساعات التدفئة',
                    '$totalHeat ساعة',
                    Icons.thermostat,
                    const Color(0xFFEF5350),
                    '${stations.where((s) => s.heaterHours > 0).length} محطة')),
            const SizedBox(width: 12),
            Expanded(
                child: _opStatCard(
                    'معدل التشغيل',
                    '${totalGen > 0 ? ((totalGen / (stations.length * 168)) * 100).toStringAsFixed(0) : 0}%',
                    Icons.speed,
                    const Color(0xFF42A5F5),
                    'من إجمالي الأسبوع')),
            const SizedBox(width: 12),
            Expanded(
                child: _opStatCard(
                    'كفاءة الوقود',
                    '${prov.todayOutgoing > 0 ? (prov.todayOutgoing / max(1, totalGen)).toStringAsFixed(0) : 0} لتر/h',
                    Icons.eco,
                    const Color(0xFF10B981),
                    'معدل الاستهلاك')),
          ]),
          const SizedBox(height: 16),

          // مخطط ساعات التشغيل
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D3748))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ساعات التشغيل لكل محطة',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 20),
                    ...stations.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          SizedBox(
                              width: 120,
                              child: Row(children: [
                                Icon(s.icon, color: s.color, size: 14),
                                const SizedBox(width: 6),
                                Flexible(
                                    child: Text(s.name.replaceAll('محطة ', ''),
                                        style: GoogleFonts.cairo(
                                            color: Colors.grey[400],
                                            fontSize: 11),
                                        overflow: TextOverflow.ellipsis))
                              ])),
                          Expanded(
                              child: Column(children: [
                            Row(children: [
                              Expanded(
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                          value: s.generatorHours / 168,
                                          backgroundColor: Colors.grey[800],
                                          color: const Color(0xFFFFA726),
                                          minHeight: 8))),
                              const SizedBox(width: 8),
                              Text('${s.generatorHours}h',
                                  style: GoogleFonts.cairo(
                                      color: const Color(0xFFFFA726),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              Expanded(
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                          value: s.heaterHours / 168,
                                          backgroundColor: Colors.grey[800],
                                          color: const Color(0xFFEF5350),
                                          minHeight: 8))),
                              const SizedBox(width: 8),
                              Text('${s.heaterHours}h',
                                  style: GoogleFonts.cairo(
                                      color: const Color(0xFFEF5350),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ]),
                          ])),
                        ]))),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _legendDot('مولّد', const Color(0xFFFFA726)),
                      const SizedBox(width: 20),
                      _legendDot('تدفئة', const Color(0xFFEF5350)),
                    ]),
                  ])),
          const SizedBox(height: 24),
        ]));
  }

  // ===== تاب المقارنة =====
  Widget _comparisonTab(
      FuelProvider prov, NumberFormat fmt, List<StationInfo> stations) {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // رادار المقارنة
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D3748))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مقارنة شاملة بين المحطات',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text('ترتيب المحطات حسب الأداء والكفاءة',
                        style: GoogleFonts.cairo(
                            color: Colors.grey[500], fontSize: 11)),
                    const SizedBox(height: 20),
                    // أفضل وأسوأ
                    Row(children: [
                      Expanded(
                          child: _rankCard(
                              'الأعلى استهلاكاً',
                              stations.reduce((a, b) =>
                                  a.dailyConsumption > b.dailyConsumption
                                      ? a
                                      : b),
                              fmt,
                              const Color(0xFFEF5350))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _rankCard(
                              'الأقل استهلاكاً',
                              stations.reduce((a, b) =>
                                  a.dailyConsumption < b.dailyConsumption
                                      ? a
                                      : b),
                              fmt,
                              const Color(0xFF10B981))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _rankCard(
                              'الأكثر مزارع',
                              stations.reduce((a, b) =>
                                  a.totalFarms > b.totalFarms ? a : b),
                              fmt,
                              const Color(0xFF42A5F5))),
                    ]),
                  ])),
          const SizedBox(height: 16),

          // ترتيب المحطات
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
                    Icon(Icons.leaderboard, color: AppColors.getAccent(context), size: 18),
                    const SizedBox(width: 8),
                    Text('ترتيب المحطات حسب الاستهلاك',
                        style: GoogleFonts.cairo(
                            color: AppColors.getAccent(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ])),
              ...List.generate(stations.length, (i) {
                final sorted = List<StationInfo>.from(stations)
                  ..sort((a, b) =>
                      b.dailyConsumption.compareTo(a.dailyConsumption));
                final s = sorted[i];
                final maxConsumption = sorted.first.dailyConsumption;
                return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.grey[800]!, width: 0.5))),
                    child: Row(children: [
                      // ترتيب
                      Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: i == 0
                                  ? const Color(0xFFFFD700).withOpacity(0.15)
                                  : i == 1
                                      ? const Color(0xFFC0C0C0)
                                          .withOpacity(0.15)
                                      : i == 2
                                          ? const Color(0xFFCD7F32)
                                              .withOpacity(0.15)
                                          : Colors.grey[800],
                              borderRadius: BorderRadius.circular(8)),
                          child: Center(
                              child: Text('${i + 1}',
                                  style: GoogleFonts.cairo(
                                      color: i == 0
                                          ? const Color(0xFFFFD700)
                                          : i == 1
                                              ? const Color(0xFFC0C0C0)
                                              : i == 2
                                                  ? const Color(0xFFCD7F32)
                                                  : Colors.grey[500],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)))),
                      const SizedBox(width: 12),
                      Icon(s.icon, color: s.color, size: 20),
                      const SizedBox(width: 8),
                      SizedBox(
                          width: 120,
                          child: Text(s.name,
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                  value: s.dailyConsumption /
                                      max(1, maxConsumption),
                                  backgroundColor: Colors.grey[800],
                                  color: s.color,
                                  minHeight: 10))),
                      const SizedBox(width: 12),
                      Text('${fmt.format(s.dailyConsumption)} لتر',
                          style: GoogleFonts.cairo(
                              color: s.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ]));
              }),
            ]),
          ),
          const SizedBox(height: 24),
        ]));
  }

  // ===== الأدوات =====
  Widget _quickStat(String label, String value, IconData icon, Color color) =>
      Expanded(
          child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.15))),
              child: Row(children: [
                Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color, size: 16)),
                const SizedBox(width: 8),
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
                    ]))
              ])));

  Widget _miniKPI(String label, String value, Color color) => Expanded(
          child: Column(children: [
        Text(value,
            style: GoogleFonts.cairo(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 9)),
      ]));

  Widget _opBadge(String label, String value, IconData icon, Color color) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Row(children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text('$label: $value',
                style: GoogleFonts.cairo(
                    color: color, fontSize: 9, fontWeight: FontWeight.bold))
          ]));

  Widget _opStatCard(
          String title, String value, IconData icon, Color color, String sub) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.15))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(title,
                style:
                    GoogleFonts.cairo(color: Colors.grey[400], fontSize: 11)),
            Text(sub,
                style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 9)),
          ]));

  Widget _rankCard(
          String label, StationInfo s, NumberFormat fmt, Color color) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Column(children: [
            Text(label, style: GoogleFonts.cairo(color: color, fontSize: 11)),
            const SizedBox(height: 6),
            Icon(s.icon, color: s.color, size: 24),
            Text(s.name.replaceAll('محطة ', ''),
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text('${fmt.format(s.dailyConsumption)} لتر/يوم',
                style:
                    GoogleFonts.cairo(color: Colors.grey[400], fontSize: 10)),
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

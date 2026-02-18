import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../constants/app_colors.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';
import '../models/report_models.dart';

/// صفحة التقارير - النسخة المطورة
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedReportType = 'يومي';
  String _selectedStation = 'الكل';

  // بيانات التقرير

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer2<FuelProvider, ThemeProvider>(
        builder: (context, provider, themeProvider, _) {
      final fmt = NumberFormat('#,###', 'ar');
      final totalExpense =
          provider.fuelExpenses.fold<int>(0, (s, r) => s + r.expense);
      final totalPurchase =
          provider.fuelExpenses.fold<int>(0, (s, r) => s + r.purchase);
      final totalCurrent =
          provider.fuelExpenses.fold<int>(0, (s, r) => s + r.currentBalance);

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
                  Text('التقارير',
                      style: GoogleFonts.cairo(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('تقارير استهلاك ومصروف الوقود',
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: Colors.grey[500])),
                ]),
                Row(children: [
                  _reportTypeSelector(),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: const Color(0xFF252830),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.download, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text('تصدير التقرير',
                          style: GoogleFonts.cairo(
                              color: Colors.white, fontSize: 13)),
                    ]),
                  ),
                ]),
              ]),
              const SizedBox(height: 24),

              // ===== بطاقات الملخص =====
              Row(children: [
                _statCard('الرصيد الحالي', fmt.format(totalCurrent), 'لتر',
                    AppColors.getAccent(context), Icons.account_balance_wallet),
                const SizedBox(width: 16),
                _statCard('إجمالي المصروف', fmt.format(totalExpense), 'لتر',
                    AppColors.getError(context), Icons.trending_down),
                const SizedBox(width: 16),
                _statCard('إجمالي المشتريات', fmt.format(totalPurchase), 'لتر',
                    const Color(0xFF3B82F6), Icons.shopping_cart),
                const SizedBox(width: 16),
                _statCard('عدد المحطات', '${provider.stationReports.length}',
                    'محطة', const Color(0xFF8B5CF6), Icons.location_city),
              ]),
              const SizedBox(height: 24),

              // ===== جدول مصروف الوقود =====
              Container(
                decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D3748))),
                child: Column(children: [
                  // عنوان + هيدر برتقالي
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.getOrange(context).withOpacity(0.9),
                        AppColors.getOrange(context).withOpacity(0.7)
                      ]),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('مصروف الوقود',
                              style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text(DateFormat('d/M/yyyy').format(DateTime.now()),
                              style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ]),
                  ),
                  // رأس الجدول
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    color: const Color(0xFF0D1B2A),
                    child: Row(children: [
                      _th('النوع', 1),
                      _th('الرصيد السابق', 2),
                      _th('المصروف', 2),
                      _th('مبيعات', 1),
                      _th('شراء', 2),
                      _th('الرصيد الحالي', 2),
                      _th('معدل السعر د.ع', 2),
                    ]),
                  ),
                  // الصفوف
                  ...provider.fuelExpenses
                      .asMap()
                      .entries
                      .map((e) => _expenseRow(e.value, e.key, fmt)),
                  // إجمالي
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                        color: AppColors.getAccent(context).withOpacity(0.08),
                        border: Border(
                            top: BorderSide(
                                color: AppColors.getAccent(context).withOpacity(0.3)))),
                    child: Row(children: [
                      Expanded(
                          flex: 1,
                          child: Text('الإجمالي',
                              style: GoogleFonts.cairo(
                                  color: AppColors.getAccent(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      Expanded(
                          flex: 2,
                          child: Text(
                              fmt.format(provider.fuelExpenses
                                  .fold<int>(0, (s, r) => s + r.prevBalance)),
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      Expanded(
                          flex: 2,
                          child: Text(fmt.format(totalExpense),
                              style: GoogleFonts.cairo(
                                  color: AppColors.getError(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      Expanded(
                          flex: 1,
                          child: Text(
                              fmt.format(provider.fuelExpenses
                                  .fold<int>(0, (s, r) => s + r.sales)),
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[400], fontSize: 13),
                              textAlign: TextAlign.center)),
                      Expanded(
                          flex: 2,
                          child: Text(fmt.format(totalPurchase),
                              style: GoogleFonts.cairo(
                                  color: const Color(0xFF3B82F6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      Expanded(
                          flex: 2,
                          child: Text(fmt.format(totalCurrent),
                              style: GoogleFonts.cairo(
                                  color: AppColors.getAccent(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      const Expanded(flex: 2, child: SizedBox()),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // ===== الرسوم البيانية =====
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // استهلاك حسب النوع
                Expanded(
                    flex: 3,
                    child: Container(
                      height: 320,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2D3748))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الاستهلاك حسب النوع',
                                style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 16),
                            Expanded(
                                child: _buildFuelTypeChart(
                                    fmt, provider.fuelExpenses)),
                          ]),
                    )),
                const SizedBox(width: 16),
                // كفاءة المحطات
                Expanded(
                    flex: 2,
                    child: Container(
                      height: 320,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2D3748))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('كفاءة المحطات',
                                style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 16),
                            Expanded(
                                child: _buildEfficiencyChart(
                                    provider.stationReports)),
                          ]),
                    )),
              ]),
              const SizedBox(height: 24),

              // ===== تقرير المحطات =====
              Container(
                decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D3748))),
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(children: [
                        Text('تقرير المحطات',
                            style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: const Color(0xFF252830),
                              borderRadius: BorderRadius.circular(8)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStation,
                              dropdownColor: const Color(0xFF252830),
                              style: GoogleFonts.cairo(
                                  color: Colors.white, fontSize: 12),
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                              items: [
                                'الكل',
                                ...provider.stationReports.map((s) => s.name)
                              ]
                                  .map((s) => DropdownMenuItem<String>(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedStation = v!),
                            ),
                          ),
                        ),
                      ])),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    color: const Color(0xFF0D1B2A),
                    child: Row(children: [
                      _th('المحطة', 3),
                      _th('الاستهلاك (لتر)', 2),
                      _th('الرصيد (لتر)', 3),
                      _th('الكفاءة', 2),
                    ]),
                  ),
                  ...(_selectedStation == 'الكل'
                          ? provider.stationReports
                          : provider.stationReports
                              .where((s) => s.name == _selectedStation))
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => _stationRow(e.value, e.key, fmt)),
                ]),
              ),
            ]),
          ),
        ),
      );
    });
  }

  Widget _statCard(
      String title, String value, String unit, Color color, IconData icon) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 12),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Row(children: [
          Text(title,
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(width: 4),
          Text(unit,
              style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey[700])),
        ]),
      ]),
    ));
  }

  Widget _th(String t, int flex) => Expanded(
      flex: flex,
      child: Text(t,
          style: GoogleFonts.cairo(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 12),
          textAlign: TextAlign.center));

  Widget _expenseRow(ReportRow r, int idx, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      color: idx % 2 == 0
          ? Colors.transparent
          : const Color(0xFF0D1B2A).withOpacity(0.3),
      child: Row(children: [
        Expanded(
            flex: 1,
            child: Center(
                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: _fuelColor(r.type).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(r.type,
                  style: GoogleFonts.cairo(
                      color: _fuelColor(r.type),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ))),
        Expanded(
            flex: 2,
            child: Text(fmt.format(r.prevBalance),
                style: GoogleFonts.cairo(color: Colors.grey[300], fontSize: 13),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text(fmt.format(r.expense),
                style: GoogleFonts.cairo(
                    color: AppColors.getError(context),
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 1,
            child: Text(r.sales > 0 ? fmt.format(r.sales) : '-',
                style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text(fmt.format(r.purchase),
                style: GoogleFonts.cairo(
                    color: const Color(0xFF3B82F6), fontSize: 13),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text(fmt.format(r.currentBalance),
                style: GoogleFonts.cairo(
                    color: AppColors.getAccent(context),
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text(fmt.format(r.avgPrice),
                style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _stationRow(StationReport s, int idx, NumberFormat fmt) {
    final effColor = s.efficiency > 93
        ? const Color(0xFF10B981)
        : s.efficiency > 90
            ? AppColors.getAccent(context)
            : AppColors.getWarning(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      color: idx % 2 == 0
          ? Colors.transparent
          : const Color(0xFF0D1B2A).withOpacity(0.3),
      child: Row(children: [
        Expanded(
            flex: 3,
            child: Text(s.name,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text(fmt.format(s.consumed),
                style: GoogleFonts.cairo(color: AppColors.getError(context), fontSize: 13),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 3,
            child: Text(fmt.format(s.balance),
                style: GoogleFonts.cairo(color: AppColors.getAccent(context), fontSize: 13),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Center(
                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: effColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('${s.efficiency}%',
                  style: GoogleFonts.cairo(
                      color: effColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ))),
      ]),
    );
  }

  Widget _buildFuelTypeChart(NumberFormat fmt, List<ReportRow> expenses) {
    final colors = [
      AppColors.getAccent(context),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6)
    ];
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 250000,
      gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: const Color(0xFF2D3748), strokeWidth: 0.5)),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final types = expenses.map((e) => e.type).toList();
                  if (v.toInt() >= 0 && v.toInt() < types.length) {
                    return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(types[v.toInt()],
                            style: GoogleFonts.cairo(
                                color: Colors.grey[500], fontSize: 10)));
                  }
                  return const SizedBox();
                })),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (v, _) => Text(
                    '${(v / 1000).toStringAsFixed(0)}K',
                    style: TextStyle(color: Colors.grey[600], fontSize: 9)))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: expenses
          .asMap()
          .entries
          .map((e) => BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                    toY: e.value.expense.toDouble(),
                    color: colors[e.key % colors.length],
                    width: 28,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6))),
              ]))
          .toList(),
    ));
  }

  Widget _buildEfficiencyChart(List<StationReport> stations) {
    return Column(
        children: stations.map<Widget>((s) {
      final color = s.efficiency > 93
          ? const Color(0xFF10B981)
          : s.efficiency > 90
              ? AppColors.getAccent(context)
              : AppColors.getWarning(context);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          SizedBox(
              width: 80,
              child: Text(s.name.replaceAll('محطة ', ''),
                  style:
                      GoogleFonts.cairo(color: Colors.grey[400], fontSize: 10),
                  overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(children: [
                    Container(height: 8, color: const Color(0xFF2D3748)),
                    FractionallySizedBox(
                        widthFactor: s.efficiency / 100,
                        child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4)))),
                  ]))),
          const SizedBox(width: 8),
          Text('${s.efficiency}%',
              style: GoogleFonts.cairo(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      );
    }).toList());
  }

  Widget _reportTypeSelector() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: AppColors.getSurfaceVariant(context),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
            children: ['يومي', 'أسبوعي', 'شهري']
                .map((p) => GestureDetector(
                      onTap: () => setState(() => _selectedReportType = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                            color: _selectedReportType == p
                                ? AppColors.getAccent(context).withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(p,
                            style: GoogleFonts.cairo(
                                color: _selectedReportType == p
                                    ? AppColors.getAccent(context)
                                    : Colors.grey[500],
                                fontSize: 11,
                                fontWeight: _selectedReportType == p
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    ))
                .toList()),
      );

  Color _fuelColor(String type) {
    switch (type) {
      case 'كاز':
        return AppColors.getAccent(context);
      case 'بنزين':
        return const Color(0xFFF59E0B);
      case 'ديزل':
        return const Color(0xFF3B82F6);
      case 'نفط أبيض':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }
}

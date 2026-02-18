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
import '../models/union_transaction.dart';

/// صفحة رصيد الاتحاد - النسخة المطورة
class UnionBalancePage extends StatefulWidget {
  const UnionBalancePage({super.key});

  @override
  State<UnionBalancePage> createState() => _UnionBalancePageState();
}

class _UnionBalancePageState extends State<UnionBalancePage> {
  String _selectedFilter = 'الكل';
  String _selectedPeriod = 'أسبوع';

  // getter for filtered transactions
  List<UnionTransaction> _getFilteredTx(List<UnionTransaction> all) =>
      _selectedFilter == 'الكل'
          ? all
          : all.where((t) => t.type == _selectedFilter).toList();

  @override
  Widget build(BuildContext context) {
    return Consumer2<FuelProvider, ThemeProvider>(
        builder: (context, provider, themeProvider, _) {
      final fmt = NumberFormat('#,###', 'ar');
      final filteredTx = _getFilteredTx(provider.unionTransactions);
      final totalIn = provider.unionTransactions
          .where((t) => t.type == 'استلام')
          .fold<double>(0, (s, t) => s + t.amount);
      final totalOut = provider.unionTransactions
          .where((t) => t.type == 'تحويل')
          .fold<double>(0, (s, t) => s + t.amount);

      return Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                Color(0xFF0D1B2A),
                AppColors.getDialogBg(context),
                Color(0xFF0F2847)
              ])),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ===== الهيدر =====
              _buildHeader(),
              const SizedBox(height: 24),

              // ===== بطاقات الملخص =====
              _buildSummaryCards(provider, fmt, totalIn, totalOut),
              const SizedBox(height: 24),

              // ===== الرسوم البيانية =====
              _buildChartsRow(provider),
              const SizedBox(height: 24),

              // ===== جدول التحويلات =====
              _buildTransactionsTable(filteredTx, fmt),
            ]),
          ),
        ),
      );
    });
  }

  // ===== الهيدر =====
  Widget _buildHeader() {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('رصيد الاتحاد',
              style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text('إدارة ومتابعة التحويلات',
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[500])),
        ]),
      ),
      _periodSelector(),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: AppColors.getSurfaceVariant(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getCardOrange(context).withOpacity(0.2))),
        child: Row(children: [
          Icon(Icons.calendar_today, color: AppColors.getCardOrange(context), size: 16),
          const SizedBox(width: 8),
          Text(DateFormat('d MMMM yyyy', 'ar').format(DateTime.now()),
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.white)),
        ]),
      ),
    ]);
  }

  // ===== بطاقات الملخص =====
  Widget _buildSummaryCards(FuelProvider provider, NumberFormat fmt,
      double totalIn, double totalOut) {
    return LayoutBuilder(builder: (context, constraints) {
      // إذا الشاشة ضيقة نعرض صفين
      if (constraints.maxWidth < 900) {
        return Column(children: [
          Row(children: [
            _card(
                'الرصيد الحالي',
                fmt.format(provider.unionBalance),
                'لتر',
                AppColors.getCardOrange(context),
                Icons.account_balance_wallet,
                '${provider.unionChangePercent >= 0 ? "+" : ""}${provider.unionChangePercent}%'),
            const SizedBox(width: 12),
            _card('المستلم هذا الشهر', fmt.format(totalIn), 'لتر',
                const Color(0xFF3B82F6), Icons.arrow_downward, '+12%'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _card('المحول للمحطات', fmt.format(totalOut), 'لتر',
                const Color(0xFFF59E0B), Icons.arrow_upward, '+8%'),
            const SizedBox(width: 12),
            _card('صافي الحركة', fmt.format(totalIn - totalOut), 'لتر',
                const Color(0xFF8B5CF6), Icons.swap_vert, ''),
          ]),
        ]);
      }
      // الشاشة عريضة - صف واحد
      return Row(children: [
        _card(
            'الرصيد الحالي',
            fmt.format(provider.unionBalance),
            'لتر',
            AppColors.getCardOrange(context),
            Icons.account_balance_wallet,
            '${provider.unionChangePercent >= 0 ? "+" : ""}${provider.unionChangePercent}%'),
        const SizedBox(width: 16),
        _card('المستلم هذا الشهر', fmt.format(totalIn), 'لتر',
            const Color(0xFF3B82F6), Icons.arrow_downward, '+12%'),
        const SizedBox(width: 16),
        _card('المحول للمحطات', fmt.format(totalOut), 'لتر',
            const Color(0xFFF59E0B), Icons.arrow_upward, '+8%'),
        const SizedBox(width: 16),
        _card('صافي الحركة', fmt.format(totalIn - totalOut), 'لتر',
            const Color(0xFF8B5CF6), Icons.swap_vert, ''),
      ]);
    });
  }

  // ===== الرسوم البيانية =====
  Widget _buildChartsRow(FuelProvider provider) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 800) {
        return Column(children: [
          _chartContainer(
              'حركة الرصيد',
              [
                _legendDot('المستلم', const Color(0xFF3B82F6)),
                const SizedBox(width: 16),
                _legendDot('المحول', const Color(0xFFF59E0B)),
              ],
              _buildBarChart(provider)),
          const SizedBox(height: 16),
          _chartContainer('توزيع التحويلات', [], _buildPieChart(provider)),
        ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            flex: 3,
            child: _chartContainer(
                'حركة الرصيد',
                [
                  _legendDot('المستلم', const Color(0xFF3B82F6)),
                  const SizedBox(width: 16),
                  _legendDot('المحول', const Color(0xFFF59E0B)),
                ],
                _buildBarChart(provider))),
        const SizedBox(width: 16),
        Expanded(
            flex: 2,
            child: _chartContainer(
                'توزيع التحويلات', [], _buildPieChart(provider))),
      ]);
    });
  }

  // ===== بطاقة ملخص =====
  Widget _card(String title, String amount, String unit, Color color,
      IconData icon, String change) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20)),
          if (change.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: (change.startsWith('+')
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(change,
                  style: GoogleFonts.cairo(
                      color: change.startsWith('+')
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
        ]),
        const SizedBox(height: 14),
        Text(title,
            style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(amount,
                style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(width: 6),
            Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: GoogleFonts.cairo(
                        color: Colors.grey[600], fontSize: 12))),
          ]),
        ),
      ]),
    ));
  }

  // ===== حاوية الرسم البياني =====
  Widget _chartContainer(String title, List<Widget> legend, Widget chart) {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D3748))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (legend.isNotEmpty) Row(children: legend),
        ]),
        const SizedBox(height: 20),
        Expanded(child: chart),
      ]),
    );
  }

  // ===== رسم بياني أعمدة - مع حساب maxY الصحيح =====
  Widget _buildBarChart(FuelProvider provider) {
    final days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
    final received = provider.weeklyUnionReceived;
    final transferred = provider.weeklyUnionTransferred;

    // حساب maxY ديناميكياً من البيانات الفعلية
    final allValues = [...received, ...transferred];
    final dataMax = allValues.isEmpty ? 100.0 : allValues.reduce(max);
    // ضمان ألا يكون صفر + إضافة هامش 20%
    final chartMax = dataMax <= 0 ? 100000.0 : (dataMax * 1.2);

    // تحديد تنسيق المحور Y
    String formatY(double v) {
      if (chartMax >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (chartMax >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
      return v.toStringAsFixed(0);
    }

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: chartMax,
      minY: 0,
      gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 5,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: const Color(0xFF2D3748), strokeWidth: 0.5)),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(days[v.toInt() % 7],
                        style: GoogleFonts.cairo(
                            color: Colors.grey[600], fontSize: 10))))),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: chartMax / 5,
                getTitlesWidget: (v, _) => Text(formatY(v),
                    style: TextStyle(color: Colors.grey[600], fontSize: 9)))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 10,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final label = rodIndex == 0 ? 'مستلم' : 'محوّل';
            return BarTooltipItem(
                '$label\n${NumberFormat('#,###').format(rod.toY.toInt())} لتر',
                GoogleFonts.cairo(
                    color: rod.color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold));
          },
        ),
      ),
      barGroups: List.generate(
          7,
          (i) => BarChartGroupData(x: i, barsSpace: 6, barRods: [
                BarChartRodData(
                    toY: received[i],
                    color: const Color(0xFF3B82F6),
                    width: 16,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                    backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: chartMax,
                        color: const Color(0xFF3B82F6).withOpacity(0.04))),
                BarChartRodData(
                    toY: transferred[i],
                    color: const Color(0xFFF59E0B),
                    width: 16,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                    backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: chartMax,
                        color: const Color(0xFFF59E0B).withOpacity(0.04))),
              ])),
    ));
  }

  // ===== رسم دائري =====
  Widget _buildPieChart(FuelProvider provider) {
    final Map<String, double> dist = {};
    for (var t in provider.unionTransactions.where((t) => t.type == 'تحويل')) {
      dist[t.target] = (dist[t.target] ?? 0) + t.amount;
    }
    final total = dist.values.fold<double>(0, (s, v) => s + v);
    final colors = [
      AppColors.getAccent(context),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFFFF7043)
    ];
    final entries = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty || total == 0) {
      return Center(
          child: Text('لا توجد تحويلات',
              style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 14)));
    }

    return Column(children: [
      Expanded(
          child: PieChart(PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 35,
              sections: entries.asMap().entries.map((e) {
                final pct = (e.value.value / total * 100).round();
                return PieChartSectionData(
                    color: colors[e.key % colors.length],
                    value: e.value.value,
                    title: '$pct%',
                    radius: 35,
                    titleStyle: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold));
              }).toList()))),
      const SizedBox(height: 14),
      ...entries.take(5).toList().asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: colors[e.key % colors.length],
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(e.value.key,
                      style: GoogleFonts.cairo(
                          color: Colors.grey[400], fontSize: 10),
                      overflow: TextOverflow.ellipsis)),
              Text('${(e.value.value / total * 100).round()}%',
                  style: GoogleFonts.cairo(
                      color: colors[e.key % colors.length],
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ]),
          )),
    ]);
  }

  // ===== جدول التحويلات =====
  Widget _buildTransactionsTable(
      List<UnionTransaction> filteredTx, NumberFormat fmt) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D3748))),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Text('سجل التحويلات',
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Spacer(),
              ...['الكل', 'استلام', 'تحويل'].map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: _selectedFilter == f
                              ? AppColors.getCardOrange(context).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _selectedFilter == f
                                  ? AppColors.getCardOrange(context)
                                  : Colors.grey[700]!),
                        ),
                        child: Text(f,
                            style: GoogleFonts.cairo(
                                color: _selectedFilter == f
                                    ? AppColors.getCardOrange(context)
                                    : Colors.grey[500],
                                fontSize: 12,
                                fontWeight: _selectedFilter == f
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    ),
                  )),
            ])),
        // رأس الجدول
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              border: Border.symmetric(
                  horizontal: BorderSide(color: Colors.grey[800]!))),
          child: Row(children: [
            _thCell('التاريخ', 2),
            _thCell('الوقت', 1),
            _thCell('النوع', 2),
            _thCell('الكمية (لتر)', 2),
            _thCell('من/إلى', 3),
            _thCell('الحالة', 2),
          ]),
        ),
        // الصفوف
        ...filteredTx.asMap().entries.map((e) => _txRow(e.value, e.key)),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('إجمالي: ${filteredTx.length} عملية',
                      style: GoogleFonts.cairo(
                          color: Colors.grey[600], fontSize: 12)),
                  Text(
                      'المجموع: ${fmt.format(filteredTx.fold<double>(0, (s, t) => s + t.amount))} لتر',
                      style: GoogleFonts.cairo(
                          color: AppColors.getCardOrange(context),
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ])),
      ]),
    );
  }

  // ===== أدوات المساعدة =====
  Widget _periodSelector() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: AppColors.getSurfaceVariant(context),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
            children: ['أسبوع', 'شهر', 'سنة']
                .map((p) => GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                            color: _selectedPeriod == p
                                ? AppColors.getCardOrange(context).withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(p,
                            style: GoogleFonts.cairo(
                                color: _selectedPeriod == p
                                    ? AppColors.getCardOrange(context)
                                    : Colors.grey[500],
                                fontSize: 11,
                                fontWeight: _selectedPeriod == p
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    ))
                .toList()),
      );

  Widget _thCell(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text,
          style: GoogleFonts.cairo(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 12),
          textAlign: TextAlign.center));

  Widget _txRow(UnionTransaction t, int idx) {
    final isIn = t.type == 'استلام';
    final tc = isIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      color: idx % 2 == 0
          ? Colors.transparent
          : const Color(0xFF0D1B2A).withOpacity(0.3),
      child: Row(children: [
        Expanded(
            flex: 2,
            child: Text(t.date,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 1,
            child: Text(t.time,
                style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Center(
                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: tc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward,
                    color: tc, size: 12),
                const SizedBox(width: 4),
                Text(t.type,
                    style: GoogleFonts.cairo(
                        color: tc, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ))),
        Expanded(
            flex: 2,
            child: Text(NumberFormat('#,###', 'ar').format(t.amount),
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 3,
            child: Text(t.target,
                style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 12),
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Center(
                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: (t.status == 'مكتمل'
                          ? AppColors.getSuccess(context)
                          : const Color(0xFFF59E0B))
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(t.status,
                  style: GoogleFonts.cairo(
                      color: t.status == 'مكتمل'
                          ? AppColors.getSuccess(context)
                          : const Color(0xFFF59E0B),
                      fontSize: 11)),
            ))),
      ]),
    );
  }

  Widget _legendDot(String label, Color c) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11)),
      ]);
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../constants/app_colors.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';

/// صفحة خزانات الوقود - النسخة المطورة
class TanksPage extends StatefulWidget {
  const TanksPage({super.key});

  @override
  State<TanksPage> createState() => _TanksPageState();
}

class _TanksPageState extends State<TanksPage>
    with SingleTickerProviderStateMixin {
  String _filterStatus = 'الكل';
  Tank? _selectedTank;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FuelProvider, ThemeProvider>(
        builder: (context, provider, themeProvider, _) {
      final tanks = provider.tanks;
      final filteredTanks = _filterStatus == 'الكل'
          ? tanks
          : tanks.where((t) => t.status.arabicName == _filterStatus).toList();
      final fmt = NumberFormat('#,###', 'ar');
      final lowTanks = tanks.where((t) => t.status == TankStatus.low).length;
      final medTanks = tanks.where((t) => t.status == TankStatus.medium).length;

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
                  Text('خزانات الوقود',
                      style: GoogleFonts.cairo(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('مراقبة مستويات الخزانات في جميع المحطات',
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: Colors.grey[500])),
                ]),
                if (lowTanks > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: AppColors.getError(context).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.getError(context).withOpacity(0.3))),
                    child: Row(children: [
                      Icon(Icons.warning_amber,
                          color: AppColors.getError(context), size: 18),
                      const SizedBox(width: 8),
                      Text('$lowTanks خزان بمستوى منخفض',
                          style: GoogleFonts.cairo(
                              color: AppColors.getError(context),
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 24),

              // ===== ملخص سريع =====
              Row(children: [
                _summaryCard('إجمالي الخزانات', '${tanks.length}',
                    Icons.storage, AppColors.getAccent(context)),
                const SizedBox(width: 16),
                _summaryCard(
                    'خزانات ممتازة',
                    '${tanks.where((t) => t.status == TankStatus.excellent).length}',
                    Icons.verified,
                    const Color(0xFF10B981)),
                const SizedBox(width: 16),
                _summaryCard('خزانات متوسطة', '$medTanks', Icons.info_outline,
                    AppColors.getWarning(context)),
                const SizedBox(width: 16),
                _summaryCard('خزانات منخفضة', '$lowTanks', Icons.error_outline,
                    AppColors.getError(context)),
                const SizedBox(width: 16),
                _summaryCard(
                    'إجمالي السعة',
                    '${fmt.format(provider.totalTankCapacity)} لتر',
                    Icons.water,
                    const Color(0xFF8B5CF6)),
              ]),
              const SizedBox(height: 24),

              // ===== فلاتر الحالة =====
              Row(children: [
                Text('فلتر الحالة:',
                    style: GoogleFonts.cairo(
                        color: Colors.grey[500], fontSize: 13)),
                const SizedBox(width: 12),
                ...['الكل', 'ممتاز', 'جيد', 'متوسط', 'منخفض']
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filterStatus = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _filterStatus == s
                                    ? _statusColor(s).withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _filterStatus == s
                                        ? _statusColor(s)
                                        : Colors.grey[700]!),
                              ),
                              child: Text(s,
                                  style: GoogleFonts.cairo(
                                      color: _filterStatus == s
                                          ? _statusColor(s)
                                          : Colors.grey[500],
                                      fontSize: 12,
                                      fontWeight: _filterStatus == s
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                            ),
                          ),
                        )),
              ]),
              const SizedBox(height: 24),

              // ===== شريط المستوى الكلي =====
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D3748))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('المستوى الكلي للمخزون',
                                style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            Text(
                                '${provider.overallFillPercentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.cairo(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _getOverallColor(
                                        provider.overallFillPercentage))),
                          ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedBuilder(
                            animation: _animController,
                            builder: (_, __) {
                              final pct = provider.overallFillPercentage /
                                  100 *
                                  _animController.value;
                              return Stack(children: [
                                Container(
                                    height: 16, color: const Color(0xFF2D3748)),
                                FractionallySizedBox(
                                    widthFactor: pct.clamp(0, 1),
                                    child: Container(
                                        height: 16,
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [
                                          _getOverallColor(
                                              provider.overallFillPercentage),
                                          _getOverallColor(provider
                                                  .overallFillPercentage)
                                              .withOpacity(0.7)
                                        ])))),
                              ]);
                            }),
                      ),
                      const SizedBox(height: 8),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${fmt.format(provider.totalCurrentStock)} لتر',
                                style: GoogleFonts.cairo(
                                    color: Colors.grey[400], fontSize: 12)),
                            Text(
                                'من ${fmt.format(provider.totalTankCapacity)} لتر',
                                style: GoogleFonts.cairo(
                                    color: Colors.grey[600], fontSize: 12)),
                          ]),
                    ]),
              ),
              const SizedBox(height: 24),

              // ===== بطاقات الخزانات =====
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 1200
                        ? 4
                        : MediaQuery.of(context).size.width > 800
                            ? 3
                            : 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0),
                itemCount: filteredTanks.length,
                itemBuilder: (context, i) => _tankCard(filteredTanks[i], fmt),
              ),

              // ===== تفاصيل الخزان المحدد =====
              if (_selectedTank != null) ...[
                const SizedBox(height: 24),
                _tankDetails(_selectedTank!, fmt),
              ],
            ]),
          ),
        ),
      );
    });
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 10),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(title,
            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[500])),
      ]),
    ));
  }

  Widget _tankCard(Tank tank, NumberFormat fmt) {
    final pct = (tank.current / tank.capacity * 100);
    final color = _getTankColor(tank.status);
    final isSelected = _selectedTank?.name == tank.name;

    return GestureDetector(
      onTap: () => setState(() => _selectedTank = isSelected ? null : tank),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? color : const Color(0xFF2D3748),
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 16)]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // هيدر
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.local_gas_station, color: color, size: 24)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(tank.status.arabicName,
                    style: GoogleFonts.cairo(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 14),
            Text(tank.name,
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(tank.fuelType,
                style:
                    GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600])),
            const Spacer(),

            // مؤشر الخزان البصري
            Container(
              height: 50,
              decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2D3748))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(children: [
                  AnimatedBuilder(
                      animation: _animController,
                      builder: (_, __) => FractionallySizedBox(
                            widthFactor:
                                (pct / 100 * _animController.value).clamp(0, 1),
                            heightFactor: 1,
                            child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                              color.withOpacity(0.8),
                              color.withOpacity(0.4)
                            ]))),
                          )),
                  Center(
                      child: Text('${pct.round()}%',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold))),
                ]),
              ),
            ),
            const SizedBox(height: 10),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(
                  child: Text('${fmt.format(tank.current)} لتر',
                      style:
                          GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis)),
              Text('/ ${fmt.format(tank.capacity)}',
                  style:
                      GoogleFonts.cairo(color: Colors.grey[600], fontSize: 10)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _tankDetails(Tank tank, NumberFormat fmt) {
    final pct = (tank.current / tank.capacity * 100);
    final color = _getTankColor(tank.status);
    final remaining = tank.capacity - tank.current;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.local_gas_station, color: color, size: 28)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(tank.name,
                    style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('${tank.fuelType} • ${tank.status.arabicName}',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: Colors.grey[500])),
              ])),
          IconButton(
              icon: Icon(Icons.close, color: Colors.grey[600]),
              onPressed: () => setState(() => _selectedTank = null)),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          _detailStat('السعة الكلية', '${fmt.format(tank.capacity)} لتر',
              Icons.storage, const Color(0xFF8B5CF6)),
          const SizedBox(width: 16),
          _detailStat('المستوى الحالي', '${fmt.format(tank.current)} لتر',
              Icons.water_drop, color),
          const SizedBox(width: 16),
          _detailStat('المتبقي للامتلاء', '${fmt.format(remaining)} لتر',
              Icons.add_circle_outline, const Color(0xFF3B82F6)),
          const SizedBox(width: 16),
          _detailStat('نسبة الامتلاء', '${pct.toStringAsFixed(1)}%',
              Icons.pie_chart, color),
        ]),
        const SizedBox(height: 24),
        Text('حركة المخزون - آخر 7 أيام',
            style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 16),
        SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: const Color(0xFF2D3748), strokeWidth: 0.5)),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                      7,
                      (i) => FlSpot(i.toDouble(),
                          tank.current * (0.85 + (i * 5 % 3) * 0.05))),
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                          colors: [color.withOpacity(0.3), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter)),
                )
              ],
            ))),
        if (tank.status == TankStatus.low) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.getError(context).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.getError(context).withOpacity(0.2))),
            child: Row(children: [
              Icon(Icons.warning_amber, color: AppColors.getError(context), size: 20),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'تحذير: مستوى الخزان منخفض. يُنصح بإعادة التعبئة في أقرب وقت.',
                      style: GoogleFonts.cairo(
                          color: AppColors.getError(context), fontSize: 13))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _detailStat(String label, String value, IconData icon, Color color) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15))),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.cairo(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        Text(label,
            style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11)),
      ]),
    ));
  }

  Color _getTankColor(TankStatus status) {
    switch (status) {
      case TankStatus.excellent:
        return const Color(0xFF10B981);
      case TankStatus.good:
        return AppColors.getAccent(context);
      case TankStatus.medium:
        return AppColors.getWarning(context);
      case TankStatus.low:
        return AppColors.getError(context);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ممتاز':
        return const Color(0xFF10B981);
      case 'جيد':
        return AppColors.getAccent(context);
      case 'متوسط':
        return AppColors.getWarning(context);
      case 'منخفض':
        return AppColors.getError(context);
      default:
        return Colors.grey;
    }
  }

  Color _getOverallColor(double pct) => pct > 70
      ? const Color(0xFF10B981)
      : pct > 40
          ? AppColors.getWarning(context)
          : AppColors.getError(context);
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  const AnimatedBuilder(
      {super.key, required Animation<double> animation, required this.builder})
      : super(listenable: animation);
  @override
  Widget build(BuildContext context) => builder(context, null);
}

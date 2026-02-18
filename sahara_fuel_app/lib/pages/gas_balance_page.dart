import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../constants/app_colors.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';

class GasBalancePage extends StatefulWidget {
  const GasBalancePage({super.key});

  @override
  State<GasBalancePage> createState() => _GasBalancePageState();
}

class _GasBalancePageState extends State<GasBalancePage> {
  String _selectedPeriod = 'شهري';
  String? _selectedStation;
  DateTime? _selectedDate;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final provider = Provider.of<FuelProvider>(context);
        final formatter = NumberFormat('#,###', 'ar');
        final gasRecords = provider.gasRecords.where((r) {
          if (_searchQuery.isNotEmpty) {
            return r.station.contains(_searchQuery) ||
                r.farm.contains(_searchQuery) ||
                r.operator.contains(_searchQuery);
          }
          if (_selectedStation != null) return r.station == _selectedStation;
          return true;
        }).toList();

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
                  _buildHeader(provider, formatter),
                  const SizedBox(height: 24),
                  _buildStationCards(provider, formatter),
                  const SizedBox(height: 24),
                  _buildColoredStatCards(provider, formatter),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildMainChart(provider)),
                      const SizedBox(width: 20),
                      Expanded(flex: 1, child: _buildTrafficDonut(provider)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildFarmBalances(provider, formatter),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 2,
                          child: _buildDataTable(gasRecords, formatter)),
                      const SizedBox(width: 20),
                      Expanded(
                          flex: 1, child: _buildRecentActivities(provider)),
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

  Widget _buildHeader(FuelProvider provider, NumberFormat formatter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('رصيد الغاز',
              style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text('نظرة عامة على رصيد الغاز للشهر الحالي',
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[500])),
        ]),
        Row(children: [
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(
                          primary: const Color(0xFF00D9A3),
                          surface: AppColors.getDialogBg(context))),
                  child: child!,
                ),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: AppColors.getCardBg(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getAccent(context).withOpacity(0.2))),
              child: Row(children: [
                Icon(Icons.calendar_today, color: AppColors.getAccent(context), size: 16),
                const SizedBox(width: 8),
                Text(
                    _selectedDate != null
                        ? DateFormat('d MMMM yyyy', 'ar').format(_selectedDate!)
                        : DateFormat('d MMMM yyyy', 'ar')
                            .format(DateTime.now()),
                    style:
                        GoogleFonts.cairo(fontSize: 13, color: Colors.white)),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          ...['يومي', 'أسبوعي', 'شهري', 'سنوي'].map((p) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = p),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == p
                          ? AppColors.getAccent(context)
                          : AppColors.getCardBg(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(p,
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: _selectedPeriod == p
                                ? Colors.white
                                : Colors.grey[500],
                            fontWeight: _selectedPeriod == p
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                ),
              )),
        ]),
      ],
    );
  }

  Widget _buildStationCards(FuelProvider provider, NumberFormat formatter) {
    final stationBalances = provider.gasBalanceByStation;
    final stations = provider.stations;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 140,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: stations.length > 6 ? 6 : stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        final balance = stationBalances[station.name] ?? 0;
        final isSelected = _selectedStation == station.name;
        return GestureDetector(
          onTap: () => setState(() => _selectedStation =
              _selectedStation == station.name ? null : station.name),
          child: Card(
            color: AppColors.getCardBg(context),
            elevation: isSelected ? 12 : 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isSelected
                    ? BorderSide(
                        color: station.color.withOpacity(0.6), width: 2)
                    : BorderSide.none),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [
                    station.color.withOpacity(0.12),
                    station.color.withOpacity(0.03)
                  ])),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: station.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.local_fire_department,
                                color: station.color, size: 20),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: (balance >= 0
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFEF5350))
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(
                                '${balance >= 0 ? "+" : ""}${formatter.format(balance)} لتر',
                                style: TextStyle(
                                    color: balance >= 0
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFEF5350),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]),
                    const Spacer(),
                    Text('${formatter.format(balance.abs())} لتر',
                        style: GoogleFonts.cairo(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(station.name,
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.grey[500])),
                  ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColoredStatCards(FuelProvider provider, NumberFormat formatter) {
    final cards = [
      _ColoredCardData(
          'إجمالي الوارد',
          formatter.format(provider.totalGasIncoming),
          'لتر',
          const Color(0xFFE91E63),
          const Color(0xFFFF6090),
          Icons.arrow_downward),
      _ColoredCardData(
          'إجمالي الصادر',
          formatter.format(provider.totalGasOutgoing),
          'لتر',
          const Color(0xFFFF9800),
          const Color(0xFFFFB74D),
          Icons.arrow_upward),
      _ColoredCardData(
          'صافي الرصيد',
          formatter.format(provider.totalGasBalance),
          'لتر',
          const Color(0xFF2196F3),
          const Color(0xFF64B5F6),
          Icons.account_balance_wallet),
      _ColoredCardData(
          'إجمالي التكلفة',
          formatter.format(provider.totalGasCost),
          'د.ع',
          const Color(0xFF9C27B0),
          const Color(0xFFCE93D8),
          Icons.attach_money),
    ];

    return Row(
      children: cards
          .map((card) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                        colors: [card.color1, card.color2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                          color: card.color1.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(card.title,
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9))),
                              Icon(card.icon,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 20),
                            ]),
                        const SizedBox(height: 12),
                        Text(card.value,
                            style: GoogleFonts.cairo(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text(card.unit,
                            style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.7))),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 30,
                          child: _buildMiniSparkline(
                              card.color1 == const Color(0xFFE91E63)
                                  ? provider.gasWeeklyData
                                  : provider.gasWeeklyOutgoing),
                        ),
                      ]),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMiniSparkline(List<double> data) {
    if (data.every((d) => d == 0)) return const SizedBox();
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox();
    return CustomPaint(
      size: const Size(double.infinity, 30),
      painter: _SparklinePainter(data, maxVal),
    );
  }

  Widget _buildMainChart(FuelProvider provider) {
    final incoming = provider.gasWeeklyData;
    final outgoing = provider.gasWeeklyOutgoing;
    final days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];

    return Card(
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Dashboard',
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Row(children: [
              _legendDot(AppColors.getAccent(context), 'الوارد'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFFF6090), 'الصادر'),
            ]),
          ]),
          Text('نظرة عامة على الغاز للشهر الحالي',
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey[800]!, strokeWidth: 0.5)),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          if (v.toInt() >= 0 && v.toInt() < days.length) {
                            return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(days[v.toInt()],
                                    style: GoogleFonts.cairo(
                                        color: Colors.grey[600],
                                        fontSize: 10)));
                          }
                          return const SizedBox();
                        })),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (v, _) => Text(
                            '${(v / 1000).toStringAsFixed(0)}K',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 9)))),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(incoming.length,
                      (i) => FlSpot(i.toDouble(), incoming[i])),
                  isCurved: true,
                  color: AppColors.getAccent(context),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                          colors: [
                            AppColors.getAccent(context).withOpacity(0.3),
                            Colors.transparent
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter)),
                ),
                LineChartBarData(
                  spots: List.generate(outgoing.length,
                      (i) => FlSpot(i.toDouble(), outgoing[i])),
                  isCurved: true,
                  color: const Color(0xFFFF6090),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF6090).withOpacity(0.15),
                            Colors.transparent
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter)),
                ),
              ],
            )),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chartStat(
                  Icons.local_fire_department,
                  'إجمالي الرصيد',
                  FuelProvider.formatNumber(provider.totalGasBalance),
                  AppColors.getAccent(context)),
              _chartStat(
                  Icons.arrow_downward,
                  'الوارد',
                  FuelProvider.formatNumber(provider.totalGasIncoming),
                  const Color(0xFF4CAF50)),
              _chartStat(
                  Icons.arrow_upward,
                  'الصادر',
                  FuelProvider.formatNumber(provider.totalGasOutgoing),
                  const Color(0xFFEF5350)),
              _chartStat(
                  Icons.monetization_on,
                  'التكلفة',
                  FuelProvider.formatNumber(provider.totalGasCost),
                  const Color(0xFFFFA726)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildTrafficDonut(FuelProvider provider) {
    final total = provider.totalGasIncoming + provider.totalGasOutgoing;
    final inPct = total > 0 ? (provider.totalGasIncoming / total * 100) : 50.0;
    final outPct = total > 0 ? (provider.totalGasOutgoing / total * 100) : 50.0;

    return Card(
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text('Traffic',
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                    value: inPct,
                    color: const Color(0xFFE91E63),
                    title: '${inPct.toStringAsFixed(0)}%',
                    titleStyle: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    radius: 35),
                PieChartSectionData(
                    value: outPct,
                    color: const Color(0xFFFF9800),
                    title: '${outPct.toStringAsFixed(0)}%',
                    titleStyle: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    radius: 35),
                PieChartSectionData(
                    value: 12,
                    color: const Color(0xFF9C27B0),
                    title: '12%',
                    titleStyle: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    radius: 35),
              ],
            )),
          ),
          const SizedBox(height: 20),
          _trafficLegend(const Color(0xFFE91E63), 'الوارد',
              '${inPct.toStringAsFixed(0)}%'),
          const SizedBox(height: 8),
          _trafficLegend(const Color(0xFFFF9800), 'الصادر',
              '${outPct.toStringAsFixed(0)}%'),
          const SizedBox(height: 8),
          _trafficLegend(const Color(0xFF9C27B0), 'مخزون', '12%'),
        ]),
      ),
    );
  }

  Widget _buildFarmBalances(FuelProvider provider, NumberFormat formatter) {
    final farmBalances = provider.gasFarmBalances;
    final sortedFarms = farmBalances.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return Card(
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('رصيد المزارع حسب الموقع',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text('${farmBalances.length} مزرعة',
                style:
                    GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500])),
          ]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: sortedFarms.take(12).map((entry) {
              final isPositive = entry.value >= 0;
              return Container(
                width: 200,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isPositive
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFEF5350))
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: (isPositive
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350))
                          .withOpacity(0.2)),
                ),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: (isPositive
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFEF5350))
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFEF5350),
                        size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(entry.key,
                            style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('${formatter.format(entry.value)} لتر',
                            style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: isPositive
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFEF5350),
                                fontWeight: FontWeight.bold)),
                      ])),
                ]),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  Widget _buildDataTable(List<GasRecord> records, NumberFormat formatter) {
    return Card(
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('سجل العمليات',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Row(children: [
              _actionButton(
                  Icons.add, 'إضافة', AppColors.getAccent(context), () => _showAddDialog()),
              const SizedBox(width: 8),
              _actionButton(Icons.file_download, 'تصدير',
                  const Color(0xFF42A5F5), () => _showExportSnackbar()),
              const SizedBox(width: 8),
              Container(
                width: 200,
                height: 38,
                decoration: BoxDecoration(
                    color: AppColors.getSurfaceVariant(context),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'بحث...',
                    hintStyle: GoogleFonts.cairo(
                        color: Colors.grey[600], fontSize: 11),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey[600], size: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.getDialogBg(context)),
                  dataRowColor: WidgetStateProperty.all(Colors.transparent),
                  headingTextStyle: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  dataTextStyle:
                      GoogleFonts.cairo(color: Colors.grey[300], fontSize: 11),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('التاريخ')),
                    DataColumn(label: Text('المحطة')),
                    DataColumn(label: Text('المزرعة')),
                    DataColumn(label: Text('النوع')),
                    DataColumn(label: Text('الكمية')),
                    DataColumn(label: Text('السعر')),
                    DataColumn(label: Text('الإجمالي')),
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('الإجراءات')),
                  ],
                  rows: records.take(10).toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    return DataRow(cells: [
                      DataCell(Text('${i + 1}')),
                      DataCell(
                          Text(DateFormat('d/M/yyyy', 'ar').format(r.date))),
                      DataCell(Text(r.station,
                          style: GoogleFonts.cairo(fontSize: 11))),
                      DataCell(
                          Text(r.farm, style: GoogleFonts.cairo(fontSize: 11))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (r.type == 'وارد'
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFEF5350))
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(r.type,
                            style: TextStyle(
                                color: r.type == 'وارد'
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFEF5350),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      )),
                      DataCell(Text('${formatter.format(r.quantity)} لتر')),
                      DataCell(Text('${formatter.format(r.unitPrice)} د.ع')),
                      DataCell(Text('${formatter.format(r.totalCost)} د.ع')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.getAccent(context).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text('مكتمل',
                            style: TextStyle(
                                color: AppColors.getAccent(context),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      )),
                      DataCell(Row(children: [
                        IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFF42A5F5), size: 16),
                            onPressed: () => _showEditDialog(r)),
                        IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Color(0xFFEF5350), size: 16),
                            onPressed: () => _confirmDelete(r)),
                      ])),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
                'عرض 1 إلى ${records.length > 10 ? 10 : records.length} من ${records.length} سجلات',
                style:
                    GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600])),
            Row(children: [
              _paginationButton('«', false),
              _paginationButton('1', true),
              _paginationButton('2', false),
              _paginationButton('»', false),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _buildRecentActivities(FuelProvider provider) {
    final gasActivities = provider.recentActivities
        .where((a) => a.description.contains('غاز'))
        .take(5)
        .toList();
    final activities = gasActivities.isEmpty
        ? provider.recentActivities.take(5).toList()
        : gasActivities;

    return Card(
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('آخر العمليات',
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 16),
          ...activities.asMap().entries.map((entry) {
            final a = entry.value;
            final color = a.type == ActivityType.incoming
                ? const Color(0xFF4CAF50)
                : a.type == ActivityType.outgoing
                    ? const Color(0xFFEF5350)
                    : const Color(0xFF42A5F5);
            final icon = a.type == ActivityType.incoming
                ? Icons.arrow_downward
                : a.type == ActivityType.outgoing
                    ? Icons.arrow_upward
                    : Icons.swap_horiz;
            final timeAgo = DateTime.now().difference(a.time);
            String timeText;
            if (timeAgo.inMinutes < 60) {
              timeText = '${timeAgo.inMinutes} دقيقة';
            } else if (timeAgo.inHours < 24) {
              timeText = '${timeAgo.inHours} ساعة';
            } else {
              timeText = '${timeAgo.inDays} يوم';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(a.description,
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Text('منذ $timeText',
                          style: GoogleFonts.cairo(
                              fontSize: 9, color: Colors.grey[600])),
                    ])),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  void _showAddDialog() {
    final farmCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '320');
    final operatorCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'وارد';
    final provider = Provider.of<FuelProvider>(context, listen: false);
    String? selectedStation;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.getDialogBg(context),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.getAccent(context).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add, color: Color(0xFF00D9A3))),
              const SizedBox(width: 12),
              Text('إضافة سجل غاز',
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ]),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(
                      children: ['وارد', 'صرف']
                          .map((t) => Expanded(
                                  child: GestureDetector(
                                onTap: () => setDialogState(() => type = t),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: type == t
                                        ? (t == 'وارد'
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFEF5350))
                                            .withOpacity(0.2)
                                        : AppColors.getSurfaceVariant(context),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: type == t
                                            ? (t == 'وارد'
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFEF5350))
                                            : Colors.grey[700]!),
                                  ),
                                  child: Center(
                                      child: Text(t,
                                          style: GoogleFonts.cairo(
                                              color: type == t
                                                  ? Colors.white
                                                  : Colors.grey[500],
                                              fontWeight: FontWeight.bold))),
                                ),
                              )))
                          .toList()),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStation,
                    dropdownColor: AppColors.getDialogBg(context),
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration('المحطة'),
                    items: provider.stations
                        .map((s) => DropdownMenuItem(
                            value: s.name, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedStation = v),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(farmCtrl, 'المزرعة', Icons.grass),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _dialogField(quantityCtrl, 'الكمية (لتر)',
                            Icons.local_fire_department,
                            isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _dialogField(
                            priceCtrl, 'السعر (د.ع)', Icons.attach_money,
                            isNumber: true)),
                  ]),
                  const SizedBox(height: 12),
                  _dialogField(operatorCtrl, 'المشغّل', Icons.person),
                  const SizedBox(height: 12),
                  _dialogField(notesCtrl, 'ملاحظات', Icons.note),
                ]),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('إلغاء',
                      style: GoogleFonts.cairo(color: Colors.grey[500]))),
              ElevatedButton(
                onPressed: () {
                  if (selectedStation == null) return;
                  final qty = double.tryParse(quantityCtrl.text) ?? 0;
                  final price = double.tryParse(priceCtrl.text) ?? 320;
                  if (qty <= 0) return;
                  provider.addGasRecord(
                    station: selectedStation!,
                    farm: farmCtrl.text.isEmpty ? 'عام' : farmCtrl.text,
                    quantity: qty,
                    unitPrice: price,
                    type: type,
                    operator: operatorCtrl.text.isEmpty
                        ? 'النظام'
                        : operatorCtrl.text,
                    notes: notesCtrl.text,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('تم إضافة السجل بنجاح',
                          style: GoogleFonts.cairo()),
                      backgroundColor: AppColors.getAccent(context)));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getAccent(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: Text('حفظ',
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(GasRecord record) {
    final farmCtrl = TextEditingController(text: record.farm);
    final quantityCtrl =
        TextEditingController(text: record.quantity.toString());
    final priceCtrl = TextEditingController(text: record.unitPrice.toString());
    final notesCtrl = TextEditingController(text: record.notes);
    final provider = Provider.of<FuelProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.getDialogBg(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.edit, color: Color(0xFF42A5F5))),
            const SizedBox(width: 12),
            Text('تعديل سجل',
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ]),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dialogField(farmCtrl, 'المزرعة', Icons.grass),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _dialogField(
                        quantityCtrl, 'الكمية', Icons.local_fire_department,
                        isNumber: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _dialogField(priceCtrl, 'السعر', Icons.attach_money,
                        isNumber: true)),
              ]),
              const SizedBox(height: 12),
              _dialogField(notesCtrl, 'ملاحظات', Icons.note),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء',
                    style: GoogleFonts.cairo(color: Colors.grey[500]))),
            ElevatedButton(
              onPressed: () {
                provider.updateGasRecord(
                  record.id,
                  farm: farmCtrl.text,
                  quantity: double.tryParse(quantityCtrl.text),
                  unitPrice: double.tryParse(priceCtrl.text),
                  notes: notesCtrl.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('تم التعديل بنجاح', style: GoogleFonts.cairo()),
                    backgroundColor: const Color(0xFF42A5F5)));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text('حفظ التعديل',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(GasRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.getDialogBg(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تأكيد الحذف',
              style: GoogleFonts.cairo(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
              'هل تريد حذف هذا السجل؟\n${record.station} - ${record.farm} - ${record.quantity} لتر',
              style: GoogleFonts.cairo(color: Colors.grey[400])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء',
                    style: GoogleFonts.cairo(color: Colors.grey[500]))),
            ElevatedButton(
              onPressed: () {
                Provider.of<FuelProvider>(context, listen: false)
                    .deleteGasRecord(record.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('تم الحذف', style: GoogleFonts.cairo()),
                    backgroundColor: const Color(0xFFEF5350)));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text('حذف',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('جاري تصدير البيانات...', style: GoogleFonts.cairo()),
      backgroundColor: const Color(0xFF42A5F5),
      action: SnackBarAction(
          label: 'تم', textColor: Colors.white, onPressed: () {}),
    ));
  }

  Widget _actionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.cairo(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label,
          style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11)),
    ]);
  }

  Widget _chartStat(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 10)),
          Text(value,
              style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _trafficLegend(Color color, String label, String value) {
    return Row(children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Expanded(
          child: Text(label,
              style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 12))),
      Text(value,
          style: GoogleFonts.cairo(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _paginationButton(String text, bool active) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          color: active ? AppColors.getAccent(context) : AppColors.getSurfaceVariant(context),
          borderRadius: BorderRadius.circular(6)),
      child: Center(
          child: Text(text,
              style: TextStyle(
                  color: active ? Colors.white : Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.bold))),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00D9A3))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 18),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[700]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00D9A3))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _ColoredCardData {
  final String title, value, unit;
  final Color color1, color2;
  final IconData icon;
  _ColoredCardData(
      this.title, this.value, this.unit, this.color1, this.color2, this.icon);
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final double maxVal;
  _SparklinePainter(this.data, this.maxVal);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxVal == 0) return;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i] / maxVal) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

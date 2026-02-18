import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../constants/app_colors.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';

class SaharaBalancePage extends StatefulWidget {
  const SaharaBalancePage({super.key});

  @override
  State<SaharaBalancePage> createState() => _SaharaBalancePageState();
}

class _SaharaBalancePageState extends State<SaharaBalancePage> {
  String? selectedFarm;
  String? selectedStation;
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
            child: Row(
              children: [
                // ===== الشريط الجانبي =====
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    border: Border(
                        left: BorderSide(color: Colors.grey[800]!, width: 1)),
                  ),
                  child: Column(
                    children: [
                      // هيدر الشريط
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.getAccent(context).withOpacity(0.15),
                              Colors.transparent
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_city,
                                    color: AppColors.getAccent(context), size: 24),
                                const SizedBox(width: 10),
                                Text('المواقع والمحطات',
                                    style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // حقل البحث
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                  color: AppColors.getSurfaceVariant(context),
                                  borderRadius: BorderRadius.circular(10)),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                style: GoogleFonts.cairo(
                                    color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'بحث عن محطة أو مزرعة...',
                                  hintStyle: GoogleFonts.cairo(
                                      color: Colors.grey[600], fontSize: 12),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey[600], size: 18),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // قائمة المحطات
                      Expanded(
                        child: Builder(builder: (context) {
                          final filteredStations = provider.stations.where((s) {
                            if (_searchQuery.isEmpty) return true;
                            return s.name.contains(_searchQuery) ||
                                s.farms.any((f) => f.contains(_searchQuery));
                          }).toList();
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: filteredStations.length,
                            itemBuilder: (context, index) =>
                                _buildStationTile(filteredStations[index]),
                          );
                        }),
                      ),
                      // إحصائية سريعة
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: AppColors.getSurfaceVariant(context),
                            border: Border(
                                top: BorderSide(color: Colors.grey[800]!))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _miniStat('المحطات', '${provider.stations.length}',
                                AppColors.getAccent(context)),
                            _miniStat('المزارع', '102', AppColors.getCardOrange(context)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== الجزء الرئيسي =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الهيدر
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('رصيد الصحاري',
                                      style: GoogleFonts.cairo(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text(
                                      'إجمالي الرصيد: ${formatter.format(provider.saharaBalance)} لتر',
                                      style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          color: Colors.grey[500])),
                                ]),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                  color: AppColors.getCardBg(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          AppColors.getAccent(context).withOpacity(0.2))),
                              child: Row(children: [
                                Icon(Icons.calendar_today,
                                    color: AppColors.getAccent(context), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                    DateFormat('d MMMM yyyy', 'ar')
                                        .format(DateTime.now()),
                                    style: GoogleFonts.cairo(
                                        fontSize: 13, color: Colors.white)),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // بطاقات المحطات
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            mainAxisExtent: 150,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          itemCount: provider.stations.length,
                          itemBuilder: (context, index) =>
                              _stationCard(provider.stations[index], formatter),
                        ),
                        const SizedBox(height: 30),

                        // تفاصيل المحطة/المزرعة المحددة
                        if (selectedFarm != null)
                          _buildFarmDetails(selectedFarm!, provider),
                        if (selectedFarm == null && selectedStation != null)
                          _buildStationOverview(selectedStation!, provider),
                        if (selectedFarm == null && selectedStation == null)
                          _buildDefaultView(provider),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStationTile(StationInfo station) {
    final isExpanded = selectedStation == station.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isExpanded
            ? AppColors.getAccent(context).withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: station.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(station.icon, color: station.color, size: 18),
        ),
        title: Text(station.name,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${station.farms.length + (station.subStations?.fold(0, (s, sub) => s! + sub.farms.length) ?? 0)} موقع',
            style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 10)),
        iconColor: Colors.grey[500],
        collapsedIconColor: Colors.grey[600],
        onExpansionChanged: (expanded) {
          if (expanded) setState(() => selectedStation = station.name);
        },
        children: [
          ...station.farms.map((f) => _farmTile(f, station.color)),
          if (station.subStations != null)
            ...station.subStations!.map((sub) => ExpansionTile(
                  title: Text(sub.name,
                      style: GoogleFonts.cairo(
                          color: Colors.white70, fontSize: 12)),
                  childrenPadding: const EdgeInsets.only(right: 16),
                  children: sub.farms
                      .map((f) => _farmTile(f, station.color))
                      .toList(),
                )),
        ],
      ),
    );
  }

  Widget _farmTile(String farmName, Color color) {
    final isSelected = selectedFarm == farmName;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(right: 24, left: 8),
      leading: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey[600],
            shape: BoxShape.circle),
      ),
      title: Text(farmName,
          style: GoogleFonts.cairo(
              color: isSelected ? color : Colors.white60,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () => setState(() => selectedFarm = farmName),
    );
  }

  Widget _stationCard(StationInfo station, NumberFormat formatter) {
    final isSelected = selectedStation == station.name;
    return GestureDetector(
      onTap: () => setState(() {
        selectedStation = station.name;
        selectedFarm = null;
      }),
      child: Card(
        color: AppColors.getCardBg(context),
        elevation: isSelected ? 12 : 6,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSelected
                ? BorderSide(color: station.color.withOpacity(0.5), width: 1.5)
                : BorderSide.none),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: [
                station.color.withOpacity(0.12),
                station.color.withOpacity(0.03)
              ])),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: station.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(station.icon, color: station.color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: (station.change >= 0
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFEF5350))
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      station.change >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: station.change >= 0
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFEF5350),
                      size: 12),
                  const SizedBox(width: 3),
                  Text('${station.change >= 0 ? "+" : ""}${station.change}%',
                      style: TextStyle(
                          color: station.change >= 0
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
            const Spacer(),
            Text('${formatter.format(station.balance)} لتر',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(station.name,
                style:
                    GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500])),
          ]),
        ),
      ),
    );
  }

  Widget _buildFarmDetails(String farmName, FuelProvider provider) {
    final consumption =
        List.generate(7, (i) => 4000.0 + i * 500 + (i * 3 % 5) * 200);
    return Card(
      color: AppColors.getCardBg(context),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.getAccent(context)),
                onPressed: () => setState(() => selectedFarm = null)),
            const SizedBox(width: 8),
            Expanded(
                child: Text('تفاصيل $farmName',
                    style: GoogleFonts.cairo(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 24),
          // بطاقات التفاصيل
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _detailCard('ساعات المولدة', '120 ساعة', Icons.electric_bolt,
                  const Color(0xFFFFA726)),
              _detailCard('ساعات الهيتر', '80 ساعة', Icons.thermostat,
                  const Color(0xFFEF5350)),
              _detailCard('رصيد سابق', '50,000 لتر', Icons.history,
                  const Color(0xFF42A5F5)),
              _detailCard('رصيد حالي', '45,000 لتر',
                  Icons.account_balance_wallet, AppColors.getAccent(context)),
              _detailCard('كثافة الكاز', '0.85', Icons.science,
                  const Color(0xFFAB47BC)),
            ],
          ),
          const SizedBox(height: 28),
          Text('الاستهلاك الأسبوعي',
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(BarChartData(
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
                          final days = [
                            'سبت',
                            'أحد',
                            'اثنين',
                            'ثلاثاء',
                            'أربعاء',
                            'خميس',
                            'جمعة'
                          ];
                          return Text(days[v.toInt() % 7],
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[600], fontSize: 10));
                        })),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
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
              barGroups: List.generate(
                  7,
                  (i) => BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                            toY: consumption[i],
                            gradient: LinearGradient(
                                colors: [
                                  AppColors.getAccent(context),
                                  AppColors.getAccent(context).withOpacity(0.6)
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6))),
                      ])),
            )),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _infoChip('وارد من', 'محطة الطاقة', Icons.arrow_downward,
                const Color(0xFF4CAF50)),
            _infoChip('تصدير إلى', 'محطة البوادي', Icons.arrow_upward,
                const Color(0xFFEF5350)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildStationOverview(String stationName, FuelProvider provider) {
    final station = provider.stations.firstWhere((s) => s.name == stationName);
    return Card(
      color: AppColors.getCardBg(context),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: station.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(station.icon, color: station.color, size: 28)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(station.name,
                      style: GoogleFonts.cairo(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text(
                      'عدد المزارع: ${station.farms.length + (station.subStations?.fold(0, (s, sub) => s! + sub.farms.length) ?? 0)}',
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.grey[500])),
                ])),
          ]),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _detailCard(
                  'الرصيد',
                  '${NumberFormat('#,###', 'ar').format(station.balance)} لتر',
                  Icons.account_balance_wallet,
                  station.color),
              _detailCard('ساعات المولدة', '${station.generatorHours} ساعة',
                  Icons.electric_bolt, const Color(0xFFFFA726)),
              _detailCard('ساعات الهيتر', '${station.heaterHours} ساعة',
                  Icons.thermostat, const Color(0xFFEF5350)),
              _detailCard(
                  'التغيير',
                  '${station.change >= 0 ? "+" : ""}${station.change}%',
                  station.change >= 0 ? Icons.trending_up : Icons.trending_down,
                  station.change >= 0
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFEF5350)),
            ],
          ),
          const SizedBox(height: 24),
          Text('الاستهلاك الشهري',
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey[800]!, strokeWidth: 0.5)),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                      12,
                      (i) => FlSpot(
                          i.toDouble(),
                          station.balance / 12 +
                              (i * 7 % 5) * station.balance / 100)),
                  isCurved: true,
                  color: station.color,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                          colors: [
                            station.color.withOpacity(0.3),
                            Colors.transparent
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter)),
                )
              ],
            )),
          ),
        ]),
      ),
    );
  }

  Widget _buildDefaultView(FuelProvider provider) {
    return Card(
      color: AppColors.getCardBg(context),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Icon(Icons.touch_app, color: Colors.grey[700], size: 60),
          const SizedBox(height: 16),
          Text('اختر محطة أو مزرعة لعرض التفاصيل',
              style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('انقر على أي بطاقة أعلاه أو اختر من القائمة الجانبية',
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[700])),
        ]),
      ),
    );
  }

  Widget _detailCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 150, // Fixed width for wrap items
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        Text(label,
            style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11)),
      ]),
    );
  }

  Widget _infoChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[500])),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.cairo(
              fontSize: 18, color: color, fontWeight: FontWeight.bold)),
      Text(label,
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600])),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../constants/app_colors.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});
  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.getPageGradient(context))),
            child: Column(children: [
              // الهيدر + التبويبات
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(children: [
                  Icon(Icons.directions_car, color: AppColors.getAccent(context), size: 28),
                  const SizedBox(width: 12),
                  Text('إدارة العربات',
                      style: GoogleFonts.cairo(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(context))),
                  const Spacer(),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.getDivider(context))),
                    child: TabBar(
                      controller: _tabCtrl,
                      isScrollable: true,
                      dividerHeight: 0,
                      splashBorderRadius: BorderRadius.circular(10),
                      indicator: BoxDecoration(
                          color: AppColors.getAccent(context).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.getAccent(context).withOpacity(0.4))),
                      labelColor: AppColors.getAccent(context),
                      unselectedLabelColor: AppColors.getSubtleText(context),
                      labelStyle: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(
                            icon: Icon(Icons.local_fire_department, size: 16),
                            text: 'كاز'),
                        Tab(
                            icon: Icon(Icons.local_gas_station, size: 16),
                            text: 'بنزين'),
                        Tab(
                            icon: Icon(Icons.propane_tank, size: 16),
                            text: 'غاز'),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              // المحتوى
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: const [
                    _VehicleTabContent(fuelType: 'كاز'),
                    _VehicleTabContent(fuelType: 'بنزين'),
                    _VehicleTabContent(fuelType: 'غاز'),
                  ],
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ===== محتوى كل تبويب =====
class _VehicleTabContent extends StatefulWidget {
  final String fuelType;
  const _VehicleTabContent({required this.fuelType});
  @override
  State<_VehicleTabContent> createState() => _VehicleTabContentState();
}

class _VehicleTabContentState extends State<_VehicleTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String? _typeFilter;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Vehicle> _filterVehicles(List<Vehicle> all) {
    return all.where((v) {
      if (v.fuelType != widget.fuelType) return false;
      if (_searchQuery.isNotEmpty &&
          !v.plateNumber.contains(_searchQuery) &&
          !v.driverName.contains(_searchQuery) &&
          !v.model.contains(_searchQuery)) return false;
      if (_typeFilter != null && v.vehicleType != _typeFilter) return false;
      return true;
    }).toList();
  }

  List<Vehicle> _todayRefueled(List<Vehicle> all) {
    return all
        .where((v) =>
            v.fuelType == widget.fuelType &&
            v.lastRefuel.year == _selectedDate.year &&
            v.lastRefuel.month == _selectedDate.month &&
            v.lastRefuel.day == _selectedDate.day)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<FuelProvider>(
      builder: (context, provider, _) {
        final formatter = NumberFormat('#,###', 'ar');
        final allVehicles = provider.vehicles;
        final filtered = _filterVehicles(allVehicles);
        final todayList = _todayRefueled(allVehicles);
        final activeCount = allVehicles
            .where((v) => v.fuelType == widget.fuelType && v.isActive)
            .length;
        final totalCount =
            allVehicles.where((v) => v.fuelType == widget.fuelType).length;
        final dailyConsumption =
            todayList.fold(0.0, (s, v) => s + v.lastQuantity);
        final top10 = List<Vehicle>.from(todayList)
          ..sort((a, b) => b.lastQuantity.compareTo(a.lastQuantity));

        // أنواع السيارات
        final types = allVehicles
            .where((v) => v.fuelType == widget.fuelType)
            .map((v) => v.vehicleType)
            .toSet()
            .toList();

        // بيانات الرسم البياني
        final weeklyData = List.generate(7, (i) {
          final d = DateTime.now().subtract(Duration(days: 6 - i));
          return allVehicles
              .where((v) =>
                  v.fuelType == widget.fuelType &&
                  v.lastRefuel.year == d.year &&
                  v.lastRefuel.month == d.month &&
                  v.lastRefuel.day == d.day)
              .fold(0.0, (s, v) => s + v.lastQuantity);
        });

        final fuelColor = widget.fuelType == 'كاز'
            ? const Color(0xFFFF6B35)
            : widget.fuelType == 'بنزين'
                ? const Color(0xFF2196F3)
                : const Color(0xFF9C27B0);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ===== شريط التاريخ + الأزرار =====
            _buildActionBar(provider, fuelColor),
            const SizedBox(height: 20),

            // ===== 4 كارتات إحصائية =====
            Row(children: [
              _statCard(
                  'إجمالي التفويلة اليومي',
                  '${formatter.format(dailyConsumption)} لتر',
                  Icons.local_gas_station,
                  fuelColor,
                  '${todayList.length} عملية'),
              _statCard('العربات الشغالة', '$activeCount', Icons.directions_car,
                  const Color(0xFF4CAF50), 'نشطة الآن'),
              _statCard('العربات الكلي', '$totalCount', Icons.garage,
                  const Color(0xFF42A5F5), 'مسجلة'),
              _statCard(
                  'الكمية المستهلكة',
                  '${formatter.format(allVehicles.where((v) => v.fuelType == widget.fuelType).fold(0.0, (s, v) => s + v.totalConsumed))} لتر',
                  Icons.speed,
                  const Color(0xFFFFA726),
                  'إجمالي'),
            ]),
            const SizedBox(height: 20),

            // ===== Dashboard + Top 10 =====
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  flex: 2,
                  child: _buildDashboard(
                      weeklyData, fuelColor, formatter, provider)),
              const SizedBox(width: 16),
              Expanded(
                  flex: 1,
                  child: _buildTop10(
                      top10.take(10).toList(), formatter, fuelColor)),
            ]),
            const SizedBox(height: 20),

            // ===== فلتر أنواع + إحصائية =====
            _buildTypeFilter(types, allVehicles, fuelColor, formatter),
            const SizedBox(height: 20),

            // ===== الجدول =====
            _buildDataTable(filtered, formatter, fuelColor, provider),
          ]),
        );
      },
    );
  }

  // ===== شريط الأزرار =====
  Widget _buildActionBar(FuelProvider provider, Color fuelColor) {
    return Wrap(spacing: 10, runSpacing: 10, children: [
      // تاريخ
      _actionBtn(
          Icons.calendar_today,
          DateFormat('d/M/yyyy', 'ar').format(_selectedDate),
          fuelColor, () async {
        final d = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2024),
            lastDate: DateTime.now(),
            builder: (c, ch) => Theme(
                data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                        primary: fuelColor, surface: AppColors.getDialogBg(context))),
                child: ch!));
        if (d != null) setState(() => _selectedDate = d);
      }),
      // تفويل
      _actionBtn(Icons.local_gas_station, 'تفويل سيارة',
          const Color(0xFF4CAF50), () => _showRefuelDialog(provider)),
      // إضافة
      _actionBtn(Icons.add, 'إضافة سيارة', AppColors.getAccent(context),
          () => _showAddVehicleDialog(provider)),
      // تحميل Excel
      _actionBtn(Icons.upload_file, 'تحميل Excel', const Color(0xFF8B5CF6),
          () => _showUploadSnackbar()),
      // تصدير
      _actionBtn(Icons.file_download, 'تصدير', const Color(0xFF42A5F5),
          () => _showExportDialog()),
      // بحث
      Container(
        width: 220,
        height: 40,
        decoration: BoxDecoration(
            color: AppColors.getSurfaceVariant(context),
            borderRadius: BorderRadius.circular(10)),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.cairo(color: AppColors.getTextPrimary(context), fontSize: 12),
          decoration: InputDecoration(
            hintText: 'بحث برقم السيارة أو السائق...',
            hintStyle:
                GoogleFonts.cairo(color: AppColors.getHintText(context), fontSize: 11),
            prefixIcon: Icon(Icons.search, color: AppColors.getHintText(context), size: 16),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    ]);
  }

  // ===== كارت إحصائي =====
  Widget _statCard(
      String title, String value, IconData icon, Color color, String sub) {
    return Expanded(
        child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getCardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  GoogleFonts.cairo(fontSize: 11, color: AppColors.getSubtleText(context))),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context))),
          Text(sub, style: GoogleFonts.cairo(fontSize: 10, color: color)),
        ])),
      ]),
    ));
  }

  // ===== Dashboard =====
  Widget _buildDashboard(List<double> data, Color fuelColor, NumberFormat fmt,
      FuelProvider provider) {
    final days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
    final maxY = data.isEmpty
        ? 100.0
        : (data.reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(100.0, double.infinity);

    return Card(
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dashboard Pro+',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context))),
                Text('استهلاك ${widget.fuelType} الأسبوعي',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.getSubtleText(context))),
              ]),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: fuelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Icon(Icons.circle, color: fuelColor, size: 8),
                  const SizedBox(width: 6),
                  Text(widget.fuelType,
                      style: GoogleFonts.cairo(
                          color: fuelColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
                height: 220,
                child: BarChart(BarChartData(
                  maxY: maxY,
                  gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) =>
                          FlLine(color: AppColors.getDivider(context), strokeWidth: 0.5)),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              if (v.toInt() >= 0 && v.toInt() < days.length)
                                return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(days[v.toInt()],
                                        style: GoogleFonts.cairo(
                                            color: AppColors.getHintText(context),
                                            fontSize: 10)));
                              return const SizedBox();
                            })),
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (v, _) => Text(
                                '${(v / 1000).toStringAsFixed(0)}K',
                                style: TextStyle(
                                    color: AppColors.getHintText(context), fontSize: 9)))),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                      data.length,
                      (i) => BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                                toY: data[i],
                                gradient: LinearGradient(
                                    colors: [
                                      fuelColor,
                                      fuelColor.withOpacity(0.5)
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter),
                                width: 22,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8))),
                          ])),
                ))),
            const SizedBox(height: 16),
            // إحصائيات سريعة
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _miniStat(
                  'المعدل اليومي',
                  '${fmt.format(data.isEmpty ? 0 : data.reduce((a, b) => a + b) / 7)} لتر',
                  fuelColor),
              _miniStat(
                  'أعلى يوم',
                  '${fmt.format(data.isEmpty ? 0 : data.reduce((a, b) => a > b ? a : b))} لتر',
                  const Color(0xFFEF5350)),
              _miniStat(
                  'أقل يوم',
                  '${fmt.format(data.isEmpty ? 0 : data.where((d) => d > 0).isEmpty ? 0 : data.where((d) => d > 0).reduce((a, b) => a < b ? a : b))} لتر',
                  const Color(0xFF4CAF50)),
            ]),
          ])),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(label,
            style:
                GoogleFonts.cairo(fontSize: 10, color: AppColors.getSubtleText(context))),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context))),
      ]),
    );
  }

  // ===== Top 10 =====
  Widget _buildTop10(List<Vehicle> top10, NumberFormat fmt, Color fuelColor) {
    return Card(
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.emoji_events,
                  color: const Color(0xFFFFD700), size: 22),
              const SizedBox(width: 8),
              Text('أكثر 10 استهلاكاً',
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context))),
            ]),
            const SizedBox(height: 4),
            Text('اليوم ${DateFormat('d/M', 'ar').format(_selectedDate)}',
                style: GoogleFonts.cairo(
                    fontSize: 11, color: AppColors.getSubtleText(context))),
            const SizedBox(height: 12),
            if (top10.isEmpty)
              Center(
                  child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(children: [
                        Icon(Icons.inbox, color: AppColors.getHintText(context), size: 40),
                        const SizedBox(height: 8),
                        Text('لا توجد بيانات',
                            style: GoogleFonts.cairo(
                                color: AppColors.getHintText(context), fontSize: 12)),
                      ])))
            else
              ...top10.asMap().entries.map((e) {
                final i = e.key;
                final v = e.value;
                final medal = i == 0
                    ? '🥇'
                    : i == 1
                        ? '🥈'
                        : i == 2
                            ? '🥉'
                            : '${i + 1}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: i < 3
                        ? fuelColor.withOpacity(0.06)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: i < 3
                        ? Border.all(color: fuelColor.withOpacity(0.15))
                        : null,
                  ),
                  child: Row(children: [
                    Text(medal, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(v.plateNumber,
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextPrimary(context))),
                          Text(v.driverName,
                              style: GoogleFonts.cairo(
                                  fontSize: 10, color: AppColors.getSubtleText(context))),
                        ])),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${fmt.format(v.lastQuantity)} لتر',
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: fuelColor)),
                          Text(v.vehicleType,
                              style: GoogleFonts.cairo(
                                  fontSize: 9, color: AppColors.getHintText(context))),
                        ]),
                  ]),
                );
              }),
          ])),
    );
  }

  // ===== فلتر الأنواع =====
  Widget _buildTypeFilter(List<String> types, List<Vehicle> allVehicles,
      Color fuelColor, NumberFormat fmt) {
    return Card(
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('تصنيف السيارات',
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(context))),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _filterChip(
                  'الكل',
                  null,
                  fuelColor,
                  allVehicles
                      .where((v) => v.fuelType == widget.fuelType)
                      .length),
              ...types.map((t) => _filterChip(
                  t,
                  t,
                  fuelColor,
                  allVehicles
                      .where((v) =>
                          v.fuelType == widget.fuelType && v.vehicleType == t)
                      .length)),
            ]),
          ])),
    );
  }

  Widget _filterChip(String label, String? value, Color color, int count) {
    final isSelected = _typeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _typeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withOpacity(0.15) : AppColors.getSurfaceVariant(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : AppColors.getDivider(context)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: isSelected ? color : AppColors.getTextPrimary(context),
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : AppColors.getDivider(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(10)),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? color : AppColors.getSubtleText(context),
                    fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  // ===== الجدول =====
  Widget _buildDataTable(List<Vehicle> vehicles, NumberFormat fmt,
      Color fuelColor, FuelProvider provider) {
    return Card(
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('سجل العربات - ${widget.fuelType}',
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context))),
              Text('${vehicles.length} سيارة',
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.getSubtleText(context))),
            ]),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getDivider(context))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(AppColors.getTableHeader(context)),
                    dataRowColor: WidgetStateProperty.all(Colors.transparent),
                    headingTextStyle: GoogleFonts.cairo(
                        color: AppColors.getTextPrimary(context),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                    dataTextStyle: GoogleFonts.cairo(
                        color: AppColors.getTextSecondary(context), fontSize: 11),
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('رقم السيارة')),
                      DataColumn(label: Text('السائق')),
                      DataColumn(label: Text('النوع')),
                      DataColumn(label: Text('الموديل')),
                      DataColumn(label: Text('آخر تفويل')),
                      DataColumn(label: Text('الكمية')),
                      DataColumn(label: Text('الاستهلاك الكلي')),
                      DataColumn(label: Text('الحالة')),
                      DataColumn(label: Text('الإجراءات')),
                    ],
                    rows:
                        vehicles.take(15).toList().asMap().entries.map((entry) {
                      final i = entry.key;
                      final v = entry.value;
                      return DataRow(cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text(v.plateNumber,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                        DataCell(Text(v.driverName)),
                        DataCell(_typeBadge(v.vehicleType, fuelColor)),
                        DataCell(Text(v.model)),
                        DataCell(Text(
                            DateFormat('d/M/yyyy', 'ar').format(v.lastRefuel))),
                        DataCell(Text('${fmt.format(v.lastQuantity)} لتر',
                            style: TextStyle(
                                color: fuelColor,
                                fontWeight: FontWeight.bold))),
                        DataCell(Text('${fmt.format(v.totalConsumed)} لتر')),
                        DataCell(_statusBadge(v.isActive)),
                        DataCell(Row(children: [
                          IconButton(
                              icon: Icon(Icons.local_gas_station,
                                  color: const Color(0xFF4CAF50), size: 16),
                              tooltip: 'تفويل',
                              onPressed: () =>
                                  _showRefuelOneDialog(provider, v)),
                          IconButton(
                              icon: Icon(Icons.edit,
                                  color: const Color(0xFF42A5F5), size: 16),
                              tooltip: 'تعديل',
                              onPressed: () => _showEditDialog(provider, v)),
                          IconButton(
                              icon: Icon(Icons.history,
                                  color: const Color(0xFFFFA726), size: 16),
                              tooltip: 'السجل',
                              onPressed: () => _showHistoryDialog(v)),
                        ])),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ])),
    );
  }

  Widget _typeBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Text(type,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: (active ? const Color(0xFF4CAF50) : const Color(0xFFEF5350))
              .withOpacity(0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle,
            size: 6,
            color: active ? const Color(0xFF4CAF50) : const Color(0xFFEF5350)),
        const SizedBox(width: 4),
        Text(active ? 'نشط' : 'متوقف',
            style: TextStyle(
                color:
                    active ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.cairo(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // ===== دايلوج تفويل سيارة =====
  void _showRefuelDialog(FuelProvider provider) {
    final plateCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: AppColors.getDialogBg(context),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.local_gas_station,
                        color: Color(0xFF4CAF50))),
                const SizedBox(width: 12),
                Text('تفويل سيارة - ${widget.fuelType}',
                    style: GoogleFonts.cairo(
                        color: AppColors.getTextPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ]),
              content: SizedBox(
                  width: 400,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _dialogField(
                        plateCtrl, 'رقم السيارة', Icons.directions_car),
                    const SizedBox(height: 12),
                    _dialogField(
                        qtyCtrl, 'الكمية (لتر)', Icons.local_gas_station,
                        isNumber: true),
                    const SizedBox(height: 12),
                    _dialogField(notesCtrl, 'ملاحظات', Icons.note),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إلغاء',
                        style: GoogleFonts.cairo(color: AppColors.getSubtleText(context)))),
                ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(qtyCtrl.text) ?? 0;
                    if (plateCtrl.text.isEmpty || qty <= 0) return;
                    provider.refuelVehicle(
                        plateCtrl.text, qty, widget.fuelType);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('تم التفويل بنجاح',
                            style: GoogleFonts.cairo()),
                        backgroundColor: const Color(0xFF4CAF50)));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: Text('تفويل',
                      style: GoogleFonts.cairo(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            )));
  }

  void _showRefuelOneDialog(FuelProvider provider, Vehicle v) {
    final qtyCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: AppColors.getDialogBg(context),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('تفويل ${v.plateNumber}',
                  style: GoogleFonts.cairo(
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.bold)),
              content: _dialogField(
                  qtyCtrl, 'الكمية (لتر)', Icons.local_gas_station,
                  isNumber: true),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إلغاء',
                        style: GoogleFonts.cairo(color: AppColors.getSubtleText(context)))),
                ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(qtyCtrl.text) ?? 0;
                    if (qty <= 0) return;
                    provider.refuelVehicle(v.plateNumber, qty, widget.fuelType);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('تم تفويل ${v.plateNumber}',
                            style: GoogleFonts.cairo()),
                        backgroundColor: const Color(0xFF4CAF50)));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: Text('تفويل',
                      style: GoogleFonts.cairo(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            )));
  }

  // ===== إضافة سيارة =====
  void _showAddVehicleDialog(FuelProvider provider) {
    final plateCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    String vType = 'شاحنة';
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, ss) => Directionality(
                textDirection: ui.TextDirection.rtl,
                child: AlertDialog(
                  backgroundColor: AppColors.getDialogBg(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Row(children: [
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: AppColors.getAccent(context).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.add, color: AppColors.getAccent(context))),
                    const SizedBox(width: 12),
                    Text('إضافة سيارة - ${widget.fuelType}',
                        style: GoogleFonts.cairo(
                            color: AppColors.getTextPrimary(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ]),
                  content: SizedBox(
                      width: 450,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        _dialogField(
                            plateCtrl, 'رقم اللوحة', Icons.confirmation_number),
                        const SizedBox(height: 12),
                        _dialogField(driverCtrl, 'اسم السائق', Icons.person),
                        const SizedBox(height: 12),
                        _dialogField(
                            modelCtrl, 'الموديل', Icons.directions_car),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: vType,
                          dropdownColor: AppColors.getDialogBg(context),
                          style: GoogleFonts.cairo(
                              color: AppColors.getTextPrimary(context), fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'نوع السيارة',
                            labelStyle: GoogleFonts.cairo(
                                color: AppColors.getSubtleText(context), fontSize: 12),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: AppColors.getDivider(context))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: AppColors.getAccent(context))),
                          ),
                          items: [
                            'شاحنة',
                            'صهريج',
                            'بيكب',
                            'سيارة صغيرة',
                            'باص',
                            'معدة ثقيلة',
                            'مولدة'
                          ]
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => ss(() => vType = v!),
                        ),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('إلغاء',
                            style: GoogleFonts.cairo(
                                color: AppColors.getSubtleText(context)))),
                    ElevatedButton(
                      onPressed: () {
                        if (plateCtrl.text.isEmpty) return;
                        provider.addVehicle(
                            plateNumber: plateCtrl.text,
                            driverName: driverCtrl.text.isEmpty
                                ? 'غير محدد'
                                : driverCtrl.text,
                            model: modelCtrl.text.isEmpty
                                ? 'غير محدد'
                                : modelCtrl.text,
                            vehicleType: vType,
                            fuelType: widget.fuelType);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('تم إضافة السيارة',
                                style: GoogleFonts.cairo()),
                            backgroundColor: AppColors.getAccent(context)));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getAccent(context),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: Text('إضافة',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ))));
  }

  void _showEditDialog(FuelProvider provider, Vehicle v) {
    final driverCtrl = TextEditingController(text: v.driverName);
    final modelCtrl = TextEditingController(text: v.model);
    showDialog(
        context: context,
        builder: (ctx) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: AppColors.getDialogBg(context),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('تعديل ${v.plateNumber}',
                  style: GoogleFonts.cairo(
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.bold)),
              content: SizedBox(
                  width: 400,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _dialogField(driverCtrl, 'اسم السائق', Icons.person),
                    const SizedBox(height: 12),
                    _dialogField(modelCtrl, 'الموديل', Icons.directions_car),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إلغاء',
                        style: GoogleFonts.cairo(color: AppColors.getSubtleText(context)))),
                ElevatedButton(
                  onPressed: () {
                    provider.updateVehicle(v.id,
                        driverName: driverCtrl.text, model: modelCtrl.text);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: Text('حفظ',
                      style: GoogleFonts.cairo(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            )));
  }

  void _showHistoryDialog(Vehicle v) {
    showDialog(
        context: context,
        builder: (ctx) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: AppColors.getDialogBg(context),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('سجل ${v.plateNumber}',
                  style: GoogleFonts.cairo(
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.bold)),
              content: SizedBox(
                  width: 400,
                  height: 300,
                  child: ListView(
                      children: v.history
                          .map((h) => ListTile(
                                leading: Icon(Icons.local_gas_station,
                                    color: AppColors.getAccent(context), size: 18),
                                title: Text(
                                    '${NumberFormat('#,###', 'ar').format(h.quantity)} لتر',
                                    style: GoogleFonts.cairo(
                                        color: AppColors.getTextPrimary(context),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    DateFormat('d/M/yyyy - HH:mm', 'ar')
                                        .format(h.date),
                                    style: GoogleFonts.cairo(
                                        color: AppColors.getSubtleText(context),
                                        fontSize: 11)),
                              ))
                          .toList())),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إغلاق',
                        style: GoogleFonts.cairo(color: AppColors.getSubtleText(context))))
              ],
            )));
  }

  void _showExportDialog() {
    showDialog(
        context: context,
        builder: (ctx) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: AppColors.getDialogBg(context),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('تصدير البيانات',
                  style: GoogleFonts.cairo(
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.bold)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(
                    leading: Icon(Icons.picture_as_pdf,
                        color: const Color(0xFFEF5350)),
                    title: Text('تصدير PDF',
                        style: GoogleFonts.cairo(color: AppColors.getTextPrimary(context))),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('جاري تصدير PDF...',
                              style: GoogleFonts.cairo()),
                          backgroundColor: const Color(0xFFEF5350)));
                    }),
                ListTile(
                    leading:
                        Icon(Icons.table_chart, color: const Color(0xFF4CAF50)),
                    title: Text('تصدير Excel',
                        style: GoogleFonts.cairo(color: AppColors.getTextPrimary(context))),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('جاري تصدير Excel...',
                              style: GoogleFonts.cairo()),
                          backgroundColor: const Color(0xFF4CAF50)));
                    }),
              ]),
            )));
  }

  void _showUploadSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('اختر ملف Excel لتحميل بيانات السيارات...',
            style: GoogleFonts.cairo()),
        backgroundColor: const Color(0xFF8B5CF6),
        duration: const Duration(seconds: 3)));
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.cairo(color: AppColors.getTextPrimary(context), fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.cairo(color: AppColors.getSubtleText(context), fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.getHintText(context), size: 18),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.getDivider(context))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.getAccent(context))),
      ),
    );
  }
}

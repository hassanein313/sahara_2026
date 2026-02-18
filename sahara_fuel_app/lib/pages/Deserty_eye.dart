import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../constants/app_colors.dart';
import 'dart:ui' as ui;
import '../utils/theme_colors.dart';

/// صفحة عين الصحراء — تصميم حديث يطابق الصورة 2 تماماً
class DesertEyePage extends StatefulWidget {
  const DesertEyePage({super.key});
  @override
  State<DesertEyePage> createState() => _DesertEyePageState();
}

class _DesertEyePageState extends State<DesertEyePage> {
  int _selectedStation = -1;
  final fmt = NumberFormat('#,###', 'ar');

  // الألوان المطابقة للصورة 2
  static const Color sandLight = Color(0xFFF5E6D3);
  static const Color sandMedium = Color(0xFFD4B896);
  static const Color sandDark = Color(0xFFBFA07A);
  static const Color navyDark = Color(0xFF1A3A52);
  static const Color navyMedium = Color(0xFF2A5080);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color gasGreen = Color(0xFF10B981);
  static const Color benzenBlue = Color(0xFF3B82F6);
  static const Color dezelOrange = Color(0xFFFFA726);

  // الألوان الليلية
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A1F28);
  static const Color darkSurfaceLight = Color(0xFF252B36);
  static const Color darkText = Color(0xFFE5E7EB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Helper للحصول على الألوان الديناميكية
  Color _getBgColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkBackground : sandLight;
  }

  Color _getSidebarColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkSurface : navyDark;
  }

  Color _getCardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkSurfaceLight : Colors.white;
  }

  Color _getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkText : navyDark;
  }

  Color _getSecondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkTextSecondary : Colors.grey[600]!;
  }

  Color _getBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Color(0xFF3F4655) : Colors.grey[300]!;
  }

  Color _getGridColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Color(0xFF2A3142) : Colors.grey[200]!;
  }

  // بيانات المحطات
  final List<Station> stations = [
    Station('محطة الصحراء 1', Offset(0.70, 0.12), 45000, 'كاز', true),
    Station('محطة أنوار', Offset(0.28, 0.18), 62000, 'بنزين', true),
    Station('الموقع المالي', Offset(0.48, 0.38), 38000, 'كاز', true),
    Station('أنوجية القاسم', Offset(0.25, 0.52), 51000, 'غاز', true),
    Station('محطة الراحة', Offset(0.40, 0.60), 29000, 'بنزين', false),
    Station('محطة الرمال', Offset(0.43, 0.65), 73000, 'كاز', true),
    Station('الوجهة النهائية', Offset(0.68, 0.55), 85000, 'بنزين', true),
  ];

  // بيانات آخر المعاملات
  final List<Transaction> transactions = [
    Transaction(
        'Seek', 'Seek', 100, '11 Mesaago', Icons.local_gas_station, gasGreen),
    Transaction('تعريب', 'Scattered', 940, 'GL 02:20h', Icons.directions_car,
        dezelOrange),
    Transaction('تعبئة', 'Isloor', 590, 'GL 05:99h', Icons.local_gas_station,
        benzenBlue),
    Transaction('تحويل', 'Enabled Stallonen', 166, '3A 60:23h',
        Icons.swap_horiz, Color(0xFF8B5CF6)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBgColor(context),
      body: Row(
        children: [
          // ===== الشريط الجانبي الأزرق =====
          _buildSidebar(context),
          // ===== المحتوى الرئيسي =====
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الهيدر
                  _buildHeader(context),
                  SizedBox(height: 24),
                  // القسم الرئيسي: الخريطة + الجهة اليمنى
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الخريطة (يسار)
                      Expanded(
                        flex: 2,
                        child: _buildMapCard(context),
                      ),
                      SizedBox(width: 24),
                      // العدادات والمعلومات (يمين)
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildFuelGauges(context),
                            SizedBox(height: 20),
                            _buildTotalConsumption(context),
                            SizedBox(height: 20),
                            _buildRecentTransactions(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  // الرسوم البيانية
                  _buildChartsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== الشريط الجانبي =====
  Widget _buildSidebar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: _getSidebarColor(context),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        children: [
          // الشعار
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Color(0xFF4A7C9E), Color(0xFF5A9CCD)]
                          : [sandMedium, sandLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(Icons.local_gas_station,
                      color: isDark ? Colors.white : navyDark, size: 32),
                ),
                SizedBox(height: 12),
                Text(
                  'وقود الصحاري',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(context),
                  ),
                ),
                Text(
                  'Desert Fuel',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: _getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: _getBorderColor(context), height: 1),
          // المنتجات
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _sidebarItem(context, Icons.dashboard_rounded, 'لوحة التحكم'),
                _sidebarItem(context, Icons.location_on_rounded, 'المحطات',
                    isActive: true),
                _sidebarItem(context, Icons.directions_car_rounded, 'العربات'),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'المحطات القريبة',
                    style: GoogleFonts.cairo(
                      color: _getSecondaryTextColor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                ...stations.take(3).map((s) => _stationItem(context, s)),
              ],
            ),
          ),
          Divider(color: _getBorderColor(context), height: 1),
          // Settings
          Padding(
            padding: EdgeInsets.all(16),
            child: _sidebarItem(context, Icons.settings_rounded, 'الإعدادات'),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, String label,
      {bool isActive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Color(0xFF3A5475) : navyMedium).withOpacity(0.6)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? Border.all(color: teal.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isActive ? teal : _getSecondaryTextColor(context),
                size: 20),
            SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: isActive
                    ? teal
                    : (isDark ? Colors.grey[300] : Colors.grey[400]),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stationItem(BuildContext context, Station station) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: station.active ? gasGreen : Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                station.name,
                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 10),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== الهيدر =====
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الخريطة',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getTextColor(context),
              ),
            ),
            Text(
              'مسار العربات المتتبع',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: _getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _headerButton(context, 'بحث', Icons.search),
            SizedBox(width: 12),
            _headerButton(context, 'ملفي', Icons.person),
          ],
        ),
      ],
    );
  }

  Widget _headerButton(BuildContext context, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Icon(icon, color: _getTextColor(context), size: 18),
          SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  // ===== خريطة واقعية جميلة =====
  Widget _buildMapCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTapDown: (details) {
            setState(() {
              for (int i = 0; i < stations.length; i++) {
                final station = stations[i];
                final dx =
                    (details.localPosition.dx / 400 - station.position.dx)
                        .abs();
                final dy =
                    (details.localPosition.dy / 380 - station.position.dy)
                        .abs();
                if (dx < 0.05 && dy < 0.05) {
                  _selectedStation = _selectedStation == i ? -1 : i;
                  return;
                }
              }
            });
          },
          child: CustomPaint(
            painter: MapPainter(
              stations: stations,
              selectedStation: _selectedStation,
            ),
            size: Size(double.infinity, 380),
          ),
        ),
      ),
    );
  }

  // ===== عدادات الوقود =====
  Widget _buildFuelGauges(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مستوى الوقود',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getTextColor(context),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _fuelGauge(context, 'Gas', 0.65, gasGreen),
              _fuelGauge(context, 'Banzen', 0.78, benzenBlue),
              _fuelGauge(context, 'Dezel', 0.45, dezelOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fuelGauge(
      BuildContext context, String label, double value, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 5,
                  color: color.withOpacity(0.2),
                  strokeCap: StrokeCap.round,
                ),
              ),
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 5,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _getTextColor(context),
          ),
        ),
      ],
    );
  }

  // ===== إجمالي الاستهلاك =====
  Widget _buildTotalConsumption(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجمالي التعبئة',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: _getSecondaryTextColor(context),
            ),
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '4.50',
                style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(context),
                ),
              ),
              SizedBox(width: 6),
              Text(
                'L/100km',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: _getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.68,
              minHeight: 8,
              backgroundColor: _getGridColor(context),
              color: teal,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Efficiency 68%',
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ===== آخر المعاملات =====
  Widget _buildRecentTransactions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المعاملات',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getTextColor(context),
            ),
          ),
          Text(
            'Recent Transactions',
            style: GoogleFonts.cairo(
              fontSize: 9,
              color: _getSecondaryTextColor(context),
            ),
          ),
          SizedBox(height: 16),
          // رأس الجدول
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'نوع العملية',
                    style: GoogleFonts.cairo(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _getSecondaryTextColor(context),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'الوقت',
                    style: GoogleFonts.cairo(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'المبلغ',
                    style: GoogleFonts.cairo(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _getSecondaryTextColor(context),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: _getBorderColor(context)),
          ...transactions.map((t) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: t.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(t.icon, size: 14, color: t.color),
                          ),
                          SizedBox(width: 8),
                          Text(
                            t.type,
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        t.time,
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          color: _getSecondaryTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '\$${t.amount}',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(context),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ===== الرسوم البيانية =====
  Widget _buildChartsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الرسوم البيانية التحليلية',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getTextColor(context),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildLineChart(context, 'Efficiency', gasGreen),
            ),
            SizedBox(width: 20),
            Expanded(
              child: _buildLineChart(context, 'Timeline', benzenBlue),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context, String title, Color color) {
    final data = [45.0, 55.0, 48.0, 62.0, 70.0, 68.0, 75.0];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(context),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Legend',
                  style: GoogleFonts.cairo(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: _getGridColor(context),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        'يوم ${v.toInt() + 1}',
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          color: _getSecondaryTextColor(context),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: TextStyle(
                          fontSize: 8,
                          color: _getSecondaryTextColor(context),
                        ),
                      ),
                    ),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      data.length,
                      (i) => FlSpot(i.toDouble(), data[i]),
                    ),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(enabled: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== رسام الخريطة المخصص =====
class MapPainter extends CustomPainter {
  final List<Station> stations;
  final int selectedStation;

  MapPainter({
    required this.stations,
    required this.selectedStation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // خلفية رملية تفصيلية
    _drawDesertBackground(canvas, size);

    // رسم الطريق بشكل واقعي
    _drawRoad(canvas, size);

    // رسم المحطات
    _drawStations(canvas, size);

    // رسم السيارات
    _drawVehicles(canvas, size);

    // رسم بالون المعلومات
    if (selectedStation >= 0 && selectedStation < stations.length) {
      _drawStationInfo(canvas, size, stations[selectedStation]);
    }
  }

  void _drawDesertBackground(Canvas canvas, Size size) {
    // تدرج لوني صحراوي
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFD4B896),
          Color(0xFFBFA07A),
          Color(0xFFA88B6A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // تفاصيل رملية
    final rng = Random(42);
    final dotPaint = Paint()..color = Color(0xFFBFA07A).withOpacity(0.3);
    for (int i = 0; i < 100; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 3,
        dotPaint,
      );
    }

    // تلال رملية
    final hillPaint = Paint()
      ..color = Color(0xFFC4A882).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    for (double x = 0; x <= size.width; x += 30) {
      path.lineTo(
          x, size.height * 0.5 + 20 * sin(x * 0.008) + rng.nextDouble() * 10);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, hillPaint);
  }

  void _drawRoad(Canvas canvas, Size size) {
    if (stations.length < 2) return;

    // رسم الطريق بشكل واقعي
    final path = Path();
    path.moveTo(stations[0].position.dx * size.width,
        stations[0].position.dy * size.height);

    for (int i = 1; i < stations.length; i++) {
      final prev = stations[i - 1];
      final curr = stations[i];

      // استخدام Bezier curves لرسم طريق ناعم
      final ctrl1X = (prev.position.dx + curr.position.dx) / 2 * size.width;
      final ctrl1Y = (prev.position.dy * size.height) + (i.isEven ? -30 : 30);

      path.quadraticBezierTo(
        ctrl1X,
        ctrl1Y,
        curr.position.dx * size.width,
        curr.position.dy * size.height,
      );
    }

    // رسم خط الطريق الخلفي (ظل)
    final shadowPaint = Paint()
      ..color = Color(0xFF2D3748).withOpacity(0.6)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, shadowPaint);

    // رسم خط الطريق الرئيسي
    final roadPaint = Paint()
      ..color = Color(0xFF4A5568).withOpacity(0.8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, roadPaint);

    // رسم خطوط وسط الطريق المتقطعة
    final dashPaint = Paint()
      ..color = Color(0xFFFFA726).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final metrics = path.computeMetrics();
    for (var metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final nextDistance = distance + 12;
          final nextTangent =
              metric.getTangentForOffset(min(nextDistance, metric.length));
          if (nextTangent != null) {
            canvas.drawLine(tangent.position, nextTangent.position, dashPaint);
          }
        }
        distance += 24;
      }
    }
  }

  void _drawStations(Canvas canvas, Size size) {
    for (int i = 0; i < stations.length; i++) {
      final station = stations[i];
      final isSelected = i == selectedStation;

      final x = station.position.dx * size.width;
      final y = station.position.dy * size.height;

      // الدائرة الخارجية (الهالة)
      if (isSelected) {
        final haloPaint = Paint()
          ..color = Color(0xFFD4A843).withOpacity(0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 28, haloPaint);
      }

      // الدائرة الرئيسية
      final circlePaint = Paint()
        ..color = station.active ? Color(0xFF1A3A52) : Color(0xFFEF4444)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), isSelected ? 18 : 14, circlePaint);

      // الإطار
      final borderPaint = Paint()
        ..color = isSelected ? Color(0xFFD4A843) : Color(0xFF2DD4BF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2;
      canvas.drawCircle(Offset(x, y), isSelected ? 18 : 14, borderPaint);

      // الأيقونة
      final textPainter = TextPainter(
        text: TextSpan(
          text: '⛽',
          style: TextStyle(fontSize: isSelected ? 18 : 14),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          y - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawVehicles(Canvas canvas, Size size) {
    // رسم السيارات المتحركة على الطريق
    final vehicles = [
      (0.35, 0.25),
      (0.55, 0.45),
      (0.30, 0.65),
    ];

    for (final (x, y) in vehicles) {
      final px = x * size.width;
      final py = y * size.height;

      // الظل
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px - 12, py + 8, 24, 8),
          Radius.circular(2),
        ),
        shadowPaint,
      );

      // السيارة
      final carPaint = Paint()
        ..color = Color(0xFF3B82F6).withOpacity(0.8)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px - 10, py - 8, 20, 16),
          Radius.circular(6),
        ),
        carPaint,
      );

      // الإطارات
      final wheelPaint = Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px - 5, py + 6), 2, wheelPaint);
      canvas.drawCircle(Offset(px + 5, py + 6), 2, wheelPaint);
    }
  }

  void _drawStationInfo(Canvas canvas, Size size, Station station) {
    final x = station.position.dx * size.width;
    final y = station.position.dy * size.height;

    // بالون المعلومات
    final balloonX = x.clamp(80.0, size.width - 80);
    final balloonY = (y - 60).clamp(20.0, size.height - 80);

    // الخلفية
    final bgPaint = Paint()
      ..color = Color(0xFF1A3A52).withOpacity(0.95)
      ..style = PaintingStyle.fill;

    final balloonRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(balloonX - 70, balloonY, 140, 80),
      Radius.circular(10),
    );
    canvas.drawRRect(balloonRect, bgPaint);

    // الحد الخارجي
    final borderPaint = Paint()
      ..color = Color(0xFFD4A843).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(balloonRect, borderPaint);

    // المؤشر
    final pointerPath = Path();
    pointerPath.moveTo(balloonX - 10, balloonY + 80);
    pointerPath.lineTo(balloonX + 10, balloonY + 80);
    pointerPath.lineTo(balloonX, balloonY + 90);
    pointerPath.close();
    canvas.drawPath(pointerPath, bgPaint);

    // النص
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${station.name}\n${station.fuelType}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        balloonX - 70 + 10,
        balloonY + 15,
      ),
    );
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) =>
      oldDelegate.selectedStation != selectedStation;
}

// ===== النماذج =====
class Station {
  final String name;
  final Offset position;
  final int balance;
  final String fuelType;
  final bool active;

  Station(this.name, this.position, this.balance, this.fuelType, this.active);
}

class Transaction {
  final String type;
  final String name;
  final int amount;
  final String time;
  final IconData icon;
  final Color color;

  Transaction(
      this.type, this.name, this.amount, this.time, this.icon, this.color);
}

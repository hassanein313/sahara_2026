import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';

/// صفحة تقرير الوارد - تصميم احترافي متطور
class IncomingReportPage extends StatefulWidget {
  const IncomingReportPage({super.key});

  @override
  State<IncomingReportPage> createState() => _IncomingReportPageState();
}

class _IncomingReportPageState extends State<IncomingReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FuelProvider>(context, listen: false).syncWithApi().then((_) {
        if (mounted) setState(() {});
      });
    });
  }

  String _searchQuery = '';
  String _sortColumn = '';
  bool _sortAscending = true;
  final Map<String, String> _columnFilters = {};
  String _selectedDate = ''; // سيتم تعيينه تلقائياً لآخر تاريخ

  // بيانات قاعدة البيانات - متغيرات للفلترة
  final Map<String, String> _dbColumnFilters = {};
  bool _isDatabaseDialogVisible = false;

  // البيانات المفلترة بالتاريخ للداشبورد
  List<Map<String, dynamic>> get _dashboardData {
    return _incomingData
        .where((item) => item['date'] == _selectedDate)
        .toList();
  }

  // الحصول على آخر تاريخ تحديث من البيانات
  String get _lastUpdateDate {
    if (_incomingData.isEmpty) return '';

    // تحويل التواريخ إلى DateTime للمقارنة
    DateTime? latestDate;
    for (var item in _incomingData) {
      try {
        List<String> dateParts = (item['date'] as String).split('/');
        if (dateParts.length == 3) {
          DateTime date = DateTime(
            int.parse(dateParts[2]), // year
            int.parse(dateParts[0]), // month
            int.parse(dateParts[1]), // day
          );
          if (latestDate == null || date.isAfter(latestDate)) {
            latestDate = date;
          }
        }
      } catch (e) {
        continue;
      }
    }

    if (latestDate == null) return '';
    return '\${latestDate.month}/\${latestDate.day}/\${latestDate.year}';
  }

  // البيانات المفلترة للجدول الرئيسي - تظهر آخر تحديث فقط
  List<Map<String, dynamic>> get _mainTableData {
    String lastDate = _lastUpdateDate;
    if (lastDate.isEmpty) return [];

    // إذا لم يتم تحديد تاريخ، استخدم آخر تاريخ
    if (_selectedDate.isEmpty) {
      // Side-effect bad practice in getter, but for UI state init it works in Flutter build cycle often
      // Better handled in build()
      return _incomingData.where((item) => item['date'] == lastDate).toList();
    }

    return _incomingData.where((item) => item['date'] == lastDate).toList();
  }

  // البيانات المفلترة لقاعدة البيانات - تشمل كل البيانات
  List<Map<String, dynamic>> get _databaseFilteredData {
    List<Map<String, dynamic>> dataSource = List.from(_incomingData);

    // تطبيق فلاتر قاعدة البيانات
    if (_dbColumnFilters.isNotEmpty) {
      dataSource = dataSource.where((item) {
        return _dbColumnFilters.entries.every((filter) {
          final value = item[filter.key]?.toString().toLowerCase() ?? '';
          return value.contains(filter.value.toLowerCase());
        });
      }).toList();
    }

    return dataSource;
  }

  List<Map<String, dynamic>> get _incomingData {
    final provider = Provider.of<FuelProvider>(context);
    return provider.incomingShipments.map((e) {
      return {
        'supplier': e.supplier,
        'company': e.fuelType,
        'quantity': e.quantity.toInt(),
        'density': e.density,
        'color': e.color,
        'voucher': e.id.length > 6 ? e.id.substring(0, 6) : e.id,
        'price': e.unitPrice.toInt(),
        'cost': e.totalCost.toInt(),
        'driver': e.driverName,
        'vehicleNo': e.truckNumber,
        'date': '${e.date.month}/${e.date.day}/${e.date.year}',
      };
    }).toList();
  }

  final List<Map<String, String>> _columns = [
    {'key': 'supplier', 'label': 'اسم المجهز'},
    {'key': 'company', 'label': 'الشركة المجهزة'},
    {'key': 'quantity', 'label': 'الكمية المستلمة'},
    {'key': 'density', 'label': 'كثافة المنتج'},
    {'key': 'color', 'label': 'لون المنتج'},
    {'key': 'voucher', 'label': 'رقم الفوچر'},
    {'key': 'price', 'label': 'سعر المنتج'},
    {'key': 'cost', 'label': 'تكلفة المنتج'},
    {'key': 'driver', 'label': 'اسم السائق'},
    {'key': 'vehicleNo', 'label': 'رقم السيارة'},
    {'key': 'date', 'label': 'تاريخ الاستلام'},
  ];

  List<Map<String, dynamic>> get _filteredData {
    // استخدام _mainTableData للجدول الرئيسي (آخر تحديث فقط)
    var data = _mainTableData.where((item) {
      // Global search
      if (_searchQuery.isNotEmpty) {
        final match =
            item.values.any((v) => v.toString().contains(_searchQuery));
        if (!match) return false;
      }
      // Column filters
      for (var entry in _columnFilters.entries) {
        if (entry.value.isNotEmpty &&
            item[entry.key].toString() != entry.value) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sorting
    if (_sortColumn.isNotEmpty) {
      data.sort((a, b) {
        var aVal = a[_sortColumn];
        var bVal = b[_sortColumn];
        int cmp;
        if (aVal is int && bVal is int) {
          cmp = aVal.compareTo(bVal);
        } else {
          cmp = aVal.toString().compareTo(bVal.toString());
        }
        return _sortAscending ? cmp : -cmp;
      });
    }
    return data;
  }

  Set<String> _getUniqueValues(String key) {
    return _incomingData
        .map((e) => e[key]?.toString().trim() ?? '')
        .where((v) => v.isNotEmpty)
        .toSet();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // تعيين التاريخ تلقائياً لأحدث تاريخ عند فتح الصفحة
        if (_selectedDate.isEmpty && _incomingData.isNotEmpty) {
          Future.microtask(
              () => setState(() => _selectedDate = _lastUpdateDate));
        } else if (_selectedDate.isNotEmpty &&
            _incomingData.isNotEmpty &&
            !_incomingData.any((d) => d['date'] == _selectedDate)) {
          // إذا كان التاريخ المختار غير موجود، ننتقل لأحدث تاريخ
          Future.microtask(
              () => setState(() => _selectedDate = _lastUpdateDate));
        }

        final totalQuantity = _filteredData.fold<int>(0, (sum, item) {
          final v = item['quantity'];
          return sum + (v is num ? v.toInt() : 0);
        });
        final totalCost = _filteredData.fold<int>(0, (sum, item) {
          final v = item['cost'];
          return sum + (v is num ? v.toInt() : 0);
        });

        return Container(
          color: AppColors.scaffold,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تقرير الوارد',
                            style: GoogleFonts.cairo(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextPrimary(context))),
                        const SizedBox(height: 4),
                        Text('إدارة ومتابعة شحنات الوقود الواردة',
                            style: GoogleFonts.cairo(
                                fontSize: 13, color: AppColors.getTextSecondary(context))),
                      ],
                    ),
                    Row(
                      children: [
                        // Date Picker
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.getInputBg(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.getAccent(context).withValues(alpha: 0.5)),
                          ),
                          child: InkWell(
                            onTap: () => _showDatePicker(),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: AppColors.getAccent(context), size: 18),
                                const SizedBox(width: 8),
                                Text(_selectedDate,
                                    style: GoogleFonts.cairo(
                                        color: AppColors.getTextPrimary(context),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 6),
                                Icon(Icons.keyboard_arrow_down,
                                    color: AppColors.getTextSecondary(context), size: 18),
                              ],
                            ),
                          ),
                        ),
                        // زر قاعدة البيانات
                        InkWell(
                          onTap: () => _showDatabaseLoginDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.storage,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text('قاعدة البيانات',
                                    style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3748),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: PopupMenuButton<String>(
                            offset: const Offset(0, 45),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: const Color(0xFF2D3748),
                            elevation: 4,
                            onSelected: (value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                          value == 'PDF'
                                              ? Icons.picture_as_pdf
                                              : Icons.table_chart,
                                          color: Colors.white,
                                          size: 20),
                                      const SizedBox(width: 10),
                                      Text('جاري التصدير كـ $value...',
                                          style: GoogleFonts.cairo()),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF32363F),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'PDF',
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFE53935)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: const Icon(Icons.picture_as_pdf,
                                          color: Color(0xFFE53935), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('ملف PDF',
                                        style: GoogleFonts.cairo(
                                            fontSize: 14, color: Colors.white)),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              PopupMenuItem(
                                value: 'Excel',
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF2E7D32)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: const Icon(Icons.table_chart,
                                          color: Color(0xFF2E7D32), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('ملف Excel',
                                        style: GoogleFonts.cairo(
                                            fontSize: 14, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.download,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text('تصدير التقرير',
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 6),
                                  Icon(Icons.keyboard_arrow_down,
                                      color: Colors.grey[400], size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Stats Cards - Using Dashboard Data (filtered by date)
                Builder(builder: (context) {
                  final dashData = _dashboardData;
                  final dashTotalQty = dashData.fold<int>(0, (sum, item) {
                    final v = item['quantity'];
                    return sum + (v is num ? v.toInt() : 0);
                  });
                  final dashTotalCost = dashData.fold<int>(0, (sum, item) {
                    final v = item['cost'];
                    return sum + (v is num ? v.toInt() : 0);
                  });
                  final dashSuppliers =
                      dashData.map((e) => e['supplier']).toSet().length;
                  return Row(
                    children: [
                      _statCard('عدد الشحنات', '${dashData.length}',
                          Icons.local_shipping, const Color(0xFF3B82F6), ''),
                      const SizedBox(width: 16),
                      _statCard(
                          'إجمالي الكمية',
                          '${_formatNumber(dashTotalQty)} لتر',
                          Icons.water_drop,
                          AppColors.getAccent(context),
                          ''),
                      const SizedBox(width: 16),
                      _statCard(
                          'إجمالي التكلفة',
                          '${_formatNumber(dashTotalCost)} د.ع',
                          Icons.payments,
                          const Color(0xFFF59E0B),
                          ''),
                      const SizedBox(width: 16),
                      _statCard('عدد الموردين', '$dashSuppliers',
                          Icons.business, const Color(0xFF8B5CF6), ''),
                    ],
                  );
                }),
                const SizedBox(height: 28),

                // Charts Row - Like Reference Image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line Chart - Main Chart
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 340,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2127),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2D3748)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الشحنات الواردة',
                                    style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                                Row(
                                  children: [
                                    _legendItem('الكمية', AppColors.getAccent(context)),
                                    const SizedBox(width: 16),
                                    _legendItem(
                                        'التكلفة', const Color(0xFFEC4899)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(child: _buildLineChart()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Pie Chart + Top Suppliers
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Pie Chart with full names
                          Container(
                            height: 200,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2127),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFF2D3748)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('توزيع الموردين',
                                        style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                    Text('انقر للتفاصيل',
                                        style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            color: Colors.grey[500])),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(child: _buildPieChart()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Top Suppliers Today - Replaces Bar Chart
                          Container(
                            height: 124,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2127),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFF2D3748)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('الموردين الأكثر اليوم',
                                    style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                                const SizedBox(height: 10),
                                Expanded(child: _buildTopSuppliersList()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Advanced Table
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2127),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D3748)),
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF2D3748),
                                    borderRadius: BorderRadius.circular(10)),
                                child: TextField(
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  style: GoogleFonts.cairo(
                                      color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'بحث في جميع الأعمدة...',
                                    hintStyle: GoogleFonts.cairo(
                                        color: Colors.grey[600], fontSize: 14),
                                    prefixIcon: Icon(Icons.search,
                                        color: Colors.grey[600], size: 22),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Refresh button
                            InkWell(
                              onTap: () {
                                setState(() => _selectedDate =
                                    ''); // Reset date to force update
                                Provider.of<FuelProvider>(context,
                                        listen: false)
                                    .syncWithApi();
                              },
                              child: Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF2D3748),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.refresh,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Global filter dropdown
                            Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF2D3748),
                                  borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _columnFilters['supplier']?.isEmpty ??
                                          true
                                      ? null
                                      : _columnFilters['supplier'],
                                  hint: Row(
                                    children: [
                                      Icon(Icons.filter_list,
                                          color: Colors.grey[500], size: 18),
                                      const SizedBox(width: 8),
                                      Text('فلتر المورد',
                                          style: GoogleFonts.cairo(
                                              color: Colors.grey[500],
                                              fontSize: 13)),
                                    ],
                                  ),
                                  dropdownColor: const Color(0xFF2D3748),
                                  style: GoogleFonts.cairo(
                                      color: Colors.white, fontSize: 13),
                                  icon: Icon(Icons.keyboard_arrow_down,
                                      color: Colors.grey[500]),
                                  items: [
                                    DropdownMenuItem(
                                        value: '',
                                        child: Text('جميع الموردين',
                                            style: GoogleFonts.cairo(
                                                fontSize: 13))),
                                    ..._getUniqueValues('supplier').map((v) =>
                                        DropdownMenuItem(
                                            value: v,
                                            child: Text(v,
                                                style: GoogleFonts.cairo(
                                                    fontSize: 13)))),
                                  ],
                                  onChanged: (v) => setState(() =>
                                      _columnFilters['supplier'] = v ?? ''),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Add Data Button
                            InkWell(
                              onTap: () {/* TODO: Add data dialog */},
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.getAccent(context),
                                      AppColors.getAccent(context).withValues(alpha: 0.8)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.add,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text('إضافة بيانات',
                                        style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (_columnFilters.values.any((v) => v.isNotEmpty))
                              InkWell(
                                onTap: () =>
                                    setState(() => _columnFilters.clear()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.clear,
                                          color: Colors.red[400], size: 16),
                                      const SizedBox(width: 6),
                                      Text('مسح',
                                          style: GoogleFonts.cairo(
                                              color: Colors.red[400],
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Professional Table with Modern Design
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252830),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2D3748)),
                        ),
                        child: Column(
                          children: [
                            // Table Header Row
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Color(0xFF1E2127),
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              child: Row(
                                children: _columns
                                    .map((col) => Expanded(
                                        child: _buildProHeaderCell(
                                            col['key']!, col['label']!)))
                                    .toList(),
                              ),
                            ),
                            // Table Body - with isolated scroll
                            Listener(
                              onPointerSignal: (pointerSignal) {
                                // This prevents scroll events from bubbling up to parent
                              },
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 400),
                                child: ScrollConfiguration(
                                  behavior: ScrollConfiguration.of(context)
                                      .copyWith(scrollbars: true),
                                  child: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      children: _filteredData
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final d = entry.value;
                                        final isOdd = entry.key % 2 == 1;
                                        return Container(
                                          width: double.infinity,
                                          color: isOdd
                                              ? const Color(0xFF1E2127)
                                              : const Color(0xFF252830),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 8),
                                          child: Row(
                                            children: _columns
                                                .map((col) => Expanded(
                                                    child: _buildProDataCell(
                                                        d, col['key']!)))
                                                .toList(),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                                child: Text(
                                    'إجمالي: ${_filteredData.length} سجل',
                                    style: GoogleFonts.cairo(
                                        color: Colors.grey[500],
                                        fontSize: 13))),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('الكمية: ',
                                      style: GoogleFonts.cairo(
                                          color: Colors.grey[500],
                                          fontSize: 12)),
                                  Text('${_formatNumber(totalQuantity)} لتر',
                                      style: GoogleFonts.cairo(
                                          color: AppColors.getAccent(context),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(String key, String label) {
    final isActive = _sortColumn == key;
    final uniqueValues = _getUniqueValues(key);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minWidth: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column title with sort
          InkWell(
            onTap: () {
              setState(() {
                if (_sortColumn == key) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortColumn = key;
                  _sortAscending = true;
                }
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(width: 6),
                Icon(
                  isActive
                      ? (_sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward)
                      : Icons.unfold_more,
                  color: isActive ? AppColors.getAccent(context) : Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
          // Filter dropdown
          if (uniqueValues.isNotEmpty && uniqueValues.length < 10) ...[
            const SizedBox(height: 8),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFF2D3748),
                  borderRadius: BorderRadius.circular(6)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _columnFilters[key]?.isEmpty ?? true
                      ? null
                      : _columnFilters[key],
                  hint: Text('الكل',
                      style: GoogleFonts.cairo(
                          color: Colors.grey[500], fontSize: 11)),
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2D3748),
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 11),
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey[600], size: 16),
                  items: [
                    DropdownMenuItem(
                        value: '',
                        child: Text('الكل',
                            style: GoogleFonts.cairo(fontSize: 11))),
                    ...uniqueValues.map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v,
                            style: GoogleFonts.cairo(fontSize: 11),
                            overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) =>
                      setState(() => _columnFilters[key] = v ?? ''),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataCell(Map<String, dynamic> data, String key) {
    final value = data[key];
    String displayValue;
    Color textColor = Colors.grey[300]!;
    FontWeight fontWeight = FontWeight.normal;

    if (value is int) {
      if (key == 'quantity') {
        displayValue = _formatNumber(value);
        textColor = AppColors.getAccent(context);
        fontWeight = FontWeight.bold;
      } else if (key == 'cost') {
        displayValue = value > 0 ? _formatNumber(value) : '-';
        textColor = value > 0 ? const Color(0xFFF59E0B) : Colors.grey[500]!;
        fontWeight = value > 0 ? FontWeight.bold : FontWeight.normal;
      } else if (key == 'price') {
        displayValue = value > 0 ? '$value' : '-';
      } else {
        displayValue = value.toString();
      }
    } else {
      displayValue = value.toString().isNotEmpty ? value.toString() : '-';
      if (displayValue == '-') textColor = Colors.grey[600]!;
    }

    // Special styling for color column
    if (key == 'color' && displayValue != '-') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: const BoxConstraints(minWidth: 120),
        child: _colorBadge(displayValue),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      constraints: const BoxConstraints(minWidth: 120),
      child: Text(displayValue,
          style: GoogleFonts.cairo(
              color: textColor, fontSize: 13, fontWeight: fontWeight)),
    );
  }

  Widget _buildProHeaderCell(String key, String label) {
    final isActive = _sortColumn == key;
    final uniqueValues = _getUniqueValues(key);
    // Show filter for all columns except 'cost'
    final hasFilter = key != 'cost' && uniqueValues.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sort header - fixed height
          SizedBox(
            height: 36,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_sortColumn == key) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortColumn = key;
                    _sortAscending = true;
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.getAccent(context).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(label,
                          style: GoogleFonts.cairo(
                            color: isActive ? AppColors.getAccent(context) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      isActive
                          ? (_sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward)
                          : Icons.sort,
                      color: isActive ? AppColors.getAccent(context) : Colors.grey[600],
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Filter dropdown - fixed height for all
          SizedBox(
            height: hasFilter ? 30 : 30,
            child: hasFilter
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3748),
                      borderRadius: BorderRadius.circular(6),
                      border: _columnFilters[key]?.isNotEmpty == true
                          ? Border.all(
                              color: AppColors.getAccent(context).withValues(alpha: 0.5),
                              width: 1)
                          : null,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _columnFilters[key]?.isEmpty ?? true
                            ? null
                            : _columnFilters[key],
                        hint: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_alt_outlined,
                                color: Colors.grey[600], size: 11),
                            const SizedBox(width: 3),
                            Text('الكل',
                                style: GoogleFonts.cairo(
                                    color: Colors.grey[500], fontSize: 10)),
                          ],
                        ),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2D3748),
                        style: GoogleFonts.cairo(
                            color: Colors.white, fontSize: 10),
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey[600], size: 12),
                        items: [
                          DropdownMenuItem(
                              value: '',
                              child: Row(
                                children: [
                                  Icon(Icons.clear_all,
                                      color: Colors.grey[500], size: 12),
                                  const SizedBox(width: 6),
                                  Text('إظهار الكل',
                                      style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          color: Colors.grey[400])),
                                ],
                              )),
                          ...uniqueValues.map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v,
                                    style: GoogleFonts.cairo(fontSize: 10),
                                    overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) =>
                            setState(() => _columnFilters[key] = v ?? ''),
                      ),
                    ),
                  )
                : Center(
                    child: Text('-',
                        style: GoogleFonts.cairo(
                            color: Colors.grey[700], fontSize: 10)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProDataCell(Map<String, dynamic> data, String key) {
    final value = data[key];
    String displayValue;
    Color textColor = Colors.grey[300]!;
    FontWeight fontWeight = FontWeight.normal;

    if (value is int) {
      if (key == 'quantity') {
        displayValue = '${_formatNumber(value)} لتر';
        textColor = AppColors.getAccent(context);
        fontWeight = FontWeight.bold;
      } else if (key == 'cost') {
        displayValue = value > 0 ? '${_formatNumber(value)} د.ع' : '-';
        textColor = value > 0 ? const Color(0xFFF59E0B) : Colors.grey[600]!;
        fontWeight = value > 0 ? FontWeight.bold : FontWeight.normal;
      } else if (key == 'price') {
        displayValue = value > 0 ? '$value' : '-';
        textColor = value > 0 ? const Color(0xFF3B82F6) : Colors.grey[600]!;
      } else {
        displayValue = value.toString();
      }
    } else {
      displayValue = value?.toString() ?? '-';
      if (displayValue.isEmpty) displayValue = '-';
      if (displayValue == '-') textColor = Colors.grey[600]!;
    }

    // Special styling for color column
    if (key == 'color' && displayValue != '-') {
      return Center(child: _colorBadge(displayValue));
    }

    return Center(
      child: Text(displayValue,
          style: GoogleFonts.cairo(
              color: textColor, fontSize: 13, fontWeight: fontWeight),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis),
    );
  }

  Widget _headerButton(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showDatePicker() {
    // Get unique dates from data
    final uniqueDates =
        _incomingData.map((e) => e['date'] as String).toSet().toList();
    final searchController = TextEditingController();
    List<String> filteredDates = List.from(uniqueDates);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E2127),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 320,
            height: 450,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('اختر التاريخ',
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.grey, size: 20),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 12),
                // Manual date search field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF252830),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2D3748)),
                  ),
                  child: TextField(
                    controller: searchController,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن تاريخ (مثال: 1/24/2026)',
                      hintStyle: GoogleFonts.cairo(
                          color: Colors.grey[600], fontSize: 12),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.grey, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value.isEmpty) {
                          filteredDates = List.from(uniqueDates);
                        } else {
                          filteredDates = uniqueDates
                              .where((d) => d.contains(value))
                              .toList();
                        }
                      });
                    },
                    onSubmitted: (value) {
                      // Allow manual date entry
                      if (value.isNotEmpty && uniqueDates.contains(value)) {
                        setState(() => _selectedDate = value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Scrollable date list (max 6 visible)
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredDates.length,
                    itemBuilder: (context, index) {
                      final date = filteredDates[index];
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedDate = date);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _selectedDate == date
                                ? AppColors.getAccent(context).withValues(alpha: 0.2)
                                : const Color(0xFF252830),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _selectedDate == date
                                    ? AppColors.getAccent(context)
                                    : const Color(0xFF2D3748)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(date,
                                  style: GoogleFonts.cairo(
                                      color: _selectedDate == date
                                          ? AppColors.getAccent(context)
                                          : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              if (_selectedDate == date)
                                Icon(Icons.check_circle,
                                    color: AppColors.getAccent(context), size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color, String change) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2127),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2D3748)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (change.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Icon(Icons.trending_up,
                            color: const Color(0xFF10B981), size: 12),
                        const SizedBox(width: 4),
                        Text(change,
                            style: GoogleFonts.cairo(
                                color: const Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(title,
                style:
                    GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final Map<String, int> totals = {};
    final Map<String, int> counts = {};
    for (var item in _incomingData) {
      final supplier = item['supplier'] as String;
      totals[supplier] = (totals[supplier] ?? 0) + (item['quantity'] as int);
      counts[supplier] = (counts[supplier] ?? 0) + 1;
    }

    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      AppColors.getAccent(context),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899)
    ];
    final maxValue = sortedEntries.first.value.toDouble();

    return Column(
      children: [
        // Chart bars with full names
        ...sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final supplier = entry.value.key;
          final quantity = entry.value.value;
          final percentage = (quantity / maxValue * 100).round();
          final color = colors[index % colors.length];
          final shipments = counts[supplier] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(supplier,
                                style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('$shipments شحنة',
                              style: GoogleFonts.cairo(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Text(_formatNumber(quantity),
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        Text(' لتر',
                            style: GoogleFonts.cairo(
                                color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: const Color(0xFF2D3748),
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.6)]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                          widthFactor: percentage / 100,
                          alignment: Alignment.centerRight),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: percentage / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                color,
                                color.withValues(alpha: 0.7)
                              ]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        // Summary row
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF252830),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chartStat(
                  'إجمالي الكمية',
                  '${_formatNumber(totals.values.reduce((a, b) => a + b))} لتر',
                  Icons.water_drop),
              Container(width: 1, height: 30, color: const Color(0xFF3D4450)),
              _chartStat('عدد الموردين', '${totals.length}', Icons.business),
              Container(width: 1, height: 30, color: const Color(0xFF3D4450)),
              _chartStat('عدد الشحنات', '${_incomingData.length}',
                  Icons.local_shipping),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[500], size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style:
                    GoogleFonts.cairo(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 11)),
      ],
    );
  }

  Widget _buildLineChart() {
    // Build chart data from filtered dashboard data
    final data = _dashboardData;
    if (data.isEmpty) {
      return Center(
          child: Text('لا توجد بيانات لهذا التاريخ',
              style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 14)));
    }

    // Group by supplier and calculate totals
    final Map<String, int> quantityBySupplier = {};
    final Map<String, int> costBySupplier = {};
    for (var item in data) {
      final supplier = item['supplier'] as String;
      final qty = item['quantity'];
      final cst = item['cost'];
      quantityBySupplier[supplier] =
          (quantityBySupplier[supplier] ?? 0) + (qty is num ? qty.toInt() : 0);
      costBySupplier[supplier] =
          (costBySupplier[supplier] ?? 0) + (cst is num ? cst.toInt() : 0);
    }

    final suppliers = quantityBySupplier.keys.toList();
    final maxQuantity =
        quantityBySupplier.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxCost = costBySupplier.values.fold<int>(0, (a, b) => a > b ? a : b);

    // Normalize cost to same scale as quantity for display
    final scaleFactor =
        maxQuantity > 0 && maxCost > 0 ? maxQuantity / maxCost : 1.0;

    final quantitySpots = suppliers
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), quantityBySupplier[e.value]!.toDouble()))
        .toList();

    final costSpots = suppliers
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(),
            (costBySupplier[e.value]! * scaleFactor).toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxQuantity > 0 ? maxQuantity / 4 : 1000,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: const Color(0xFF2D3748), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) {
                final index = v.toInt();
                if (index >= 0 && index < suppliers.length) {
                  // Shorten supplier name for display
                  String name = suppliers[index];
                  if (name.length > 8) name = '${name.substring(0, 8)}...';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(name,
                        style: GoogleFonts.cairo(
                            color: Colors.grey[600], fontSize: 9),
                        textAlign: TextAlign.center),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxQuantity * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: quantitySpots,
            isCurved: true,
            color: AppColors.getAccent(context),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 5,
                color: AppColors.getAccent(context),
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.getAccent(context).withValues(alpha: 0.3),
                  AppColors.getAccent(context).withValues(alpha: 0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: costSpots,
            isCurved: true,
            color: const Color(0xFFEC4899),
            barWidth: 2,
            dashArray: [5, 5],
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            maxContentWidth: 200,
            getTooltipColor: (touchedSpot) => const Color(0xFF252830),
            tooltipRoundedRadius: 12,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.toInt();
                final supplierName =
                    index < suppliers.length ? suppliers[index] : '';
                final isQuantity = spot.barIndex == 0;
                final value = isQuantity
                    ? quantityBySupplier[supplierName] ?? 0
                    : costBySupplier[supplierName] ?? 0;
                return LineTooltipItem(
                  '$supplierName\n${isQuantity ? 'الكمية' : 'التكلفة'}: ${_formatNumber(value)} ${isQuantity ? 'لتر' : 'د.ع'}',
                  GoogleFonts.cairo(
                      color: spot.bar.color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
      duration: const Duration(milliseconds: 800),
    );
  }

  Widget _buildPieChart() {
    final Map<String, int> totals = {};
    for (var item in _dashboardData) {
      final qty = item['quantity'];
      totals[item['supplier'] as String] =
          (totals[item['supplier']] ?? 0) + (qty is num ? qty.toInt() : 0);
    }

    if (totals.isEmpty) {
      return Center(
          child: Text('لا توجد بيانات',
              style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 12)));
    }

    final colors = [
      AppColors.getAccent(context),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6)
    ];
    final total = totals.values.fold<int>(0, (a, b) => a + b);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (event is FlTapUpEvent &&
                      pieTouchResponse?.touchedSection != null) {
                    final index =
                        pieTouchResponse!.touchedSection!.touchedSectionIndex;
                    if (index >= 0) {
                      final supplierName = totals.keys.toList()[index];
                      _showSupplierDetailsDialog(supplierName);
                    }
                  }
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 28,
              sections: totals.entries.toList().asMap().entries.map((entry) {
                final percent = (entry.value.value / total * 100).round();
                return PieChartSectionData(
                  color: colors[entry.key % colors.length],
                  value: entry.value.value.toDouble(),
                  title: '$percent%',
                  radius: 25,
                  titleStyle: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: totals.entries.toList().asMap().entries.map((entry) {
              final percent = (entry.value.value / total * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  onTap: () => _showSupplierDetailsDialog(entry.value.key),
                  child: Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: colors[entry.key % colors.length],
                              shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(entry.value.key,
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[300], fontSize: 10),
                              overflow: TextOverflow.ellipsis)),
                      Text('$percent%',
                          style: GoogleFonts.cairo(
                              color: colors[entry.key % colors.length],
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showSupplierDetailsDialog(String supplierName) {
    final supplierData = _incomingData
        .where((item) => item['supplier'] == supplierName)
        .toList();
    final totalQty = supplierData.fold<int>(0, (sum, item) {
      final v = item['quantity'];
      return sum + (v is num ? v.toInt() : 0);
    });
    final totalCost = supplierData.fold<int>(0, (sum, item) {
      final q = item['quantity'];
      final p = item['price'];
      return sum + ((q is num ? q.toInt() : 0) * (p is num ? p.toInt() : 0));
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E2127),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.getAccent(context).withValues(alpha: 0.3),
                      const Color(0xFF1E2127)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.getAccent(context).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.business,
                          color: AppColors.getAccent(context), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(supplierName,
                              style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('تفاصيل الشحنات الواردة',
                              style: GoogleFonts.cairo(
                                  fontSize: 12, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.grey[800], shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Stats Row
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildStatCard('عدد الشحنات', '${supplierData.length}',
                        Icons.local_shipping, AppColors.getAccent(context)),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'إجمالي الكمية',
                        '${_formatNumber(totalQty)} لتر',
                        Icons.water_drop,
                        const Color(0xFF3B82F6)),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'إجمالي التكلفة',
                        '${_formatNumber(totalCost)} د.ع',
                        Icons.payments,
                        const Color(0xFFF59E0B)),
                  ],
                ),
              ),

              // Table Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.table_chart,
                            color: Colors.grey[500], size: 18),
                        const SizedBox(width: 8),
                        Text('جدول الشحنات',
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252830),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2D3748)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          child: Table(
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                  color: const Color(0xFF2D3748)
                                      .withValues(alpha: 0.5),
                                  width: 0.5),
                            ),
                            children: [
                              TableRow(
                                decoration:
                                    BoxDecoration(color: Color(0xFF1E2127)),
                                children: [
                                  'التاريخ',
                                  'الكمية',
                                  'السعر',
                                  'الكثافة'
                                ]
                                    .map((h) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Text(h,
                                              style: GoogleFonts.cairo(
                                                  color: AppColors.getAccent(context),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center),
                                        ))
                                    .toList(),
                              ),
                              ...supplierData.asMap().entries.map((entry) {
                                final d = entry.value;
                                final isOdd = entry.key % 2 == 1;
                                return TableRow(
                                  decoration: BoxDecoration(
                                      color: isOdd
                                          ? const Color(0xFF1E2127)
                                          : const Color(0xFF252830)),
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Text(d['date'],
                                            style: GoogleFonts.cairo(
                                                color: Colors.white,
                                                fontSize: 12),
                                            textAlign: TextAlign.center)),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Text(
                                            '${_formatNumber(d['quantity'])} لتر',
                                            style: GoogleFonts.cairo(
                                                color: AppColors.getAccent(context),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Text('${d['price']}',
                                            style: GoogleFonts.cairo(
                                                color: const Color(0xFFF59E0B),
                                                fontSize: 12),
                                            textAlign: TextAlign.center)),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Text(
                                            d['density']?.toString() ?? '-',
                                            style: GoogleFonts.cairo(
                                                color: Colors.grey[400],
                                                fontSize: 12),
                                            textAlign: TextAlign.center)),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style:
                    GoogleFonts.cairo(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _dialogStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 10)),
      ],
    );
  }

  Widget _buildTopSuppliersList() {
    final Map<String, int> counts = {};
    for (var item in _dashboardData) {
      counts[item['supplier'] as String] = (counts[item['supplier']] ?? 0) + 1;
    }
    final sortedSuppliers = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      AppColors.getAccent(context),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6)
    ];

    return Row(
      children: sortedSuppliers.take(4).toList().asMap().entries.map((entry) {
        final color = colors[entry.key % colors.length];
        final name = entry.value.key;
        final count = entry.value.value;
        return Expanded(
          child: InkWell(
            onTap: () => _showSupplierDetailsDialog(name),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(name,
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$count شحنة',
                        style: GoogleFonts.cairo(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart() {
    final Map<String, int> counts = {};
    for (var item in _incomingData) {
      counts[item['supplier'] as String] = (counts[item['supplier']] ?? 0) + 1;
    }
    final colors = [
      AppColors.getAccent(context),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6)
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: counts.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.3,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: counts.entries.toList().asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value.toDouble(),
                gradient: LinearGradient(colors: [
                  colors[e.key % colors.length],
                  colors[e.key % colors.length].withValues(alpha: 0.6)
                ], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                width: 18,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 800),
    );
  }

  Widget _colorBadge(String c) {
    Color bg = c == 'عسلي'
        ? const Color(0xFFF59E0B)
        : c == 'نفط ابيض'
            ? Colors.blueGrey
            : AppColors.getInfo(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8)),
      child: Text(c,
          style: GoogleFonts.cairo(
              color: bg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _formatNumber(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  // دالة لإظهار نافذة تسجيل الدخول لقاعدة البيانات
  void _showDatabaseLoginDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2127),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.lock, color: Color(0xFF8B5CF6), size: 24),
              ),
              const SizedBox(width: 12),
              Text('صلاحية الدخول',
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  style: GoogleFonts.cairo(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'اسم المستخدم',
                    labelStyle: GoogleFonts.cairo(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.person, color: Color(0xFF8B5CF6)),
                    filled: true,
                    fillColor: const Color(0xFF252830),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: GoogleFonts.cairo(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle: GoogleFonts.cairo(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.vpn_key, color: Color(0xFF8B5CF6)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFF252830),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء',
                  style:
                      GoogleFonts.cairo(color: Colors.white70, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                if (usernameController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _showDatabaseDialog(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('الرجاء إدخال اسم المستخدم وكلمة المرور',
                          style: GoogleFonts.cairo()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('دخول',
                  style: GoogleFonts.cairo(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لإظهار نافذة قاعدة البيانات مع الفلاتر
  void _showDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E2127),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storage,
                          color: Color(0xFF8B5CF6), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('قاعدة البيانات الكاملة',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildDatabaseTable(setDialogState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // بناء جدول قاعدة البيانات مع الفلاتر
  Widget _buildDatabaseTable(StateSetter setDialogState) {
    final columns = [
      {'key': 'date', 'label': 'التاريخ', 'width': 100.0},
      {'key': 'supplier', 'label': 'المورد', 'width': 180.0},
      {'key': 'company', 'label': 'الشركة', 'width': 180.0},
      {'key': 'quantity', 'label': 'الكمية', 'width': 100.0},
      {'key': 'density', 'label': 'الكثافة', 'width': 80.0},
      {'key': 'color', 'label': 'اللون', 'width': 100.0},
      {'key': 'voucher', 'label': 'رقم الوصل', 'width': 120.0},
      {'key': 'price', 'label': 'السعر', 'width': 100.0},
      {'key': 'cost', 'label': 'الكلفة', 'width': 120.0},
      {'key': 'driver', 'label': 'السائق', 'width': 150.0},
      {'key': 'vehicleNo', 'label': 'رقم المركبة', 'width': 120.0},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252830),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2127),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt,
                    color: Color(0xFF8B5CF6), size: 20),
                const SizedBox(width: 8),
                Text('الفلاتر',
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_dbColumnFilters.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() {
                        _dbColumnFilters.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all,
                        size: 18, color: Colors.red),
                    label: Text('مسح الفلاتر',
                        style:
                            GoogleFonts.cairo(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowHeight: 100,
                  dataRowHeight: 55,
                  headingRowColor: WidgetStateProperty.all(
                      const Color(0xFF8B5CF6).withValues(alpha: 0.15)),
                  columns: columns.map((col) {
                    return DataColumn(
                      label: SizedBox(
                        width: col['width'] as double,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              col['label'] as String,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 35,
                              child: TextField(
                                onChanged: (value) {
                                  setDialogState(() {
                                    if (value.isEmpty) {
                                      _dbColumnFilters.remove(col['key']);
                                    } else {
                                      _dbColumnFilters[col['key'] as String] =
                                          value;
                                    }
                                  });
                                },
                                style: GoogleFonts.cairo(
                                    color: Colors.white, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'بحث...',
                                  hintStyle: GoogleFonts.cairo(
                                      color: Colors.white38, fontSize: 11),
                                  filled: true,
                                  fillColor: const Color(0xFF252830),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.search,
                                      size: 16, color: Colors.white38),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  rows: _databaseFilteredData.map((item) {
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color>((states) {
                        if (_databaseFilteredData.indexOf(item) % 2 == 0) {
                          return Colors.white.withValues(alpha: 0.03);
                        }
                        return Colors.transparent;
                      }),
                      cells: columns.map((col) {
                        final key = col['key'] as String;
                        final value = item[key];
                        String displayValue = '';

                        if (value is int || value is double) {
                          if (value != 0) {
                            displayValue = _formatNumber(
                                value is int ? value : value.toInt());
                          }
                        } else {
                          displayValue = value.toString();
                        }

                        return DataCell(
                          SizedBox(
                            width: col['width'] as double,
                            child: Text(
                              displayValue,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة لإظهار نافذة إضافة البيانات
  void _showAddDataDialog(BuildContext context) {
    final supplierController = TextEditingController();
    final companyController = TextEditingController();
    final quantityController = TextEditingController();
    final densityController = TextEditingController();
    final colorController = TextEditingController();
    final voucherController = TextEditingController();
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final driverController = TextEditingController();
    final vehicleNoController = TextEditingController();
    final dateController = TextEditingController(text: _lastUpdateDate);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E2127),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.getAccent(context).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(Icons.add_box, color: AppColors.getAccent(context), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('إضافة بيانات جديدة',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252830),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInputField('المورد',
                                        supplierController, Icons.business)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('الشركة',
                                        companyController, Icons.factory)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInputField('الكمية',
                                        quantityController, Icons.water_drop,
                                        isNumber: true)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('الكثافة',
                                        densityController, Icons.compress,
                                        isNumber: true)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('اللون',
                                        colorController, Icons.palette)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInputField('رقم الوصل',
                                        voucherController, Icons.receipt)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('السعر',
                                        priceController, Icons.attach_money,
                                        isNumber: true)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('الكلفة',
                                        costController, Icons.monetization_on,
                                        isNumber: true)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInputField('السائق',
                                        driverController, Icons.person)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField(
                                        'رقم المركبة',
                                        vehicleNoController,
                                        Icons.directions_car)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('التاريخ',
                                        dateController, Icons.calendar_today)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _incomingData.add({
                                    'supplier': supplierController.text,
                                    'company': companyController.text,
                                    'quantity':
                                        int.tryParse(quantityController.text) ??
                                            0,
                                    'density': densityController.text.isEmpty
                                        ? ''
                                        : int.tryParse(
                                                densityController.text) ??
                                            0,
                                    'color': colorController.text,
                                    'voucher': voucherController.text,
                                    'price':
                                        int.tryParse(priceController.text) ?? 0,
                                    'cost':
                                        int.tryParse(costController.text) ?? 0,
                                    'driver': driverController.text,
                                    'vehicleNo': vehicleNoController.text,
                                    'date': dateController.text,
                                  });
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم إضافة البيانات بنجاح',
                                        style: GoogleFonts.cairo()),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check, size: 20),
                              label: Text('حفظ البيانات',
                                  style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.getAccent(context),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF252830),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                children: [
                                  Icon(Icons.preview,
                                      color: AppColors.getAccent(context), size: 20),
                                  const SizedBox(width: 10),
                                  Text('معاينة البيانات المضافة',
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            _buildPreviewTable(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label, TextEditingController controller, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.getAccent(context), size: 20),
        filled: true,
        fillColor: const Color(0xFF1E2127),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.getAccent(context), width: 2),
        ),
      ),
    );
  }

  Widget _buildPreviewTable() {
    final columns = [
      {'key': 'date', 'label': 'التاريخ', 'width': 100.0},
      {'key': 'supplier', 'label': 'المورد', 'width': 180.0},
      {'key': 'company', 'label': 'الشركة', 'width': 180.0},
      {'key': 'quantity', 'label': 'الكمية', 'width': 100.0},
      {'key': 'density', 'label': 'الكثافة', 'width': 80.0},
      {'key': 'color', 'label': 'اللون', 'width': 100.0},
      {'key': 'voucher', 'label': 'رقم الوصل', 'width': 120.0},
      {'key': 'price', 'label': 'السعر', 'width': 100.0},
      {'key': 'cost', 'label': 'الكلفة', 'width': 120.0},
      {'key': 'driver', 'label': 'السائق', 'width': 150.0},
      {'key': 'vehicleNo', 'label': 'رقم المركبة', 'width': 120.0},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowHeight: 55,
        dataRowHeight: 50,
        headingRowColor:
            WidgetStateProperty.all(AppColors.getAccent(context).withValues(alpha: 0.15)),
        columns: columns.map((col) {
          return DataColumn(
            label: SizedBox(
              width: col['width'] as double,
              child: Text(
                col['label'] as String,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }).toList(),
        rows: _mainTableData.map((item) {
          return DataRow(
            color: WidgetStateProperty.resolveWith<Color>((states) {
              if (_mainTableData.indexOf(item) % 2 == 0) {
                return Colors.white.withValues(alpha: 0.03);
              }
              return Colors.transparent;
            }),
            cells: columns.map((col) {
              final key = col['key'] as String;
              final value = item[key];
              String displayValue = '';

              if (value is int || value is double) {
                if (value != 0) {
                  displayValue =
                      _formatNumber(value is int ? value : value.toInt());
                }
              } else {
                displayValue = value.toString();
              }

              return DataCell(
                SizedBox(
                  width: col['width'] as double,
                  child: Text(
                    displayValue,
                    style: GoogleFonts.cairo(
                        color: AppColors.getTextPrimary(context), fontSize: 12),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

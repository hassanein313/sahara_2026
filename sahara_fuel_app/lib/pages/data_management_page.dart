import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import '../constants/app_colors.dart';
import '../providers/fuel_provider.dart';
import '../services/api_service.dart';

/// صفحة إدارة البيانات — إدخال يدوي + رفع ملفات + بيانات تجريبية
class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});
  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _api = ApiService();
  bool _loading = false;
  String? _resultMessage;
  bool _resultSuccess = false;

  // ===== حقول إدخال معاملة وقود =====
  final _fuelTypeCtrl = TextEditingController(text: 'incoming');
  final _fuelKindCtrl = TextEditingController(text: 'benzene');
  final _quantityCtrl = TextEditingController();
  final _unitPriceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _truckCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // ===== حقول إدخال خزان =====
  final _tankNameCtrl = TextEditingController();
  final _tankFuelTypeCtrl = TextEditingController(text: 'benzene');
  final _tankCapacityCtrl = TextEditingController();
  final _tankCurrentLevelCtrl = TextEditingController();
  final _tankLocationCtrl = TextEditingController();

  // ===== حقل رفع JSON =====
  final _jsonCtrl = TextEditingController();

  String _selectedTank = '';
  List<Map<String, dynamic>> _availableTanks = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadTanks();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _fuelTypeCtrl.dispose();
    _fuelKindCtrl.dispose();
    _quantityCtrl.dispose();
    _unitPriceCtrl.dispose();
    _supplierCtrl.dispose();
    _driverCtrl.dispose();
    _truckCtrl.dispose();
    _notesCtrl.dispose();
    _tankNameCtrl.dispose();
    _tankFuelTypeCtrl.dispose();
    _tankCapacityCtrl.dispose();
    _tankCurrentLevelCtrl.dispose();
    _tankLocationCtrl.dispose();
    _jsonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTanks() async {
    final res = await _api.getTanks();
    if (res.success && res.data != null) {
      setState(() {
        _availableTanks = List<Map<String, dynamic>>.from(res.data);
        if (_availableTanks.isNotEmpty)
          _selectedTank = _availableTanks.first['id'];
      });
    }
  }

  void _showResult(String msg, bool success) {
    setState(() {
      _resultMessage = msg;
      _resultSuccess = success;
    });
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _resultMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
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
                  child: Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('إدارة البيانات',
                          style: GoogleFonts.cairo(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextPrimary(context))),
                      Text('إدخال يدوي • رفع ملفات • بيانات تجريبية',
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: AppColors.getSubtleText(context))),
                    ]),
                    const Spacer(),
                    // زر الاتصال بالسيرفر
                    FutureBuilder<bool>(
                    future: _api.checkHealth(),
                    builder: (c, snap) {
                      final ok = snap.data == true;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: (ok
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: ok
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                              ok
                                  ? 'متصل بالسيرفر'
                                  : snap.connectionState ==
                                          ConnectionState.waiting
                                      ? 'جاري الفحص...'
                                      : 'غير متصل',
                              style: GoogleFonts.cairo(
                                  color: ok
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      );
                    }),
              ])),
          const SizedBox(height: 16),

          // ===== رسالة النتيجة =====
          if (_resultMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_resultSuccess
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444))
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: (_resultSuccess
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(_resultSuccess ? Icons.check_circle : Icons.error,
                    color: _resultSuccess
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(_resultMessage!,
                        style: GoogleFonts.cairo(
                            color: AppColors.getTextPrimary(context), fontSize: 13))),
                GestureDetector(
                    onTap: () => setState(() => _resultMessage = null),
                    child:
                        const Icon(Icons.close, color: Colors.grey, size: 18)),
              ]),
            ),
          const SizedBox(height: 12),

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
                    unselectedLabelColor: AppColors.getSubtleText(context),
                    labelStyle: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 11),
                    unselectedLabelStyle: GoogleFonts.cairo(fontSize: 10),
                    tabs: const [
                      Tab(text: 'إضافة معاملة'),
                      Tab(text: 'إضافة خزان'),
                      Tab(text: 'رفع بيانات JSON'),
                      Tab(text: 'بيانات تجريبية')
                    ]),
              )),
          const SizedBox(height: 16),

          // ===== محتوى التابات =====
          Expanded(
              child: TabBarView(controller: _tabCtrl, children: [
            _buildFuelTransactionTab(),
            _buildTankTab(),
            _buildJsonImportTab(),
            _buildSeedTab(),
          ])),
        ]),
      ),
    );
      },
    );
  }

  // ================================================================
  //  تاب 1: إضافة معاملة وقود يدوياً
  // ================================================================
  Widget _buildFuelTransactionTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _formCard(
          icon: Icons.local_gas_station,
          title: 'إضافة معاملة وقود جديدة',
          subtitle: 'أدخل بيانات الشحنة أو الصادر',
          children: [
            Row(children: [
              Expanded(
                  child: _dropdownField(
                      'نوع المعاملة',
                      _fuelTypeCtrl.text,
                      {
                        'incoming': 'وارد (استلام)',
                        'outgoing': 'صادر (توزيع)',
                        'transfer': 'تحويل بين خزانات'
                      },
                      (v) => setState(() => _fuelTypeCtrl.text = v))),
              const SizedBox(width: 16),
              Expanded(
                  child: _dropdownField(
                      'نوع الوقود',
                      _fuelKindCtrl.text,
                      {
                        'benzene': 'بنزين',
                        'diesel': 'ديزل',
                        'kerosene': 'كيروسين',
                        'gas': 'غاز'
                      },
                      (v) => setState(() => _fuelKindCtrl.text = v))),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _textField(
                      'الكمية (لتر)', _quantityCtrl, Icons.straighten,
                      isNumber: true)),
              const SizedBox(width: 16),
              Expanded(
                  child: _textField(
                      'سعر الوحدة', _unitPriceCtrl, Icons.attach_money,
                      isNumber: true)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child:
                      _textField('اسم المورّد', _supplierCtrl, Icons.business)),
              const SizedBox(width: 16),
              Expanded(child: _tankDropdown()),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _textField('اسم السائق', _driverCtrl, Icons.person)),
              const SizedBox(width: 16),
              Expanded(
                  child: _textField(
                      'رقم الشاحنة', _truckCtrl, Icons.local_shipping)),
            ]),
            const SizedBox(height: 16),
            _textField('ملاحظات', _notesCtrl, Icons.note, maxLines: 2),
            const SizedBox(height: 24),
            _submitButton(
                'إضافة المعاملة', Icons.add_circle, _submitFuelTransaction),
          ],
        ));
  }

  Future<void> _submitFuelTransaction() async {
    if (_quantityCtrl.text.isEmpty) {
      _showResult('⚠️ يجب إدخال الكمية', false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _api.createFuelTransaction(
        type: _fuelTypeCtrl.text,
        fuelType: _fuelKindCtrl.text,
        quantity: double.parse(_quantityCtrl.text),
        unitPrice: _unitPriceCtrl.text.isNotEmpty ? double.parse(_unitPriceCtrl.text) : null,
        supplier: _supplierCtrl.text.isNotEmpty ? _supplierCtrl.text : null,
        tankId: _selectedTank.isNotEmpty ? _selectedTank : null,
        driverName: _driverCtrl.text.isNotEmpty ? _driverCtrl.text : null,
        truckNumber: _truckCtrl.text.isNotEmpty ? _truckCtrl.text : null,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      );
      if (res.success) {
        _showResult(
            '✅ تم إضافة المعاملة بنجاح — ${_quantityCtrl.text} لتر ${_fuelKindCtrl.text}',
            true);
        _quantityCtrl.clear();
        _unitPriceCtrl.clear();
        _supplierCtrl.clear();
        _driverCtrl.clear();
        _truckCtrl.clear();
        _notesCtrl.clear();
        _loadTanks(); // تحديث الخزانات
      } else {
        _showResult('❌ فشل: ${res.error}', false);
      }
    } catch (e) {
      _showResult('❌ خطأ: $e', false);
    }
    setState(() => _loading = false);
  }

  // ================================================================
  //  تاب 2: إضافة خزان
  // ================================================================
  Widget _buildTankTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _formCard(
          icon: Icons.propane_tank,
          title: 'إضافة خزان جديد',
          subtitle: 'تسجيل خزان وقود في النظام',
          children: [
            Row(children: [
              Expanded(
                  child: _textField('اسم الخزان', _tankNameCtrl, Icons.label)),
              const SizedBox(width: 16),
              Expanded(
                  child: _dropdownField(
                      'نوع الوقود',
                      _tankFuelTypeCtrl.text,
                      {
                        'benzene': 'بنزين',
                        'diesel': 'ديزل',
                        'kerosene': 'كيروسين',
                        'gas': 'غاز'
                      },
                      (v) => setState(() => _tankFuelTypeCtrl.text = v))),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _textField(
                      'السعة الكلية (لتر)', _tankCapacityCtrl, Icons.storage,
                      isNumber: true)),
              const SizedBox(width: 16),
              Expanded(
                  child: _textField('المستوى الحالي (لتر)',
                      _tankCurrentLevelCtrl, Icons.water,
                      isNumber: true)),
            ]),
            const SizedBox(height: 16),
            _textField('الموقع', _tankLocationCtrl, Icons.location_on),
            const SizedBox(height: 24),
            _submitButton('إضافة الخزان', Icons.add_circle, _submitTank),
          ],
        ));
  }

  Future<void> _submitTank() async {
    if (_tankNameCtrl.text.isEmpty || _tankCapacityCtrl.text.isEmpty) {
      _showResult('⚠️ يجب إدخال اسم الخزان والسعة', false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _api.createTank(
        name: _tankNameCtrl.text,
        fuelType: _tankFuelTypeCtrl.text,
        capacity: double.parse(_tankCapacityCtrl.text),
        currentLevel: _tankCurrentLevelCtrl.text.isNotEmpty ? double.parse(_tankCurrentLevelCtrl.text) : null,
        location: _tankLocationCtrl.text.isNotEmpty ? _tankLocationCtrl.text : null,
      );
      if (res.success) {
        _showResult('✅ تم إضافة الخزان "${_tankNameCtrl.text}" بنجاح', true);
        _tankNameCtrl.clear();
        _tankCapacityCtrl.clear();
        _tankCurrentLevelCtrl.clear();
        _tankLocationCtrl.clear();
        _loadTanks();
      } else {
        _showResult('❌ فشل: ${res.error}', false);
      }
    } catch (e) {
      _showResult('❌ خطأ: $e', false);
    }
    setState(() => _loading = false);
  }

  // ================================================================
  //  تاب 3: رفع بيانات JSON
  // ================================================================
  Widget _buildJsonImportTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          _formCard(
            icon: Icons.upload_file,
            title: 'استيراد بيانات من JSON',
            subtitle: 'الصق بيانات JSON لاستيراد معاملات أو خزانات',
            children: [
              // مثال التنسيق
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.info_outline,
                            color: AppColors.getAccent(context), size: 16),
                        const SizedBox(width: 8),
                        Text('تنسيق البيانات المطلوب:',
                            style: GoogleFonts.cairo(
                                color: AppColors.getAccent(context),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.getSurface(context),
                            borderRadius: BorderRadius.circular(8)),
                        child: SelectableText(
                          '[\n'
                          '  {\n'
                          '    "type": "incoming",\n'
                          '    "fuel_type": "benzene",\n'
                          '    "quantity": 5000,\n'
                          '    "unit_price": 650,\n'
                          '    "supplier": "شركة النفط",\n'
                          '    "date": "2026-02-15",\n'
                          '    "driver_name": "أحمد",\n'
                          '    "notes": "شحنة صباحية"\n'
                          '  }\n'
                          ']',
                          style: GoogleFonts.firaCode(
                              color: AppColors.getSubtleText(context), fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'الحقول المطلوبة: type (incoming/outgoing) • fuel_type (benzene/diesel/kerosene/gas) • quantity',
                          style: GoogleFonts.cairo(
                              color: AppColors.getSubtleText(context), fontSize: 10)),
                    ]),
              ),
              const SizedBox(height: 16),
              // حقل الإدخال
              Container(
                decoration: BoxDecoration(
                    color: const Color(0xFF0F1923),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2D3748))),
                child: TextField(
                  controller: _jsonCtrl,
                  maxLines: 10,
                  style:
                      GoogleFonts.firaCode(color: AppColors.getTextPrimary(context), fontSize: 12),
                  decoration: InputDecoration(
                    hintText:
                        'الصق بيانات JSON هنا...\n\nأو استخدم التنسيق أعلاه',
                    hintStyle: GoogleFonts.cairo(
                        color: AppColors.getSubtleText(context), fontSize: 12),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _submitButton('استيراد كمعاملات وقود',
                        Icons.local_gas_station, _importFuelJson)),
                const SizedBox(width: 12),
                Expanded(
                    child: _actionButton('استيراد كخزانات', Icons.propane_tank,
                        const Color(0xFF8B5CF6), _importTanksJson)),
              ]),
            ],
          ),
          const SizedBox(height: 16),

          // أمثلة سريعة
          _formCard(
              icon: Icons.content_paste,
              title: 'أمثلة جاهزة للنسخ',
              subtitle: 'انقر لنسخ المثال في حقل الإدخال',
              children: [
                _exampleTile('5 شحنات بنزين واردة', _fuelExampleJson()),
                const SizedBox(height: 8),
                _exampleTile('3 خزانات جديدة', _tanksExampleJson()),
              ]),
          const SizedBox(height: 24),
        ]));
  }

  Future<void> _importFuelJson() async {
    if (_jsonCtrl.text.trim().isEmpty) {
      _showResult('⚠️ الصق بيانات JSON أولاً', false);
      return;
    }
    setState(() => _loading = true);
    try {
      final records =
          List<Map<String, dynamic>>.from(jsonDecode(_jsonCtrl.text));
      final res = await _api.importFuelRecords(records);
      if (res.success) {
        final data = res.data;
        _showResult(
            '✅ تم استيراد ${data['imported']} معاملة بنجاح${data['skipped'] > 0 ? ' (تم تخطي ${data['skipped']})' : ''}',
            true);
        _jsonCtrl.clear();
        _loadTanks();
      } else {
        _showResult('❌ فشل: ${res.error}', false);
      }
    } on FormatException {
      _showResult('❌ تنسيق JSON غير صحيح — تأكد من صحة البيانات', false);
    } catch (e) {
      _showResult('❌ خطأ: $e', false);
    }
    setState(() => _loading = false);
  }

  Future<void> _importTanksJson() async {
    if (_jsonCtrl.text.trim().isEmpty) {
      _showResult('⚠️ الصق بيانات JSON أولاً', false);
      return;
    }
    setState(() => _loading = true);
    try {
      final records =
          List<Map<String, dynamic>>.from(jsonDecode(_jsonCtrl.text));
      final res = await _api.importTanks(records);
      if (res.success) {
        _showResult('✅ تم استيراد ${res.data['imported']} خزان بنجاح', true);
        _jsonCtrl.clear();
        _loadTanks();
      } else {
        _showResult('❌ فشل: ${res.error}', false);
      }
    } on FormatException {
      _showResult('❌ تنسيق JSON غير صحيح', false);
    } catch (e) {
      _showResult('❌ خطأ: $e', false);
    }
    setState(() => _loading = false);
  }

  // ================================================================
  //  تاب 4: بيانات تجريبية
  // ================================================================
  Widget _buildSeedTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          _formCard(
            icon: Icons.science,
            title: 'إنشاء بيانات تجريبية',
            subtitle: 'ملء قاعدة البيانات ببيانات واقعية للاختبار',
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  _seedInfoRow(Icons.propane_tank, '5 خزانات',
                      'بنزين، ديزل، كيروسين، غاز'),
                  const SizedBox(height: 12),
                  _seedInfoRow(Icons.receipt_long, '60-120 معاملة',
                      'وارد + صادر لمدة 30 يوم'),
                  const SizedBox(height: 12),
                  _seedInfoRow(Icons.business, 'بيانات واقعية',
                      'موردين، سائقين، شاحنات، أسعار'),
                  const SizedBox(height: 12),
                  _seedInfoRow(Icons.auto_graph, 'إحصائيات',
                      'تنوع يومي في الكميات والأنواع'),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFFA726).withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber,
                      color: Color(0xFFFFA726), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          'سيتم إضافة البيانات التجريبية إلى البيانات الحالية (لن يتم حذف أي بيانات موجودة)',
                          style: GoogleFonts.cairo(
                              color: const Color(0xFFFFA726), fontSize: 11))),
                ]),
              ),
              const SizedBox(height: 20),
              _actionButton(
                '🚀 إنشاء بيانات تجريبية الآن',
                Icons.play_arrow,
                const Color(0xFF10B981),
                _seedDemo,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ]));
  }

  Future<void> _seedDemo() async {
    setState(() => _loading = true);
    try {
      final res = await _api.seedDemoData();
      if (res.success) {
        final data = res.data;
        _showResult(
            '✅ تم إنشاء ${data['tanks']} خزان و ${data['transactions']} معاملة تجريبية بنجاح!',
            true);
        _loadTanks();
      } else {
        _showResult('❌ فشل: ${res.error}', false);
      }
    } catch (e) {
      _showResult('❌ خطأ: $e', false);
    }
    setState(() => _loading = false);
  }

  // ================================================================
  //  العناصر المساعدة (UI widgets)
  // ================================================================

  Widget _formCard(
      {required IconData icon,
      required String title,
      required String subtitle,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D3748))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.getAccent(context).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.getAccent(context), size: 22)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.cairo(
                    color: AppColors.getTextPrimary(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(subtitle,
                style:
                    GoogleFonts.cairo(color: AppColors.getSubtleText(context), fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFF2D3748), height: 1),
        const SizedBox(height: 20),
        ...children,
      ]),
    );
  }

  Widget _textField(String label, TextEditingController ctrl, IconData icon,
      {bool isNumber = false, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.cairo(
              color: AppColors.getSubtleText(context),
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
            color: const Color(0xFF0F1923),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2D3748))),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: GoogleFonts.cairo(color: AppColors.getTextPrimary(context), fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.getSubtleText(context), size: 18),
            hintText: label,
            hintStyle: GoogleFonts.cairo(color: AppColors.getSubtleText(context), fontSize: 12),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: InputBorder.none,
          ),
        ),
      ),
    ]);
  }

  Widget _dropdownField(String label, String value, Map<String, String> options,
      Function(String) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.cairo(
              color: AppColors.getSubtleText(context),
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: const Color(0xFF0F1923),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2D3748))),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.getSurfaceVariant(context),
            style: GoogleFonts.cairo(color: AppColors.getTextPrimary(context), fontSize: 13),
            items: options.entries
                .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value,
                        style: GoogleFonts.cairo(
                            color: AppColors.getTextPrimary(context), fontSize: 12))))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    ]);
  }

  Widget _tankDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('الخزان المستهدف',
          style: GoogleFonts.cairo(
              color: AppColors.getSubtleText(context),
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: const Color(0xFF0F1923),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2D3748))),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedTank.isNotEmpty &&
                    _availableTanks.any((t) => t['id'] == _selectedTank)
                ? _selectedTank
                : null,
            isExpanded: true,
            dropdownColor: AppColors.getSurfaceVariant(context),
            hint: Text('اختر خزان (اختياري)',
                style:
                    GoogleFonts.cairo(color: AppColors.getSubtleText(context), fontSize: 12)),
            style: GoogleFonts.cairo(color: AppColors.getTextPrimary(context), fontSize: 13),
            items: [
              DropdownMenuItem(
                  value: '',
                  child: Text('— بدون خزان —',
                      style: GoogleFonts.cairo(
                          color: AppColors.getSubtleText(context), fontSize: 12))),
              ..._availableTanks.map((t) => DropdownMenuItem(
                    value: t['id'] as String,
                    child: Text('${t['name']} (${t['fuel_type']})',
                        style: GoogleFonts.cairo(
                            color: AppColors.getTextPrimary(context), fontSize: 12)),
                  )),
            ],
            onChanged: (v) => setState(() => _selectedTank = v ?? ''),
          ),
        ),
      ),
    ]);
  }

  Widget _submitButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: _loading
                  ? [AppColors.getSubtleText(context), AppColors.getSubtleText(context)]
                  : [AppColors.getAccent(context), const Color(0xFFF59E0B)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _loading
              ? []
              : [
                  BoxShadow(
                      color: AppColors.getAccent(context).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_loading)
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
          else
            Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_loading)
            SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color))
          else
            Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.cairo(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _seedInfoRow(IconData icon, String title, String desc) {
    return Row(children: [
      Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.getAccent(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.getAccent(context), size: 18)),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.cairo(
                color: AppColors.getTextPrimary(context),
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        Text(desc,
            style: GoogleFonts.cairo(color: AppColors.getSubtleText(context), fontSize: 11)),
      ])),
    ]);
  }

  Widget _exampleTile(String title, String json) {
    return GestureDetector(
      onTap: () => setState(() => _jsonCtrl.text = json),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2D3748))),
        child: Row(children: [
          Icon(Icons.content_copy, color: AppColors.getAccent(context), size: 16),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.cairo(color: AppColors.getTextPrimary(context), fontSize: 12)),
          const Spacer(),
          Text('انقر للنسخ',
              style: GoogleFonts.cairo(color: AppColors.getAccent(context), fontSize: 10)),
        ]),
      ),
    );
  }

  // أمثلة JSON
  String _fuelExampleJson() => const JsonEncoder.withIndent('  ').convert([
        {
          "type": "incoming",
          "fuel_type": "benzene",
          "quantity": 12000,
          "unit_price": 650,
          "supplier": "شركة النفط الوطنية",
          "driver_name": "أحمد محمد",
          "truck_number": "ب-12345",
          "notes": "شحنة صباحية"
        },
        {
          "type": "incoming",
          "fuel_type": "diesel",
          "quantity": 18000,
          "unit_price": 550,
          "supplier": "مصفاة البصرة",
          "driver_name": "حسين علي",
          "truck_number": "ن-67890"
        },
        {
          "type": "outgoing",
          "fuel_type": "benzene",
          "quantity": 5000,
          "notes": "توزيع محطة الشمال"
        },
        {
          "type": "incoming",
          "fuel_type": "kerosene",
          "quantity": 8000,
          "unit_price": 700,
          "supplier": "الشركة العامة"
        },
        {
          "type": "outgoing",
          "fuel_type": "diesel",
          "quantity": 7500,
          "notes": "توزيع محطة الجنوب"
        },
      ]);

  String _tanksExampleJson() => const JsonEncoder.withIndent('  ').convert([
        {
          "name": "خزان بنزين - المحطة الشمالية",
          "fuel_type": "benzene",
          "capacity": 50000,
          "current_level": 32000,
          "location": "المحطة الشمالية"
        },
        {
          "name": "خزان ديزل - المستودع المركزي",
          "fuel_type": "diesel",
          "capacity": 100000,
          "current_level": 75000,
          "location": "المستودع المركزي"
        },
        {
          "name": "خزان غاز - المنطقة الصناعية",
          "fuel_type": "gas",
          "capacity": 30000,
          "current_level": 12000,
          "location": "المنطقة الصناعية"
        },
      ]);
}
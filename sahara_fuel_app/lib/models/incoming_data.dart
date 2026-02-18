
class ReportColumn {
  final String key;
  final String label;
  const ReportColumn({required this.key, required this.label});
}

final List<ReportColumn> reportColumns = [
  ReportColumn(key: 'date', label: 'التاريخ'),
  ReportColumn(key: 'supplier', label: 'المورد'),
  ReportColumn(key: 'vehicle', label: 'رقم العجلة'),
  ReportColumn(key: 'driver', label: 'السائق'),
  ReportColumn(key: 'quantity', label: 'الكمية'),
  ReportColumn(key: 'type', label: 'نوع الوقود'),
  ReportColumn(key: 'cost', label: 'التكلفة'),
  ReportColumn(key: 'price', label: 'سعر اللتر'),
  ReportColumn(key: 'color', label: 'اللون'),
  ReportColumn(key: 'notes', label: 'ملاحظات'),
];

final List<Map<String, dynamic>> incomingDataset = [
  {
    'date': '2/3/2026',
    'supplier': 'مصفى الدورة',
    'vehicle': '15243',
    'driver': 'أحمد حسن',
    'quantity': 36000,
    'type': 'ديزل',
    'cost': 16200000,
    'price': 450,
    'color': 'عسلي',
    'notes': 'واصل'
  },
  {
    'date': '2/3/2026',
    'supplier': 'مصفى بيجي',
    'vehicle': '8821',
    'driver': 'سعدون محمد',
    'quantity': 18000,
    'type': 'بنزين',
    'cost': 8100000,
    'price': 450,
    'color': 'احمر',
    'notes': 'قيد الفحص'
  },
  {
    'date': '1/3/2026',
    'supplier': 'مستودع الفاو',
    'vehicle': '4452',
    'driver': 'كريم جاسم',
    'quantity': 40000,
    'type': 'نفط ابيض',
    'cost': 10000000,
    'price': 250,
    'color': 'نفط ابيض',
    'notes': '-'
  },
  {
    'date': '28/2/2026',
    'supplier': 'مصفى الدورة',
    'vehicle': '6633',
    'driver': 'علي حسين',
    'quantity': 36000,
    'type': 'ديزل',
    'cost': 16200000,
    'price': 450,
    'color': 'اصفر',
    'notes': '-'
  },
  {
    'date': '27/2/2026',
    'supplier': 'مصفى البصرة',
    'vehicle': '1102',
    'driver': 'محمود عباس',
    'quantity': 36000,
    'type': 'ديزل',
    'cost': 15840000,
    'price': 440,
    'color': 'كاز نضيف',
    'notes': 'واصل'
  },
  {
    'date': '25/2/2026',
    'supplier': 'مستودع الناصرية',
    'vehicle': '9988',
    'driver': 'رعد كاظم',
    'quantity': 22000,
    'type': 'بنزين',
    'cost': 9900000,
    'price': 450,
    'color': 'احمر',
    'notes': '-'
  }
];


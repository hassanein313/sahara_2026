import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/license_service.dart';

class AdminLicensePage extends StatefulWidget {
  const AdminLicensePage({super.key});

  @override
  State<AdminLicensePage> createState() => _AdminLicensePageState();
}

class _AdminLicensePageState extends State<AdminLicensePage> {
  final _clientIdController = TextEditingController();
  final _deviceHashController = TextEditingController();
  final _generatedKeyController = TextEditingController(); // لعرض الكود الناتج

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  String _licenseType = 'Trial'; // Trial, Yearly, Lifetime
  int _maxStations = 10;
  int _maxUsers = 5;
  String? _errorMessage;

  void _generateKey() {
    setState(() {
      _errorMessage = null;
      _generatedKeyController.text = '';
    });

    if (_clientIdController.text.isEmpty ||
        _deviceHashController.text.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى ملء جميع الحقول';
      });
      return;
    }

    try {
      final key = LicenseService.generateLicenseKey(
        clientId: _clientIdController.text.trim(),
        clientName: _clientIdController.text.trim(), // Using clientId as name
        type: _licenseType == 'Trial'
            ? LicenseType.trial
            : _licenseType == 'Yearly'
                ? LicenseType.annual
                : LicenseType.permanent,
        maxStations: _maxStations,
        maxUsers: _maxUsers,
        deviceHash: _deviceHashController.text.trim(),
      );

      setState(() {
        _generatedKeyController.text = key;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('لوحة إدارة التراخيص'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client ID
            TextField(
              controller: _clientIdController,
              decoration: const InputDecoration(
                  labelText: 'اسم العميل / ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // Device Hash
            TextField(
              controller: _deviceHashController,
              decoration: const InputDecoration(
                  labelText: 'معرف جهاز العميل (Device Hash)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // License Type
            DropdownButtonFormField<String>(
              value: _licenseType,
              items: ['Trial', 'Yearly', 'Lifetime'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _licenseType = val!;
                  // تحديث التاريخ تلقائياً حسب النوع
                  if (val == 'Trial') {
                    _expiryDate = DateTime.now().add(const Duration(days: 30));
                  } else if (val == 'Yearly') {
                    _expiryDate = DateTime.now().add(const Duration(days: 365));
                  } else if (val == 'Lifetime') {
                    _expiryDate = DateTime.now()
                        .add(const Duration(days: 36500)); // 100 سنة
                  }
                });
              },
              decoration: const InputDecoration(
                  labelText: 'نوع الترخيص', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // Expiry Date
            ListTile(
              title: const Text('تاريخ الانتهاء'),
              subtitle: Text(
                  '${_expiryDate.year}-${_expiryDate.month}-${_expiryDate.day}'),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: Colors.grey)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: _expiryDate,
                );
                if (picked != null) {
                  setState(() => _expiryDate = picked);
                }
              },
            ),
            const SizedBox(height: 32),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _generateKey,
                icon: const Icon(Icons.vpn_key),
                label: const Text('توليد كود الترخيص'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Generated Key Display
            const Text('كود الترخيص المولد:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _generatedKeyController,
              readOnly: true,
              maxLines: 4,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _generatedKeyController.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم النسخ')));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

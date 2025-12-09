import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/visit_model.dart';
import '../services/visit_service.dart';
import 'package:intl/intl.dart';

/// Financial & Assessment Form Screen
/// Allows user to input financial data and assessment for a visit
class VisitFinancialAssessmentScreen extends StatefulWidget {
  final VisitModel visit;

  const VisitFinancialAssessmentScreen({
    Key? key,
    required this.visit,
  }) : super(key: key);

  @override
  State<VisitFinancialAssessmentScreen> createState() =>
      _VisitFinancialAssessmentScreenState();
}

class _VisitFinancialAssessmentScreenState
    extends State<VisitFinancialAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _visitService = VisitService();
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Financial Controllers
  final _omsetModalController = TextEditingController();
  final _ditukarController = TextEditingController();
  final _cashController = TextEditingController();
  final _qrisController = TextEditingController();
  final _debitKreditController = TextEditingController();

  // Assessment Controllers
  final _leadtimeController = TextEditingController();

  String? _selectedKategoric = 'minor';
  String? _selectedStatus = 'open';
  double _total = 0;
  bool _isLoading = false;
  VisitModel? _currentVisit; // Store current visit data

  @override
  void initState() {
    super.initState();
    _currentVisit = widget.visit;
    _loadVisitDataFromServer(); // Load fresh data from server

    // Auto-calculate total when values change
    _omsetModalController.addListener(_calculateTotal);
    _ditukarController.addListener(_calculateTotal);
    _cashController.addListener(_calculateTotal);
    _qrisController.addListener(_calculateTotal);
    _debitKreditController.addListener(_calculateTotal);
  }

  /// Load fresh visit data from server
  Future<void> _loadVisitDataFromServer() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 Loading fresh visit data from server...');
      final response = await _visitService.getVisitById(widget.visit.id);
      
      if (response.success && response.data != null) {
        setState(() {
          _currentVisit = response.data!;
          _isLoading = false;
        });
        _loadExistingData();
      } else {
        setState(() => _isLoading = false);
        print('❌ Failed to load visit data: ${response.message}');
        // Fallback to widget.visit if server fetch fails
        _loadExistingData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading visit data: $e');
      // Fallback to widget.visit if error
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    if (_currentVisit == null) return;
    
    // Debug: Print visit data
    print('📋 Loading visit data for ID: ${_currentVisit!.id}');
    print('💰 Financial data:');
    print('  - uangOmsetModal: ${_currentVisit!.uangOmsetModal}');
    print('  - uangDitukar: ${_currentVisit!.uangDitukar}');
    print('  - cash: ${_currentVisit!.cash}');
    print('  - qris: ${_currentVisit!.qris}');
    print('  - debitKredit: ${_currentVisit!.debitKredit}');
    print('  - total: ${_currentVisit!.total}');
    print('📊 Assessment data:');
    print('  - kategoric: ${_currentVisit!.kategoric}');
    print('  - leadtime: ${_currentVisit!.leadtime}');
    print('  - statusKeuangan: ${_currentVisit!.statusKeuangan}');
    print('  - crewInCharge: ${_currentVisit!.crewInCharge}');
    
    // Load financial data
    if (_currentVisit!.uangOmsetModal != null) {
      _omsetModalController.text = _currentVisit!.uangOmsetModal!.toStringAsFixed(0);
    }
    if (_currentVisit!.uangDitukar != null) {
      _ditukarController.text = _currentVisit!.uangDitukar!.toStringAsFixed(0);
    }
    if (_currentVisit!.cash != null) {
      _cashController.text = _currentVisit!.cash!.toStringAsFixed(0);
    }
    if (_currentVisit!.qris != null) {
      _qrisController.text = _currentVisit!.qris!.toStringAsFixed(0);
    }
    if (_currentVisit!.debitKredit != null) {
      _debitKreditController.text = _currentVisit!.debitKredit!.toStringAsFixed(0);
    }

    // Load assessment data
    if (_currentVisit!.leadtime != null) {
      _leadtimeController.text = _currentVisit!.leadtime.toString();
    }

    _selectedKategoric = _currentVisit!.kategoric ?? 'minor';
    _selectedStatus = _currentVisit!.statusKeuangan ?? 'open';

    _calculateTotal();
  }

  void _calculateTotal() {
    setState(() {
      double omsetModal = double.tryParse(_omsetModalController.text) ?? 0;
      double ditukar = double.tryParse(_ditukarController.text) ?? 0;
      double cash = double.tryParse(_cashController.text) ?? 0;
      double qris = double.tryParse(_qrisController.text) ?? 0;
      double debitKredit = double.tryParse(_debitKreditController.text) ?? 0;

      _total = omsetModal + ditukar + cash + qris + debitKredit;
    });
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'visit_id': widget.visit.id,
        // Financial data
        if (_omsetModalController.text.isNotEmpty)
          'uang_omset_modal': double.tryParse(_omsetModalController.text),
        if (_ditukarController.text.isNotEmpty)
          'uang_ditukar': double.tryParse(_ditukarController.text),
        if (_cashController.text.isNotEmpty)
          'cash': double.tryParse(_cashController.text),
        if (_qrisController.text.isNotEmpty) 
          'qris': double.tryParse(_qrisController.text),
        if (_debitKreditController.text.isNotEmpty)
          'debit_kredit': double.tryParse(_debitKreditController.text),
        // Assessment data
        'kategoric': _selectedKategoric,
        if (_leadtimeController.text.isNotEmpty)
          'leadtime': int.tryParse(_leadtimeController.text),
        'status_keuangan': _selectedStatus,
        // crew_in_charge sudah di-input saat start visit, tidak perlu update lagi
      };

      final success = await _visitService.updateFinancialAssessment(data);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate data was saved
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan data. Pastikan Anda sudah login.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial & Assessment'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveData,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // SECTION 1: FINANCIAL DATA
                  _buildSectionHeader('💰 Data Keuangan'),
                  const SizedBox(height: 16),

                  _buildCurrencyField(
                    controller: _omsetModalController,
                    label: 'Uang Modal',
                    icon: Icons.account_balance_wallet,
                  ),
                  const SizedBox(height: 16),

                  _buildCurrencyField(
                    controller: _ditukarController,
                    label: 'Uang Ditukar',
                    icon: Icons.swap_horiz,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildCurrencyField(
                    controller: _cashController,
                    label: 'Cash',
                    icon: Icons.money,
                  ),
                  const SizedBox(height: 16),

                  _buildCurrencyField(
                    controller: _qrisController,
                    label: 'QRIS',
                    icon: Icons.qr_code,
                  ),
                  const SizedBox(height: 16),

                  _buildCurrencyField(
                    controller: _debitKreditController,
                    label: 'Debit/Kredit',
                    icon: Icons.credit_card,
                  ),
                  const SizedBox(height: 16),

                  // TOTAL (Auto-calculated)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calculate, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _currencyFormat.format(_total),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Divider(thickness: 2),
                  const SizedBox(height: 24),

                  // SECTION 2: ASSESSMENT DATA
                  _buildSectionHeader('📊 Data Assessment'),
                  const SizedBox(height: 16),

                  // Crew in Charge (Readonly - dari start visit)
                  if (_currentVisit?.crewInCharge != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey.shade700),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Crew in Charge',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentVisit!.crewInCharge!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (_currentVisit?.crewInCharge != null)
                    const SizedBox(height: 16),

                  // Kategoric
                  DropdownButtonFormField<String>(
                    value: _selectedKategoric,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'minor', child: Text('Minor')),
                      DropdownMenuItem(value: 'major', child: Text('Major')),
                      DropdownMenuItem(value: 'ZT', child: Text('ZT (Zero Tolerance)')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedKategoric = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Lead Time
                  TextFormField(
                    controller: _leadtimeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Lead Time',
                      suffixText: 'menit',
                      prefixIcon: const Icon(Icons.timer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon: const Icon(Icons.flag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('OPEN')),
                      DropdownMenuItem(value: 'close', child: Text('CLOSE')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStatus = value);
                    },
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Simpan Data',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _omsetModalController.dispose();
    _ditukarController.dispose();
    _cashController.dispose();
    _qrisController.dispose();
    _debitKreditController.dispose();
    _leadtimeController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({super.key});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  final _controllers = {
    'N': TextEditingController(),
    'P': TextEditingController(),
    'K': TextEditingController(),
    'temperature': TextEditingController(),
    'humidity': TextEditingController(),
    'ph': TextEditingController(),
    'rainfall': TextEditingController(),
  };

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _history = [];

  static const _samples = {
    'Rice field': {'N': '90', 'P': '42', 'K': '43', 'temperature': '20.9', 'humidity': '82', 'ph': '6.5', 'rainfall': '202.9'},
    'Coffee estate': {'N': '91', 'P': '21', 'K': '26', 'temperature': '26.3', 'humidity': '57.4', 'ph': '7.3', 'rainfall': '191.7'},
    'Cotton belt': {'N': '133', 'P': '47', 'K': '24', 'temperature': '24.4', 'humidity': '79.2', 'ph': '7.2', 'rainfall': '90.8'},
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('crop_history');
    if (raw != null) {
      setState(() => _history = List<Map<String, dynamic>>.from(jsonDecode(raw)));
    }
  }

  Future<void> _saveHistory(String label, double confidence) async {
    final prefs = await SharedPreferences.getInstance();
    _history.insert(0, {'label': label, 'confidence': confidence});
    if (_history.length > 8) _history = _history.sublist(0, 8);
    await prefs.setString('crop_history', jsonEncode(_history));
    setState(() {});
  }

  void _applySample(String key) {
    final sample = _samples[key]!;
    sample.forEach((field, value) => _controllers[field]!.text = value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final data = await _api.predictCrop(
        n: double.parse(_controllers['N']!.text),
        p: double.parse(_controllers['P']!.text),
        k: double.parse(_controllers['K']!.text),
        temperature: double.parse(_controllers['temperature']!.text),
        humidity: double.parse(_controllers['humidity']!.text),
        ph: double.parse(_controllers['ph']!.text),
        rainfall: double.parse(_controllers['rainfall']!.text),
      );
      setState(() => _result = data);
      await _saveHistory(data['recommended_crop'], (data['confidence'] as num).toDouble());
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Advisor')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const SectionLabel('CROP RECOMMENDATION'),
          const Text('What should I plant here?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Enter your soil nutrient levels and climate averages.',
            style: TextStyle(color: Color(0xFF5B6350)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _samples.keys.map((k) => SampleChip(label: k, onTap: () => _applySample(k))).toList(),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _numField('N', 'Nitrogen (N)', 'kg/ha, typical 0–140'),
                _numField('P', 'Phosphorus (P)', 'kg/ha, typical 5–145'),
                _numField('K', 'Potassium (K)', 'kg/ha, typical 5–205'),
                _numField('ph', 'Soil pH', '0 (acidic) – 14 (alkaline)', max: 14),
                _numField('temperature', 'Temperature (°C)', 'average'),
                _numField('humidity', 'Humidity (%)', 'relative humidity', max: 100),
                _numField('rainfall', 'Annual rainfall (mm)', 'per year'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Recommend a Crop'),
            ),
          ),
          if (_error != null) ErrorBanner(_error!),
          if (_result != null) ..._buildResult(_result!),
          if (_history.isNotEmpty) ..._buildHistory(),
        ],
      ),
    );
  }

  Widget _numField(String key, String label, String hint, {double? max}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, helperText: hint),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          final n = double.tryParse(v);
          if (n == null) return 'Enter a number';
          if (n < 0) return 'Must be positive';
          if (max != null && n > max) return 'Must be ≤ $max';
          return null;
        },
      ),
    );
  }

  List<Widget> _buildResult(Map<String, dynamic> data) {
    final info = data['info'] as Map<String, dynamic>;
    final matches = (data['top_matches'] as List).cast<Map<String, dynamic>>();

    return [
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.leafLight,
          border: Border.all(color: AppColors.leafDark, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(info['icon'] ?? '🌾', style: const TextStyle(fontSize: 38)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Badge('Top match'),
                  const SizedBox(height: 4),
                  Text(
                    (data['recommended_crop'] as String),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Text('${data['confidence']}% confidence',
                      style: const TextStyle(color: AppColors.leafDark, fontWeight: FontWeight.w600, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(info['note'] ?? '', style: const TextStyle(color: Color(0xFF40492F))),
      const SizedBox(height: 8),
      _infoRow('Season', info['season'] ?? '—'),
      _infoRow('Water need', info['water'] ?? '—'),
      const SizedBox(height: 18),
      const Text('Other close matches', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      ...matches.map((m) => ConfidenceBar(
            label: '${m['icon'] ?? ''} ${m['crop']}',
            confidence: (m['confidence'] as num).toDouble(),
          )),
    ];
  }

  List<Widget> _buildHistory() {
    return [
      const SizedBox(height: 28),
      const Divider(color: AppColors.line),
      const SizedBox(height: 8),
      const Text('Recent lookups', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      ..._history.map((h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(h['label'].toString()),
                Text('${h['confidence']}%', style: const TextStyle(color: Color(0xFF5B6350))),
              ],
            ),
          )),
    ];
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Color(0xFF5B6350), fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: AppColors.leaf, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}

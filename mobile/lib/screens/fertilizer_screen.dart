import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';

class FertilizerScreen extends StatefulWidget {
  const FertilizerScreen({super.key});

  @override
  State<FertilizerScreen> createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends State<FertilizerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  final _controllers = {
    'temperature': TextEditingController(),
    'humidity': TextEditingController(),
    'moisture': TextEditingController(),
    'nitrogen': TextEditingController(),
    'potassium': TextEditingController(),
    'phosphorous': TextEditingController(),
  };

  String? _soilType;
  String? _cropType;
  List<String> _soilTypes = ['Black', 'Clayey', 'Loamy', 'Red', 'Sandy'];
  List<String> _cropTypes = ['Barley', 'Cotton', 'Ground Nuts', 'Maize', 'Millets', 'Oil seeds', 'Paddy', 'Pulses', 'Sugarcane', 'Tobacco', 'Wheat'];

  bool _loading = false;
  bool _metaLoaded = false;
  String? _error;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _history = [];

  static const _samples = {
    'Sandy + Maize': {'soil_type': 'Sandy', 'crop_type': 'Maize', 'temperature': '26', 'humidity': '52', 'moisture': '38', 'nitrogen': '37', 'potassium': '0', 'phosphorous': '0'},
    'Loamy + Sugarcane': {'soil_type': 'Loamy', 'crop_type': 'Sugarcane', 'temperature': '29', 'humidity': '52', 'moisture': '45', 'nitrogen': '12', 'potassium': '0', 'phosphorous': '36'},
    'Black + Cotton': {'soil_type': 'Black', 'crop_type': 'Cotton', 'temperature': '34', 'humidity': '65', 'moisture': '62', 'nitrogen': '7', 'potassium': '9', 'phosphorous': '30'},
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadMeta();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      final meta = await _api.getMeta();
      setState(() {
        _soilTypes = List<String>.from(meta['soil_types']);
        _cropTypes = List<String>.from(meta['crop_types']);
        _metaLoaded = true;
      });
    } catch (e) {
      // keep the built-in fallback lists silently
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('fertilizer_history');
    if (raw != null) {
      setState(() => _history = List<Map<String, dynamic>>.from(jsonDecode(raw)));
    }
  }

  Future<void> _saveHistory(String label, double confidence) async {
    final prefs = await SharedPreferences.getInstance();
    _history.insert(0, {'label': label, 'confidence': confidence});
    if (_history.length > 8) _history = _history.sublist(0, 8);
    await prefs.setString('fertilizer_history', jsonEncode(_history));
    setState(() {});
  }

  void _applySample(String key) {
    final sample = _samples[key]!;
    setState(() {
      _soilType = sample['soil_type'];
      _cropType = sample['crop_type'];
    });
    sample.forEach((field, value) {
      if (_controllers.containsKey(field)) _controllers[field]!.text = value;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_soilType == null || _cropType == null) {
      setState(() => _error = 'Please select a soil type and crop type.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final data = await _api.predictFertilizer(
        soilType: _soilType!,
        cropType: _cropType!,
        temperature: double.parse(_controllers['temperature']!.text),
        humidity: double.parse(_controllers['humidity']!.text),
        moisture: double.parse(_controllers['moisture']!.text),
        nitrogen: double.parse(_controllers['nitrogen']!.text),
        potassium: double.parse(_controllers['potassium']!.text),
        phosphorous: double.parse(_controllers['phosphorous']!.text),
      );
      setState(() => _result = data);
      await _saveHistory(data['recommended_fertilizer'], (data['confidence'] as num).toDouble());
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
      appBar: AppBar(title: const Text('Fertilizer Advisor')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const SectionLabel('FERTILIZER RECOMMENDATION'),
          const Text('What should I feed this crop?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Tell us your soil type, crop type and current readings.',
            style: TextStyle(color: Color(0xFF5B6350)),
          ),
          if (!_metaLoaded)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Loading form options…', style: TextStyle(fontSize: 12, color: AppColors.clay)),
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
                _dropdown('Soil Type', _soilType, _soilTypes, (v) => setState(() => _soilType = v)),
                const SizedBox(height: 12),
                _dropdown('Crop Type', _cropType, _cropTypes, (v) => setState(() => _cropType = v)),
                const SizedBox(height: 12),
                _numField('temperature', 'Temperature (°C)', ''),
                _numField('humidity', 'Humidity (%)', 'relative humidity', max: 100),
                _numField('moisture', 'Soil Moisture (%)', '', max: 100),
                _numField('nitrogen', 'Nitrogen', ''),
                _numField('potassium', 'Potassium', ''),
                _numField('phosphorous', 'Phosphorous', ''),
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
                  : const Text('Recommend a Fertilizer'),
            ),
          ),
          if (_error != null) ErrorBanner(_error!),
          if (_result != null) ..._buildResult(_result!),
          if (_history.isNotEmpty) ..._buildHistory(),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _numField(String key, String label, String hint, {double? max}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, helperText: hint.isEmpty ? null : hint),
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
            const Text('🧪', style: TextStyle(fontSize: 38)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Badge('Top match'),
                  const SizedBox(height: 4),
                  Text(
                    (data['recommended_fertilizer'] as String),
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
      _infoRow('NPK ratio', info['npk'] ?? '—'),
      const SizedBox(height: 18),
      const Text('Other close matches', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      ...matches.map((m) => ConfidenceBar(
            label: m['fertilizer'].toString(),
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

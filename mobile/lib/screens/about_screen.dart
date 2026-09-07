import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _api = ApiService();
  double? _cropAcc;
  double? _fertAcc;

  @override
  void initState() {
    super.initState();
    _api.getMeta().then((meta) {
      setState(() {
        _cropAcc = (meta['crop_accuracy'] as num).toDouble() * 100;
        _fertAcc = (meta['fertilizer_accuracy'] as num).toDouble() * 100;
      });
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const Text('How this actually works', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Two classification models trained on public agricultural datasets, served by a Flask API.',
            style: TextStyle(color: Color(0xFF5B6350)),
          ),
          const SizedBox(height: 20),
          _modelCard(
            title: 'Crop Recommendation model',
            rows: {
              'Algorithm': 'Random Forest Classifier',
              'Training data': '2,200 rows · 22 crop classes',
              'Inputs': 'N, P, K, temperature, humidity, pH, rainfall',
              'Held-out accuracy': _cropAcc != null ? '${_cropAcc!.toStringAsFixed(2)}%' : '—',
            },
          ),
          const SizedBox(height: 14),
          _modelCard(
            title: 'Fertilizer Recommendation model',
            rows: {
              'Algorithm': 'Random Forest Classifier',
              'Training data': '99 rows · 7 fertilizer classes',
              'Inputs': 'Temperature, humidity, moisture, soil type, crop type, N, K, P',
              'Held-out accuracy': _fertAcc != null ? '${_fertAcc!.toStringAsFixed(2)}%' : '—',
            },
          ),
          const SizedBox(height: 24),
          const Text('A note on the numbers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          const Text(
            'The fertilizer dataset only has 99 rows, so treat its accuracy as '
            '"this model fits this small dataset well," not a guarantee for every '
            'field. Always weigh this alongside local soil testing and agronomic advice.',
            style: TextStyle(color: Color(0xFF40492F), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _modelCard({required String title, required Map<String, String> rows}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.soilDark),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          ...rows.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 120, child: Text(e.key, style: const TextStyle(color: Color(0xFF5B6350), fontSize: 12.5))),
                    Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13.5))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

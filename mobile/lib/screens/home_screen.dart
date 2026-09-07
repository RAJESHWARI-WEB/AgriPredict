import 'package:flutter/material.dart';
import '../theme.dart';
import 'crop_screen.dart';
import 'fertilizer_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco, color: AppColors.leaf),
            const SizedBox(width: 8),
            Text('AgriPredict', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'FINAL YEAR MINI PROJECT',
            style: TextStyle(color: AppColors.clay, fontWeight: FontWeight.w600, fontSize: 12.5, letterSpacing: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Know what to grow and\nwhat to feed it.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your soil nutrients and local climate to get a data-driven '
            'crop or fertilizer recommendation, backed by two trained models.',
            style: TextStyle(color: Color(0xFF40492F), height: 1.5),
          ),
          const SizedBox(height: 24),
          _ToolCard(
            icon: '🌾',
            title: 'Crop Advisor',
            subtitle: 'N, P, K, pH, temperature, humidity & rainfall → best-fit crop',
            color: AppColors.leaf,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropScreen())),
          ),
          const SizedBox(height: 14),
          _ToolCard(
            icon: '🧪',
            title: 'Fertilizer Advisor',
            subtitle: 'Soil type, crop type & nutrient levels → best-fit fertilizer',
            color: AppColors.harvestDark,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FertilizerScreen())),
          ),
          const SizedBox(height: 28),
          const Divider(color: AppColors.line),
          const SizedBox(height: 12),
          Row(
            children: const [
              _StatBlock(number: '22', label: 'crops recognised'),
              _StatBlock(number: '7', label: 'fertilizer types'),
              _StatBlock(number: '2,301', label: 'training records'),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
              child: const Text('About the dataset & models →', style: TextStyle(color: AppColors.leafDark)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.soilDark, width: 1.4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Color(0xFF5B6350))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.soilDark),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String number;
  final String label;
  const _StatBlock({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.leafDark)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF5B6350)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

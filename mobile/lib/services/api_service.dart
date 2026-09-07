import 'dart:convert';
import 'package:http/http.dart' as http;

/// Points at the same Flask backend used by the web frontend.
///
/// - Android emulator reaching a backend on your dev machine: use
///   10.0.2.2 instead of localhost.
/// - Physical device: use your machine's LAN IP, e.g. 192.168.1.20.
/// - Deployed backend: put the real https:// URL here.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    late http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      throw ApiException(
        "Couldn't reach the server. Check that the backend is running "
        "and reachable at ${ApiConfig.baseUrl}.",
      );
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('The server returned an unexpected response.');
    }

    if (res.statusCode != 200) {
      throw ApiException(data['error']?.toString() ?? 'Request failed (${res.statusCode}).');
    }
    return data;
  }

  Future<Map<String, dynamic>> getMeta() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/meta'))
          .timeout(const Duration(seconds: 12));
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException("Couldn't load form options from the server.");
    }
  }

  Future<Map<String, dynamic>> predictCrop({
    required double n,
    required double p,
    required double k,
    required double temperature,
    required double humidity,
    required double ph,
    required double rainfall,
  }) {
    return _post('/api/predict/crop', {
      'N': n,
      'P': p,
      'K': k,
      'temperature': temperature,
      'humidity': humidity,
      'ph': ph,
      'rainfall': rainfall,
    });
  }

  Future<Map<String, dynamic>> predictFertilizer({
    required String soilType,
    required String cropType,
    required double temperature,
    required double humidity,
    required double moisture,
    required double nitrogen,
    required double potassium,
    required double phosphorous,
  }) {
    return _post('/api/predict/fertilizer', {
      'soil_type': soilType,
      'crop_type': cropType,
      'temperature': temperature,
      'humidity': humidity,
      'moisture': moisture,
      'nitrogen': nitrogen,
      'potassium': potassium,
      'phosphorous': phosphorous,
    });
  }
}

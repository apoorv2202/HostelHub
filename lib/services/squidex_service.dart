import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

class SquidexService {
  static final String _clientId = dotenv.env['SQUIDEX_CLIENT_ID'] ?? '';
  static final String _clientSecret = dotenv.env['SQUIDEX_CLIENT_SECRET'] ?? '';
  static final String _appName = dotenv.env['SQUIDEX_APP_NAME'] ?? '';
  static final String _apiUrl = dotenv.env['SQUIDEX_API_URL'] ?? '';

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<void> _authenticate() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return; // Token still valid
    }

    final url = Uri.parse('https://cloud.squidex.io/identity-server/connect/token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'scope': 'squidex-api',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
      _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in'] - 60));
    } else {
      throw Exception('Failed to authenticate with Squidex');
    }
  }

  Future<List<FoodItem>> getFoodItems() async {
    await _authenticate();
    final url = Uri.parse('$_apiUrl/food-items');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      return items.map((item) {
        final id = item['id'];
        final fieldData = item['data'];
        
        return FoodItem(
          id: id,
          name: fieldData['name']?['iv'] ?? 'Unknown Item',
          price: (fieldData['price']?['iv'] ?? 0.0).toDouble(),
          isVeg: fieldData['isVeg']?['iv'] ?? true,
          isAvailable: fieldData['isAvailable']?['iv'] ?? true,
          category: fieldData['category']?['iv'] ?? 'Other',
          emoji: fieldData['emoji']?['iv'] ?? '🍔',
          description: fieldData['description']?['iv'] ?? '',
        );
      }).toList();
    } else {
      return []; // Return empty list or throw
    }
  }

  Future<List<CollegeModel>> getColleges() async {
    await _authenticate();
    final url = Uri.parse('$_apiUrl/colleges');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      return items.map((item) {
        final id = item['id'];
        final fieldData = item['data'];
        return CollegeModel(
          id: id,
          name: fieldData['name']?['iv'] ?? 'Unknown College',
        );
      }).toList();
    } else {
      return [];
    }
  }

  Future<List<HostelModel>> getHostels() async {
    await _authenticate();
    final url = Uri.parse('$_apiUrl/hostels');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      return items.map((item) {
        final id = item['id'];
        final fieldData = item['data'];
        
        // college is an array of IDs in Squidex references
        final collegeArray = fieldData['college']?['iv'] as List?;
        final collegeId = (collegeArray != null && collegeArray.isNotEmpty) ? collegeArray.first.toString() : null;

        return HostelModel(
          id: id,
          name: fieldData['name']?['iv'] ?? 'Unknown Hostel',
          collegeId: collegeId,
        );
      }).toList();
    } else {
      return [];
    }
  }
}

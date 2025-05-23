import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String _baseUrl;
  String? _token;

  ApiService({required String baseUrl}) : _baseUrl = baseUrl;

  // Set the JWT token (called after login)
  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  // Prepare headers with optional Authorization
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Generic GET request
  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // Generic PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Handle HTTP response, parse JSON or throw error
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          print('Failed to decode JSON: $e');
          return null;
        }
      } else {
        return null;
      }
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
      throw Exception(
          'API call failed: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }

  // Example: Add your specific API methods here:
  /*
  Future<User> fetchUserData() async {
    final data = await get('user/profile');
    return User.fromJson(data);
  }
  
  Future<void> submitCongeRequest(Map<String, dynamic> congeData) async {
    await post('conge/request', congeData);
  }
  */
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_path.dart';

class ApiService {
  static Future<Map<String, dynamic>> postRequest(
    String fileName,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPath.endpoint(fileName)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Server returned ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Connection failed: $e"};
    }
  }

  static Future<Map<String, dynamic>> getRequest(String fileName) async {
    try {
      final response = await http.get(
        Uri.parse(ApiPath.endpoint(fileName)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Server Error: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Connection failed: $e"};
    }
  }
}

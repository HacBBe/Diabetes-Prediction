import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String apiUrl =
      'https://7477-2001-ee0-4fb6-be30-9d0b-772a-8ecb-66e.ngrok-free.app/predict';

  Future<Map<String, dynamic>> predictDiabetes(
      Map<String, dynamic> inputData) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(inputData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        // Trả về thông báo lỗi chi tiết hơn dựa trên mã trạng thái HTTP
        throw Exception(
            'Failed to load prediction. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Trả về thông báo lỗi chi tiết hơn nếu không kết nối được với máy chủ
      throw Exception('Failed to connect to the server: $e');
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

class RequestHelper {
  static Future<dynamic> receiveRequest(String url) async {
    final httpResponse = await http.get(Uri.parse(url));
    if (httpResponse.statusCode == 200) {
      final responseData = jsonDecode(httpResponse.body);
      return responseData;
    } else {
      throw 'Error occurred, No response';
    }
  }
}

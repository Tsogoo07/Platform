import 'dart:developer';
import 'package:dio/dio.dart';

class Data {
  static Future<String> sendAudio(String path) async {
    //final url = 'http://51.20.44.63:5000/todo';
    final url = 'http://192.168.1.133:5000/todo';
    final dio = Dio();

    FormData formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(path, filename: 'record.wav'),
    });

    log('pre res ');

    final response = await dio.post(
      url,
      data: formData,
      options: Options(headers: {"Content-Type": "multipart/form-data"}),
    );
    log('response: ${response}');

    if (response.statusCode == 200) {
      // Map<String, dynamic> responsePayload = json.decode(response.data);
      //log(responsePayload["res"]);
      return response.data;
    } else {
      log('unsuccessfull req');
      return 'error';
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
class PwdImageVerificationService {
  PwdImageVerificationService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 45),
  });

  final String baseUrl;
  final Duration timeout;

  Future<Map<String, dynamic>> analyze({
    required File imageFile,
    required String reportId,
    required String category,
    String description = '',
    double? latitude,
    double? longitude,
    String? capturedAt,
  }) async {
    final uri = Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/v1/images/analyze',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['report_id'] = reportId
      ..fields['category'] = category
      ..fields['description'] = description;

    if (latitude != null) {
      request.fields['report_lat'] = latitude.toString();
    }
    if (longitude != null) {
      request.fields['report_lon'] = longitude.toString();
    }
    if (capturedAt != null && capturedAt.isNotEmpty) {
      request.fields['captured_at'] = capturedAt;
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamed = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamed)
        .timeout(timeout);

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = {'detail': response.body};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? (decoded['detail']?.toString() ?? 'Image verification failed.')
          : 'Image verification failed.';
      throw HttpException('$message (HTTP ${response.statusCode})');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected verification response.');
    }

    return decoded;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class VersionChecker {
  static const String _githubApiBaseUrl = 'https://api.github.com/repos';
  static const String _appRepo = 'D4v31x/Aurora-Music_ALPHA_RELEASES';
  static Uri _appTagEndpoint = Uri.parse('$_githubApiBaseUrl/$_appRepo/releases/tags/latest');

  static Future<String?> checkForNewVersion() async {
    final response = await http.get(_appTagEndpoint);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String? newVersion = data['tag_name'];
      return newVersion;
    } else {
      return null;
    }
  }
}
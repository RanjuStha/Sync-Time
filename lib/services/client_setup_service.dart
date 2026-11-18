import 'package:flexyear/services/api.dart';
import 'package:flexyear/services/api_urls.dart';
import 'package:flexyear/services/app_prefs.dart';
import 'package:flexyear/services/client_session.dart';

class ClientSetupResult {
  final bool success;
  final String? error;
  const ClientSetupResult.ok() : success = true, error = null;
  const ClientSetupResult.fail(this.error) : success = false;
}

class ClientSetupService {
  /// Calls the setup API with [token]; on success loads the session and saves the token.
  static Future<ClientSetupResult> setup(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return const ClientSetupResult.fail('Client code is required.');

    try {
      final res = await Api.post(
        ApiUrls.clientSetup,
        body: {
          'token': trimmed,
          'organization_id': AppPrefs.companyId,
        },
      );

      if (!res.success) return ClientSetupResult.fail(res.message);

      final data = res.map['data'];
      final detail = data is Map ? data['clientDetail'] : null;
      if (detail is! Map) {
        return const ClientSetupResult.fail('Invalid response from server.');
      }

      ClientSession.load(data);
      await AppPrefs.setClientToken(trimmed); // <-- token saved here
      return const ClientSetupResult.ok();
    } catch (_) {
      return const ClientSetupResult.fail('Something went wrong. Please try again.');
    }
  }

  /// Re-runs setup using the token saved in prefs.
  static Future<ClientSetupResult> setupFromSavedToken() {
    final token = AppPrefs.clientToken;
    if (token == null || token.isEmpty) {
      return Future.value(const ClientSetupResult.fail('No saved client code found.'));
    }
    return setup(token);
  }
}
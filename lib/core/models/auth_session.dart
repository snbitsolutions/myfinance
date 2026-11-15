/// Server-issued credentials returned after a successful authentication.
///
/// A device must never manufacture an access token from account details. The
/// backend owns credential issuance, expiry, and revocation.
class AuthSession {
  const AuthSession({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;

  /// Supports the common response shapes used by authentication APIs while
  /// keeping the accepted fields in one auditable place.
  static AuthSession? fromResponse(Map<String, dynamic> response) {
    final payload = extractPayload(response);

    final accessToken = _readString(payload, const [
      'auth_token',
      'access_token',
      'token',
      'session_token',
      'jwt',
      'accessToken',
      'sessionToken',
    ]);
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: _readString(payload, const [
        'refresh_token',
        'refreshToken',
      ]),
    );
  }

  static Map<String, dynamic> extractPayload(Map<String, dynamic> response) {
    final cleaned = Map<String, dynamic>.from(response);

    for (final key in const ['data', 'payload', 'result', 'response']) {
      final value = cleaned[key];
      if (value is Map) {
        final nested = Map<String, dynamic>.from(value);
        if (nested.containsKey('data') && nested['data'] is Map) {
          return Map<String, dynamic>.from(nested['data'] as Map);
        }
        return nested;
      }
    }

    return cleaned;
  }

  static bool isSuccessStatus(dynamic status) {
    if (status == null) return false;
    if (status is bool) return status;
    if (status is num) {
      return status == 1 || status == 200;
    }

    final normalized = status.toString().trim().toLowerCase();
    return normalized == '1' ||
        normalized == '200' ||
        normalized == 'success' ||
        normalized == 'ok' ||
        normalized == 'true';
  }

  static String? _readString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
    }

    for (final value in payload.values) {
      if (value is Map) {
        final nested = _readString(Map<String, dynamic>.from(value), keys);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return null;
  }
}

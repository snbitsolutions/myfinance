/// Represents the current authentication state of the app
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? userEmail;
  final String? authToken;
  final DateTime? tokenExpiresAt;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.userEmail,
    this.authToken,
    this.tokenExpiresAt,
    this.isLoading = false,
    this.error,
  });

  /// Check if token is expired
  bool get isTokenExpired {
    if (tokenExpiresAt == null) return false;
    return DateTime.now().isAfter(tokenExpiresAt!);
  }

  /// Check if token is still valid
  bool get isTokenValid {
    return authToken != null && !isTokenExpired;
  }

  /// Create a copy with modified fields
  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? userEmail,
    String? authToken,
    DateTime? tokenExpiresAt,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      authToken: authToken ?? this.authToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Create loading state
  factory AuthState.loading() {
    return AuthState(isLoading: true);
  }

  /// Create error state
  factory AuthState.error(String message) {
    return AuthState(error: message);
  }

  /// Create authenticated state
  factory AuthState.authenticated({
    required String userId,
    required String userEmail,
    String? authToken,
    DateTime? tokenExpiresAt,
  }) {
    return AuthState(
      isAuthenticated: true,
      userId: userId,
      userEmail: userEmail,
      authToken: authToken,
      tokenExpiresAt: tokenExpiresAt,
    );
  }

  /// Create unauthenticated state
  factory AuthState.unauthenticated() {
    return const AuthState();
  }

  @override
  String toString() =>
      'AuthState(isAuthenticated: $isAuthenticated, userId: $userId, error: $error)';
}

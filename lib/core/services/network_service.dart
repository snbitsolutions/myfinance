import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

/// Network connectivity service to monitor internet connection
class NetworkService {
  static NetworkService? _instance;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Stream controller for connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();

  // Current connectivity status
  bool _isConnected = true;

  NetworkService._internal();

  /// Get singleton instance
  static NetworkService get instance {
    _instance ??= NetworkService._internal();
    return _instance!;
  }

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      _handleConnectivityChange([result]);
    });

    AppLogger.info('Network service initialized');
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _handleConnectivityChange([result]);
    } catch (e) {
      AppLogger.error('Failed to check connectivity', e);
      _isConnected = false;
      _connectivityController.add(false);
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;

    // Check if any connection type is available
    _isConnected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

    if (wasConnected != _isConnected) {
      AppLogger.info(
        _isConnected ? 'Network connected' : 'Network disconnected',
      );
      _connectivityController.add(_isConnected);

      if (kDebugMode) {
        final connectionTypes = results
            .map((r) => r.name)
            .where((name) => name != 'none')
            .join(', ');
        if (connectionTypes.isNotEmpty) {
          AppLogger.debug('Connection types: $connectionTypes');
        }
      }
    }
  }

  /// Get current connectivity status
  bool get isConnected => _isConnected;

  /// Stream of connectivity changes (true = connected, false = disconnected)
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Check if currently connected (real-time check)
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    AppLogger.info('Network service disposed');
  }
}

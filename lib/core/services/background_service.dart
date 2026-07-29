// Background service is disabled to prevent crash on Android 12+.
// Notifications are handled directly via socket in the main app.

class BackgroundServiceInstance {
  static Future<void> initializeService() async {
    // No-op stub. Background service disabled for stability.
    // All real-time events handled by main app SocketService.
  }
}

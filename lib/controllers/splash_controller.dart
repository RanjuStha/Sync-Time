class SplashController {
  static const Duration splashDuration = Duration(seconds: 2);

  Future<void> initApp() async {
    // Add startup work here later (load saved data, check login, etc.)
    await Future.delayed(splashDuration);
  }
}
import 'package:flutter/material.dart';

/// Enterprise Lifecycle & Focus Observer Mixin.
///
/// Automatically listens to OS App Lifecycle transitions (e.g. app resumed from background)
/// and triggers silent SWR revalidations to keep mobile UI always fresh and reactive.
mixin LifecycleObserverMixin<T extends StatefulWidget> on State<T>
    implements WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Callback fired when the application is restored/resumed from background.
  void onAppResumed() {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[LifecycleObserver] App resumed from background. Triggering silent revalidation...');
      onAppResumed();
    }
  }

  @override
  void didChangeAccessibilityFeatures() {}

  @override
  void didChangeLocales(List<Locale>? locales) {}

  @override
  void didChangeMetrics() {}

  @override
  void didChangePlatformBrightness() {}

  @override
  void didChangeTextScaleFactor() {}

  @override
  void didHaveMemoryPressure() {}

  @override
  Future<bool> didPopRoute() async => false;

  @override
  Future<bool> didPushRoute(String route) async => false;

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async => false;
}

import '../core/storage/local_storage.dart';
import 'routes/app_routes.dart';

/// Chooses the first Flutter route before the app paints its first frame.
///
/// A new installation starts with the language and appearance chooser.
/// Returning installations continue through Splash so session restoration
/// and the normal destination routing remain centralized there.
class StartupRouteResolver {
  const StartupRouteResolver({required this.localStorage});

  final LocalStorage localStorage;

  Future<String> resolve() async {
    final preferencesSeen = await localStorage.readInitialPreferencesSeen();
    return preferencesSeen ? AppRoutes.splash : AppRoutes.languageSelect;
  }
}

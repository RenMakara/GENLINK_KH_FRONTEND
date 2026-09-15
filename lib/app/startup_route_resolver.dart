import '../core/storage/local_storage.dart';
import 'routes/app_routes.dart';

class StartupRouteResolver {
  const StartupRouteResolver({required this.localStorage});

  final LocalStorage localStorage;

  Future<String> resolve() async {
    final preferencesSeen = await localStorage.readInitialPreferencesSeen();
    return preferencesSeen ? AppRoutes.splash : AppRoutes.welcome;
  }
}

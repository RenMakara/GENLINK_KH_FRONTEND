import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/app/startup_route_resolver.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  late _MockLocalStorage storage;

  setUp(() => storage = _MockLocalStorage());

  test('new installation starts at welcome', () async {
    when(storage.readInitialPreferencesSeen).thenAnswer((_) async => false);

    final route = await StartupRouteResolver(localStorage: storage).resolve();

    expect(route, AppRoutes.welcome);
  });

  test('returning installation starts at splash', () async {
    when(storage.readInitialPreferencesSeen).thenAnswer((_) async => true);

    final route = await StartupRouteResolver(localStorage: storage).resolve();

    expect(route, AppRoutes.splash);
  });
}

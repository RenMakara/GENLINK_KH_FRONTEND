import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Central GetX page registry.
///
/// Add GetPage definitions here once real presentation pages are introduced.
abstract final class AppPages {
  static const initial = '/';

  static final pages = <GetPage<dynamic>>[
    GetPage(name: initial, page: () => const SizedBox.shrink()),
  ];

  static final unknownRoute = GetPage<dynamic>(
    name: '/not-found',
    page: () => const SizedBox.shrink(),
  );
}

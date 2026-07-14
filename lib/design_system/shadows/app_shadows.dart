import 'package:flutter/material.dart';

/// Shadow token folder.
///
/// Keep elevation and glass shadow recipes here.
abstract final class AppShadows {
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 10)),
  ];
}

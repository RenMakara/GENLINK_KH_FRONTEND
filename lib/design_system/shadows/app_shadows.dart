import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 10)),
  ];

  static const cardLight = <BoxShadow>[
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const cardDark = <BoxShadow>[];

  static const navLight = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.02),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const navDark = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.35),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];
}


import 'package:flutter/foundation.dart';

/// A bundled, safe-to-share cover treatment for a profile.
///
/// The backend stores only the small [id], keeping a selected cover stable
/// across devices while the app retains ownership of the static artwork.
@immutable
class ProfileCoverPreset {
  const ProfileCoverPreset({
    required this.id,
    required this.assetPath,
    required this.semanticLabel,
  });

  final int id;
  final String assetPath;
  final String semanticLabel;
}

abstract final class ProfileCoverPresets {
  static const count = 10;

  static const all = <ProfileCoverPreset>[
    ProfileCoverPreset(
      id: 0,
      assetPath: 'assets/images/profile_covers/cover_city_sunset.jpg',
      semanticLabel: 'City sunset',
    ),
    ProfileCoverPreset(
      id: 1,
      assetPath: 'assets/images/profile_covers/cover_rice_terraces.jpg',
      semanticLabel: 'Rice terraces',
    ),
    ProfileCoverPreset(
      id: 2,
      assetPath: 'assets/images/profile_covers/cover_digital_network.jpg',
      semanticLabel: 'Digital network',
    ),
    ProfileCoverPreset(
      id: 3,
      assetPath: 'assets/images/profile_covers/cover_misty_forest.jpg',
      semanticLabel: 'Misty forest',
    ),
    ProfileCoverPreset(
      id: 4,
      assetPath: 'assets/images/profile_covers/cover_creative_studio.jpg',
      semanticLabel: 'Creative studio',
    ),
    ProfileCoverPreset(
      id: 5,
      assetPath: 'assets/images/profile_covers/cover_coastal_horizon.jpg',
      semanticLabel: 'Coastal horizon',
    ),
    ProfileCoverPreset(
      id: 6,
      assetPath: 'assets/images/profile_covers/cover_midnight_architecture.jpg',
      semanticLabel: 'Midnight architecture',
    ),
    ProfileCoverPreset(
      id: 7,
      assetPath: 'assets/images/profile_covers/cover_paper_waves.jpg',
      semanticLabel: 'Paper waves',
    ),
    ProfileCoverPreset(
      id: 8,
      assetPath: 'assets/images/profile_covers/cover_night_sky.jpg',
      semanticLabel: 'Night sky',
    ),
    ProfileCoverPreset(
      id: 9,
      assetPath: 'assets/images/profile_covers/cover_temple_sunrise.jpg',
      semanticLabel: 'Temple sunrise',
    ),
  ];

  static ProfileCoverPreset byId(int id) {
    if (id < 0 || id >= all.length) return all.first;
    return all[id];
  }
}

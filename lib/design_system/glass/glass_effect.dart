/// Glassmorphism design folder.
///
/// Reusable glass widgets belong here: GlassContainer, GlassCard,
/// GlassBottomNavigation, and GlassAppBar. Keep opacity between 68%-76%,
/// blur between 14-20, subtle 1px borders, and soft shadows.
class GlassEffect {
  const GlassEffect({
    this.opacity = 0.72,
    this.blur = 16,
    this.borderWidth = 1,
  });

  final double opacity;
  final double blur;
  final double borderWidth;
}

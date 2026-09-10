/// Shared spacing and corner-radius scale.
///
/// Before this existed, screens picked gaps (8/16/20/24/32) and radii
/// (10/14/16/18) ad hoc, so a single screen could show four different corner
/// roundings. Reach for these instead of a literal, and only add a new step
/// when an existing one genuinely doesn't fit.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  /// Small inline artwork and tiles.
  static const sm = 10.0;

  /// Default for cards, inputs, and list rows.
  static const md = 16.0;

  /// Large feature surfaces (the Home featured card).
  static const lg = 20.0;
}

/// Map tile/style configuration for wardriving capture maps.
abstract final class MapConfig {
  /// OpenFreeMap Liberty — no requests to OSM volunteer tile servers
  /// (`tile.openstreetmap.org`). See https://wiki.openstreetmap.org/wiki/Blocked_tiles
  ///
  /// Alternative: OSM Americana `https://americanamap.org/style.json`
  /// (uses `tiles.openstreetmap.us`, not `tile.openstreetmap.org`).
  static const styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  static const attribution =
      'OpenFreeMap · © OpenStreetMap contributors';
}

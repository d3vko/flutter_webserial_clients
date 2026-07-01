/// Map tile/style configuration for wardriving capture maps.
abstract final class MapConfig {
  /// OSM Americana — https://madewithmaplibre.com/basemaps/styles/osm-americana
  ///
  /// Alternative: OpenFreeMap `https://tiles.openfreemap.org/styles/liberty`
  static const styleUrl = 'https://americanamap.org/style.json';

  static const attribution =
      'OSM Americana · OpenStreetMap US · © OpenStreetMap contributors';
}

/// Map tile/style configuration for wardriving capture maps.
abstract final class MapConfig {
  // --- OpenFreeMap (no tile.openstreetmap.org) ---
  // static const styleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  // static const attribution =
  //     'OpenFreeMap · © OpenStreetMap contributors';
  //
  // static const styleUrl = 'https://tiles.openfreemap.org/styles/bright';
  // static const attribution =
  //     'OpenFreeMap · © OpenStreetMap contributors';
  //
  // static const styleUrl = 'https://tiles.openfreemap.org/styles/positron';
  // static const attribution =
  //     'OpenFreeMap · © OpenStreetMap contributors';
  //
  // static const styleUrl = 'https://tiles.openfreemap.org/styles/dark';
  // static const attribution =
  //     'OpenFreeMap · © OpenStreetMap contributors';

  // --- OSM Americana (tiles.openstreetmap.us, not tile.openstreetmap.org) ---
  // https://madewithmaplibre.com/basemaps/styles/osm-americana
  static const styleUrl = 'https://americanamap.org/style.json';

  static const attribution =
      'OSM Americana · OpenStreetMap US · © OpenStreetMap contributors';

  // --- Do not use ---
  // tile.openstreetmap.org raster tiles — blocked by OSM volunteer servers.
  // See https://wiki.openstreetmap.org/wiki/Blocked_tiles
}

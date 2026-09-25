/// Map tile/style configuration for wardriving capture maps.
abstract final class MapConfig {
  // OpenFreeMap public instance: no registration or API key required.
  // https://openfreemap.org/quick_start/
  static const styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  static const attribution =
      'OpenFreeMap · © OpenMapTiles · © OpenStreetMap contributors';

  // Alternative styles:
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

  // --- Do not use ---
  // tile.openstreetmap.org raster tiles — blocked by OSM volunteer servers.
  // See https://wiki.openstreetmap.org/wiki/Blocked_tiles
}

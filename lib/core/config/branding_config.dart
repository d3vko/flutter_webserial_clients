/// RF Village branding assets.
///
/// Para cambiar el icono del AppBar manualmente:
/// 1. Coloca el PNG en [assets/branding/].
/// 2. Cambia [appBarIconAsset] al nombre del archivo.
/// 3. Hot restart (los assets no se recargan con hot reload).
///
/// Variantes disponibles:
/// - `rf_village_mx_icon_v1_transparent.png` (recomendado, AppBar)
/// - `rf_village_mx_icon_v1.png`
/// - `rf_village_mx_icon_v2.png`
/// - `rf_village_mx_icon_new.png`
abstract final class BrandingConfig {
  static const appBarIconAsset =
      'assets/branding/rf_village_mx_icon_v1_transparent.png';

  static const heroLogoAsset = 'assets/branding/rf_village.png';
}

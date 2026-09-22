/// CU17 — Vestidor Virtual AR.
///
/// Los modelos 3D son los del **Khronos Group** (`glTF-Sample-Assets` y
/// `glTF-Sample-Models`): calzado, accesorios y tela. Se usan como demostración
/// porque el catálogo todavía no publica sus propios `.glb`: cuando un producto trae
/// `model_3d_url` (o el backend lo expone), ese modelo manda.
class ArConstants {
  ArConstants._();

  /// Ruta base de los modelos publicados por Khronos (`main`).
  static const _assets =
      'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models';

  /// Calzado — `MaterialsVariantsShoe`, `.glb` autocontenido con variantes de material.
  static const shoeModelUrl =
      'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/'
      'master/2.0/MaterialsVariantsShoe/glTF-Binary/MaterialsVariantsShoe.glb';

  /// Prendas de tela — `SheenCloth` se publica como `.gltf` junto a su `.bin` y sus
  /// texturas, y el visor las resuelve por ruta relativa.
  static const clothModelUrl = '$_assets/SheenCloth/glTF/SheenCloth.gltf';

  /// Accesorios — `SunglassesKhronos`, `.glb` autocontenido (371 KB).
  static const sunglassesModelUrl =
      '$_assets/SunglassesKhronos/glTF-Binary/SunglassesKhronos.glb';

  /// Respaldo final cuando el producto no trae modelo ni categoría reconocible.
  static const fallbackModelUrl = shoeModelUrl;

  /// Vistas oficiales de cada modelo (póster del visor mientras carga el 3D).
  static const clothPreviewUrl =
      '$_assets/SheenCloth/screenshot/screenshot.jpg';
  static const shoePreviewUrl =
      '$_assets/MaterialsVariantsShoe/screenshot/screenshot.jpg';
  static const sunglassesPreviewUrl =
      '$_assets/SunglassesKhronos/screenshot/SunglassesKhronos.png';

  /// Canal nativo implementado en `MainActivity.kt`.
  static const channel = 'com.fashionstore/ar';

  /// Modos de Scene Viewer (`mode` del intent).
  static const modeArPreferred = 'ar_preferred';
  static const modeArOnly = 'ar_only';
  static const mode3dPreferred = '3d_preferred';

  /// Formatos que acepta el vestidor (coincide con `model_3d_format` del backend).
  static const supportedFormats = ['glb', 'gltf'];

  /// Modelo de demostración que corresponde a la categoría del producto.
  static String modelForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('calz') || value.contains('zapat')) return shoeModelUrl;
    if (value.contains('acces') || value.contains('gafa')) {
      return sunglassesModelUrl;
    }
    return clothModelUrl;
  }

  /// Vista previa (póster) que corresponde a un modelo.
  static String previewFor(String modelUrl) {
    final value = modelUrl.toLowerCase();
    if (value.contains('sunglasses')) return sunglassesPreviewUrl;
    if (value.contains('shoe')) return shoePreviewUrl;
    return clothPreviewUrl;
  }
}

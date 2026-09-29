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

  /// Accesorios — `SunglassesKhronos`, `.glb` autocontenido (371 KB).
  static const sunglassesModelUrl =
      '$_assets/SunglassesKhronos/glTF-Binary/SunglassesKhronos.glb';

  static const _vercelModels =
      'https://fashionstore-web-eight.vercel.app/models';

  /// Accesorios / Joyería — `ChronographWatch`, `.glb` de alta definición PBR.
  static const watchModelUrl = '$_vercelModels/apple_watch.glb';

  /// Accesorios / Gorras — `baseball_cap.glb` alojado en Vercel.
  static const capModelUrl = '$_vercelModels/baseball_cap.glb';

  /// Accesorios / Sombreros — `hat.glb` alojado en Vercel.
  static const hatModelUrl = '$_vercelModels/hat.glb';

  /// Moda / Chaqueta — `denim_jacket.glb` alojado en Vercel.
  static const jacketModelUrl = '$_vercelModels/denim_jacket.glb';

  /// Moda / Blazer — `blazer.glb` alojado en Vercel.
  static const blazerModelUrl = '$_vercelModels/blazer.glb';

  /// Respaldo por defecto para calzado.
  static const fallbackModelUrl = shoeModelUrl;

  /// Vistas oficiales de cada modelo (póster del visor mientras carga el 3D).
  static const shoePreviewUrl =
      '$_assets/MaterialsVariantsShoe/screenshot/screenshot.jpg';
  static const sunglassesPreviewUrl =
      '$_assets/SunglassesKhronos/screenshot/SunglassesKhronos.png';
  static const watchPreviewUrl =
      'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=400&h=520&fit=crop&auto=format';
  static const capPreviewUrl =
      'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=400&h=520&fit=crop&auto=format';
  static const hatPreviewUrl =
      'https://images.unsplash.com/photo-1514327605112-b887c0e61c0a?w=400&h=520&fit=crop&auto=format';
  static const jacketPreviewUrl =
      'https://images.unsplash.com/photo-1603189343302-e603f7add05a?w=400&h=520&fit=crop&auto=format';
  static const blazerPreviewUrl =
      'https://images.unsplash.com/photo-1613915617430-8ab0fd7c6baf?w=400&h=520&fit=crop&auto=format';

  /// Canal nativo implementado en `MainActivity.kt`.
  static const channel = 'com.fashionstore/ar';

  /// Modos de Scene Viewer (`mode` del intent).
  static const modeArPreferred = 'ar_preferred';
  static const modeArOnly = 'ar_only';
  static const mode3dPreferred = '3d_preferred';

  /// Formatos que acepta el vestidor (coincide con `model_3d_format` del backend).
  static const supportedFormats = ['glb', 'gltf'];

  /// Vista previa (póster) que corresponde a un modelo.
  static String previewFor(String modelUrl) {
    final value = modelUrl.toLowerCase();
    if (value.contains('sunglasses')) return sunglassesPreviewUrl;
    if (value.contains('watch') || value.contains('apple_watch')) return watchPreviewUrl;
    if (value.contains('cap') || value.contains('baseball')) return capPreviewUrl;
    if (value.contains('hat')) return hatPreviewUrl;
    if (value.contains('jacket') || value.contains('denim')) return jacketPreviewUrl;
    return shoePreviewUrl;
  }
}

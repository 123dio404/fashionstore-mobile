/// CU17 — Vestidor Virtual AR.
///
/// Los modelos 3D son los del **Khronos Group** (`glTF-Sample-Assets` y
/// `glTF-Sample-Models`): calzado, accesorios y tela. Se usan como demostración
/// porque el catálogo todavía no publica sus propios `.glb`: cuando un producto trae
/// `model_3d_url` (o el backend lo expone), ese modelo manda.
class ArConstants {
  ArConstants._();


  /// Ruta base en Vercel
  static const _vercel = 'https://fashionstore-web-eight.vercel.app';

  /// Calzado — `MaterialsVariantsShoe`, `.glb` autocontenido con variantes de material.
  static const shoeModelUrl = '$_vercel/models/MaterialsVariantsShoe.glb';

  /// Accesorios — `SunglassesKhronos`, `.glb` autocontenido (371 KB).
  static const sunglassesModelUrl = '$_vercel/models/SunglassesKhronos.glb';

  /// Accesorios / Joyería — `ChronographWatch`, `.glb` de alta definición PBR.
  static const watchModelUrl = '$_vercel/models/ChronographWatch.glb';

  /// Textil / Pañuelo — `SheenCloth`, `.glb` simulación de tela técnica Sheen PBR.
  static const clothModelUrl = '$_vercel/models/SheenCloth.glb';

  /// Calzado Femenino — `SheenHighHeel`, `.glb` zapatos de tacón alta costura.
  static const heelModelUrl = '$_vercel/models/SheenHighHeel.glb';

  /// Joyería — `ClearcoatRing`, `.glb` anillo solitario titanio y carbono.
  static const ringModelUrl = '$_vercel/models/ClearcoatRing.glb';

  /// Respaldo por defecto para calzado.
  static const fallbackModelUrl = shoeModelUrl;

  /// Vistas oficiales de cada modelo (coinciden exactamente con el 3D).
  static const shoePreviewUrl = '$_vercel/previews/shoe.jpg';
  static const sunglassesPreviewUrl = '$_vercel/previews/sunglasses.png';
  static const watchPreviewUrl = '$_vercel/previews/watch.jpg';
  static const clothPreviewUrl = '$_vercel/previews/cloth.jpg';
  static const heelPreviewUrl = '$_vercel/previews/heel.jpg';
  static const ringPreviewUrl = '$_vercel/previews/ring.jpg';

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
    if (value.contains('sunglass')) return sunglassesPreviewUrl;
    if (value.contains('watch')) return watchPreviewUrl;
    if (value.contains('cloth')) return clothPreviewUrl;
    if (value.contains('heel')) return heelPreviewUrl;
    if (value.contains('ring')) return ringPreviewUrl;
    if (value.contains('shoe')) return shoePreviewUrl;
    return shoePreviewUrl;
  }
}

/// CU17 — Vestidor Virtual AR.
///
/// Modelo 3D de respaldo (Khronos glTF Sample Models): zapatilla con variantes de
/// materiales en `.glb`. Se usa cuando el producto no trae `model_3d_url`, para que
/// el vestidor siempre tenga algo real que proyectar en AR.
class ArConstants {
  ArConstants._();

  static const fallbackModelUrl =
      'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/'
      'master/2.0/MaterialsVariantsShoe/glTF-Binary/MaterialsVariantsShoe.glb';

  /// Canal nativo implementado en `MainActivity.kt`.
  static const channel = 'com.fashionstore/ar';

  /// Modos de Scene Viewer (`mode` del intent).
  static const modeArPreferred = 'ar_preferred';
  static const modeArOnly = 'ar_only';
  static const mode3dPreferred = '3d_preferred';

  /// Formatos que acepta el vestidor (coincide con `model_3d_format` del backend).
  static const supportedFormats = ['glb', 'gltf'];
}

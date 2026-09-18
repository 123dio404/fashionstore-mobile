import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class VirtualFittingScreen extends StatefulWidget {
  final String modelUrl;
  const VirtualFittingScreen({super.key, required this.modelUrl});

  @override
  State<VirtualFittingScreen> createState() => _VirtualFittingScreenState();
}

class _VirtualFittingScreenState extends State<VirtualFittingScreen> {
  String? _error;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    _startAr();
  }

  Future<void> _startAr() async {
    if (!widget.modelUrl.endsWith('.glb') &&
        !widget.modelUrl.endsWith('.gltf')) {
      setState(() => _error = 'El modelo debe ser un archivo .glb o .gltf.');
    } else {
      setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Probador virtual')),
        body: Center(
          child: _starting
              ? const CircularProgressIndicator()
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    )
                  : ModelViewer(
                      src: widget.modelUrl,
                      ar: true,
                      cameraControls: true,
                      autoRotate: true,
                    ),
        ),
      );
}

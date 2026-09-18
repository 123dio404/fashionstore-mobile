# FashionStore Mobile

Flutter client for the FashionStore API. Configure the backend URL at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Products with a `.glb` or `.gltf` URL expose the virtual fitting screen through
`model_viewer_plus`, which delegates AR launch to ARCore/ARKit where supported.
Unsupported devices and invalid model URLs show an explicit error. This is a model
viewer capability boundary, not body tracking or a claim of virtual try-on.

The checkout always uses the backend Stripe flow and displays the backend payment
status; it never marks a payment as completed locally.

The client also supports `POST /reports/analytical-query/voice` through
`AppRepository.analyticalQueryVoice`; the backend controls Google Speech credentials
through environment variables.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

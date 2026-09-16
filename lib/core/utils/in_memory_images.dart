import 'dart:typed_data';

/// Registre des images qui n’existent qu’en mémoire (backend simulé,
/// aperçus). Ces images sont référencées par une URL `memory://<id>` que
/// `EventImage` retransforme en octets, de sorte que le reste de l’app
/// continue de manipuler de simples URL.
abstract final class InMemoryImages {
  static const scheme = 'memory://';

  static final _images = <String, Uint8List>{};

  static bool isMemoryUrl(String? url) => url?.startsWith(scheme) ?? false;

  static String put(Uint8List bytes) {
    final id = '$scheme${DateTime.now().microsecondsSinceEpoch}';
    _images[id] = bytes;
    return id;
  }

  static Uint8List? get(String url) => _images[url];
}

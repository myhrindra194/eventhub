import 'dart:typed_data';

/// Registry for images that only exist in memory (mock backend, previews).
/// Such images are referenced with a `memory://<id>` URL that `EventImage`
/// resolves back to bytes, so the rest of the app keeps using plain URLs.
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

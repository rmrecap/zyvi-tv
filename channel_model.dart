---

## 2. Shared Data Object Structure (`channel_model.dart`)
This schema bridges the Mobile Application and the Admin Panel via Firebase, ensuring data parity.

```dart
// Location: lib/data/models/channel_model.dart

class ChannelModel {
  final String id;
  final String name;
  final String category;
  final String logoUrl;
  final List<StreamSource> sources;
  final bool isLive;
  final DateTime updatedAt;

  ChannelModel({
    required this.id,
    required this.name,
    required this.category,
    required this.logoUrl,
    required this.sources,
    required this.isLive,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'logoUrl': logoUrl,
      'sources': sources.map((x) => x.toMap()).toList(),
      'isLive': isLive,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChannelModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ChannelModel(
      id: documentId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      sources: List<StreamSource>.from(
        (map['sources'] ?? []).map((x) => StreamSource.fromMap(x)),
      ),
      isLive: map['isLive'] ?? false,
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class StreamSource {
  final String name; // e.g., "FOX ONE HD", "TNT SPORTS FHD"
  final String url;  // m3u8 or mp4 streaming link
  final String resolutionQuality; // e.g., "4K", "FHD", "HD"

  StreamSource({
    required this.name,
    required this.url,
    required this.resolutionQuality,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'resolutionQuality': resolutionQuality,
    };
  }

  factory StreamSource.fromMap(Map<String, dynamic> map) {
    return StreamSource(
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      resolutionQuality: map['resolutionQuality'] ?? 'HD',
    );
  }
}
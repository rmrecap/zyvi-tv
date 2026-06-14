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
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class StreamSource {
  final String name;
  final String url;
  final String resolutionQuality;

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

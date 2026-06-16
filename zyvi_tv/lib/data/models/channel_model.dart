import 'package:hive/hive.dart';

part 'channel_model.g.dart';

@HiveType(typeId: 0)
class ChannelModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String logoUrl;

  @HiveField(4)
  final List<StreamSource> sources;

  @HiveField(5)
  final bool isLive;

  @HiveField(6)
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
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'] as String)
          : map['updatedAt'] is DateTime
              ? map['updatedAt'] as DateTime
              : DateTime.now(),
    );
  }

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel.fromMap(json, json['id'] as String? ?? '');
  }
}

@HiveType(typeId: 1)
class StreamSource {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String url;

  @HiveField(2)
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

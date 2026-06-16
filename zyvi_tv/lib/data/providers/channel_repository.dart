import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/channel_model.dart';

const String kChannelBox = 'channel_box';

final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  return ChannelRepository();
});

class ChannelRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<ChannelModel?> fetchAndCacheChannel(String channelId) async {
    var box = Hive.box<ChannelModel>(kChannelBox);

    if (box.containsKey(channelId)) {
      return box.get(channelId);
    }

    try {
      final doc = await _firestore.collection('zyvi_channels').doc(channelId).get();

      if (doc.exists && doc.data() != null) {
        final channel = ChannelModel.fromMap(doc.data()!, doc.id);
        await box.put(channelId, channel);
        return channel;
      }
    } catch (e) {
      debugPrint('Firestore Read Exception: $e');
    }
    return null;
  }
}

final channelProvider = FutureProvider.family.autoDispose<ChannelModel?, String>(
  (ref, channelId) async {
    final link = ref.keepAlive();

    final repository = ref.watch(channelRepositoryProvider);
    final data = await repository.fetchAndCacheChannel(channelId);

    if (data == null) {
      link.close();
    }

    return data;
  },
);

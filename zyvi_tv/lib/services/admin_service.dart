import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static Future<int> deleteAllChannels() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('zyvi_channels')
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  static Future<bool> restoreDefaultChannels() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('zyvi_config')
          .doc('seed')
          .get();

      if (!snapshot.exists) return false;
      final data = snapshot.data();
      if (data == null || !data.containsKey('channels')) return false;

      final channels = data['channels'] as List;
      final batch = firestore.batch();

      for (final channelData in channels) {
        final docRef = firestore.collection('zyvi_channels').doc();
        batch.set(docRef, channelData as Map<String, dynamic>);
      }

      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }
}

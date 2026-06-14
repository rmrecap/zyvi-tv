This script listens natively to Firestore changes. When you update, delete, or append a stream link in your admin dashboard, your Android and iOS applications update instantly without user refresh.

Dart

// Location: lib/data/providers/firebase_stream_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/channel_model.dart';

class FirebaseStreamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream listening to active live matches / channels in absolute real-time
  Stream<List<ChannelModel>> listenToLiveChannels() {
    return _firestore
        .collection('zyvi_channels')
        .where('isLive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChannelModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Stream listening to channels filtered by categorized taxonomies
  Stream<List<ChannelModel>> listenToChannelsByCategory(String category) {
    return _firestore
        .collection('zyvi_channels')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChannelModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
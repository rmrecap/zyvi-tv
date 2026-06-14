import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/channel_model.dart';

class FirebaseStreamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Stream<List<ChannelModel>> listenToAllChannels() {
    return _firestore
        .collection('zyvi_channels')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChannelModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}

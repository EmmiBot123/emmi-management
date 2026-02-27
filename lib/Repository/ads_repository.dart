import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/Ads/user_ad_model.dart';

class AdsRepository {
  final CollectionReference _adsCollection =
      FirebaseFirestore.instance.collection('ads');

  Stream<List<AdModel>> getAds() {
    return _adsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdModel.fromJson(doc.data() as Map<String, dynamic>,
            docId: doc.id);
      }).toList();
    });
  }

  Future<void> addAd(String title, String youtubeUrl) async {
    await _adsCollection.add({
      'title': title,
      'youtubeUrl': youtubeUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAd(String id) async {
    await _adsCollection.doc(id).delete();
  }
}

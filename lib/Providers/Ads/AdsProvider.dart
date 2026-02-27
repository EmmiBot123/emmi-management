import 'package:flutter/material.dart';
import '../../Model/Ads/user_ad_model.dart';
import '../../Repository/ads_repository.dart';

class AdsProvider extends ChangeNotifier {
  final AdsRepository _repository = AdsRepository();

  Stream<List<AdModel>> get adsStream => _repository.getAds();

  bool isLoading = false;
  String? errorMessage;

  Future<bool> addAd(String title, String youtubeUrl) async {
    try {
      isLoading = true;
      notifyListeners();
      await _repository.addAd(title, youtubeUrl);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAd(String id) async {
    try {
      await _repository.deleteAd(id);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

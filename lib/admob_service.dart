import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }
}

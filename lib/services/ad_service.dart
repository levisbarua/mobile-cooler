import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  int _interstitialLoadAttempts = 0;

  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerLoaded => _isBannerLoaded;
  bool get isInterstitialLoaded => _isInterstitialLoaded;

  // Test Ad Unit IDs from Google
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  AdService() {
    init();
  }

  bool get _isSupportedPlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!_isSupportedPlatform) return;
    try {
      await MobileAds.instance.initialize();
      loadBannerAd();
      loadInterstitialAd();
    } catch (e) {
      if (kDebugMode) print('AdMob initialization failed: $e');
    }
  }

  void loadBannerAd() {
    if (!_isSupportedPlatform) return;
    
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) print('BannerAd failed to load: $error');
          ad.dispose();
          _isBannerLoaded = false;
          notifyListeners();
        },
      ),
    );
    _bannerAd!.load();
  }

  void loadInterstitialAd() {
    if (!_isSupportedPlatform) return;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          _interstitialLoadAttempts = 0;
          
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialLoaded = false;
              loadInterstitialAd(); // Load the next one
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialLoaded = false;
              loadInterstitialAd();
            },
          );
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) print('InterstitialAd failed to load: $error');
          _isInterstitialLoaded = false;
          _interstitialLoadAttempts++;
          if (_interstitialLoadAttempts < 3) {
            // Retry loading
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (!_isSupportedPlatform) return;
    if (_isInterstitialLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      if (kDebugMode) print('InterstitialAd not loaded yet.');
      loadInterstitialAd(); // Force attempt load
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}

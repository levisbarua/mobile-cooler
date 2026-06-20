import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  int _interstitialLoadAttempts = 0;

  // Diagnostics status
  String _initStatus = 'Initializing...';
  String _bannerStatus = 'Not loaded';
  String _interstitialStatus = 'Not loaded';
  String? _lastError;

  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerLoaded => _isBannerLoaded;
  bool get isInterstitialLoaded => _isInterstitialLoaded;
  String get initStatus => _initStatus;
  String get bannerStatus => _bannerStatus;
  String get interstitialStatus => _interstitialStatus;
  String? get lastError => _lastError;

  // Test Ad Unit IDs from Google
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  AdService() {
    init();
  }

  bool get _isSupportedPlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!_isSupportedPlatform) {
      _initStatus = 'Unsupported Platform';
      notifyListeners();
      return;
    }
    try {
      print('AdService: Initializing Mobile Ads SDK...');
      _initStatus = 'Initializing...';
      notifyListeners();
      await MobileAds.instance.initialize();
      print('AdService: Mobile Ads SDK initialized successfully.');
      _initStatus = 'Initialized';
      notifyListeners();
      loadBannerAd();
      loadInterstitialAd();
    } catch (e) {
      print('AdService: AdMob initialization failed: $e');
      _initStatus = 'Failed: $e';
      _lastError = 'Init: $e';
      notifyListeners();
    }
  }

  void loadBannerAd() {
    if (!_isSupportedPlatform) return;
    
    print('AdService: Loading BannerAd...');
    _bannerStatus = 'Loading...';
    notifyListeners();

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('AdService: BannerAd loaded successfully!');
          _isBannerLoaded = true;
          _bannerStatus = 'Loaded';
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          print('AdService: BannerAd failed to load: $error');
          ad.dispose();
          _isBannerLoaded = false;
          _bannerStatus = 'Failed: $error';
          _lastError = 'Banner: $error';
          notifyListeners();
        },
      ),
    );
    _bannerAd!.load();
  }

  void loadInterstitialAd() {
    if (!_isSupportedPlatform) return;

    print('AdService: Loading InterstitialAd...');
    _interstitialStatus = 'Loading...';
    notifyListeners();

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('AdService: InterstitialAd loaded successfully!');
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          _interstitialStatus = 'Loaded';
          _interstitialLoadAttempts = 0;
          
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('AdService: InterstitialAd dismissed.');
              ad.dispose();
              _isInterstitialLoaded = false;
              _interstitialStatus = 'Dismissed';
              loadInterstitialAd(); // Load the next one
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('AdService: InterstitialAd failed to show: $error');
              ad.dispose();
              _isInterstitialLoaded = false;
              _interstitialStatus = 'Failed to show: $error';
              _lastError = 'Show Interstitial: $error';
              loadInterstitialAd();
            },
          );
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          print('AdService: InterstitialAd failed to load: $error');
          _isInterstitialLoaded = false;
          _interstitialStatus = 'Failed: $error';
          _lastError = 'Interstitial: $error';
          _interstitialLoadAttempts++;
          if (_interstitialLoadAttempts < 3) {
            // Retry loading
            loadInterstitialAd();
          } else {
            notifyListeners();
          }
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (!_isSupportedPlatform) return;
    if (_isInterstitialLoaded && _interstitialAd != null) {
      print('AdService: Showing InterstitialAd...');
      _interstitialAd!.show();
    } else {
      print('AdService: InterstitialAd not loaded yet.');
      _interstitialStatus = 'Show attempted (Not loaded)';
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

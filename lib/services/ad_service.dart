import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/mock_interstitial_ad.dart';

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

  // Simulated ads and Pro preferences
  bool _useSimulatedAds = false;
  bool _isMockAd = false;
  bool _isPro = false;

  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerLoaded => _isBannerLoaded;
  bool get isInterstitialLoaded => _isInterstitialLoaded;
  String get initStatus => _initStatus;
  String get bannerStatus => _bannerStatus;
  String get interstitialStatus => _interstitialStatus;
  String? get lastError => _lastError;
  bool get useSimulatedAds => _useSimulatedAds;
  bool get isMockAd => _isMockAd;
  bool get isPro => _isPro;

  // Test Ad Unit IDs from Google
  static String get bannerAdUnitId {
    if (!kIsWeb && Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (!kIsWeb && Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (!kIsWeb && Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (!kIsWeb && Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  AdService() {
    _loadSettingsAndInit();
  }

  bool get _isSupportedPlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _loadSettingsAndInit() async {
    await loadSettings();
    await init();
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useSimulatedAds = prefs.getBool('use_simulated_ads') ?? false;
      _isPro = prefs.getBool('is_pro_version') ?? false;
      _isMockAd = _useSimulatedAds || !_isSupportedPlatform;
      notifyListeners();
    } catch (e) {
      debugPrint('AdService: Error loading settings: $e');
    }
  }

  Future<void> checkProStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPro = prefs.getBool('is_pro_version') ?? false;
    } catch (_) {}
  }

  void updateProStatus(bool value) {
    _isPro = value;
    if (_isPro) {
      // Pro active: dispose any active ads
      _bannerAd?.dispose();
      _bannerAd = null;
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isBannerLoaded = false;
      _isInterstitialLoaded = false;
      _bannerStatus = 'Not loaded (Pro)';
      _interstitialStatus = 'Not loaded (Pro)';
      _initStatus = 'initialized (Pro)';
    } else {
      // Re-initialize if Pro deactivated
      _bannerStatus = 'Not loaded';
      _interstitialStatus = 'Not loaded';
      init();
    }
    notifyListeners();
  }

  Future<void> setUseSimulatedAds(bool value) async {
    _useSimulatedAds = value;
    _isMockAd = value || !_isSupportedPlatform;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_simulated_ads', value);
    } catch (e) {
      debugPrint('AdService: Error saving settings: $e');
    }
    if (_isPro) return; // Do not load mock ads if Pro is active
    
    if (_isMockAd) {
      _loadMockAds();
    } else {
      _isBannerLoaded = false;
      _isInterstitialLoaded = false;
      _bannerStatus = 'Not loaded';
      _interstitialStatus = 'Not loaded';
      init();
    }
  }

  Future<void> init() async {
    await checkProStatus();
    if (_isPro) {
      debugPrint('AdService: Pro version active. Disabling ads initialization.');
      _initStatus = 'initialized (Pro)';
      _bannerStatus = 'Not loaded (Pro)';
      _interstitialStatus = 'Not loaded (Pro)';
      _isBannerLoaded = false;
      _isInterstitialLoaded = false;
      notifyListeners();
      return;
    }

    if (_isMockAd) {
      debugPrint('AdService: Initializing Mock Ad Service...');
      _initStatus = 'initialized (Simulated)';
      notifyListeners();
      _loadMockAds();
      return;
    }

    if (!_isSupportedPlatform) {
      _initStatus = 'Unsupported Platform';
      notifyListeners();
      return;
    }
    try {
      debugPrint('AdService: Initializing Mobile Ads SDK...');
      _initStatus = 'Initializing...';
      notifyListeners();
      await MobileAds.instance.initialize();
      debugPrint('AdService: Mobile Ads SDK initialized successfully.');
      _initStatus = 'initialized';
      notifyListeners();
      loadBannerAd();
      loadInterstitialAd();
    } catch (e) {
      debugPrint('AdService: AdMob initialization failed: $e');
      _initStatus = 'Failed: $e';
      _lastError = 'Init: $e';
      notifyListeners();
    }
  }

  void _loadMockAds() {
    if (_isPro) return; // No mock ads if Pro active
    
    _bannerStatus = 'Loading (Mock)...';
    _interstitialStatus = 'Loading (Mock)...';
    notifyListeners();
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!_isMockAd || _isPro) return;
      _isBannerLoaded = true;
      _bannerStatus = 'Loaded (Mock)';
      notifyListeners();
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!_isMockAd || _isPro) return;
      _isInterstitialLoaded = true;
      _interstitialStatus = 'Loaded (Mock)';
      notifyListeners();
    });
  }

  void dismissMockBanner() {
    _isBannerLoaded = false;
    _bannerStatus = 'Dismissed';
    notifyListeners();
  }

  void loadBannerAd() {
    if (_isPro || !_isSupportedPlatform || _isMockAd) return;
    
    debugPrint('AdService: Loading BannerAd...');
    _bannerStatus = 'Loading...';
    notifyListeners();

    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('AdService: BannerAd loaded successfully!');
          _isBannerLoaded = true;
          _bannerStatus = 'Loaded';
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: BannerAd failed to load: $error');
          ad.dispose();
          _isBannerLoaded = false;
          _bannerStatus = 'Failed: $error';
          _lastError = 'Banner: $error';
          
          if (error.message.contains('javascript engine') || error.message.contains('JavaScriptEngine')) {
            debugPrint('AdService: JavaScript Engine error detected. Falling back to Simulated Ads.');
            _isMockAd = true;
            _loadMockAds();
          } else {
            notifyListeners();
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  void loadInterstitialAd() {
    if (_isPro || !_isSupportedPlatform || _isMockAd) return;

    debugPrint('AdService: Loading InterstitialAd...');
    _interstitialStatus = 'Loading...';
    notifyListeners();

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdService: InterstitialAd loaded successfully!');
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          _interstitialStatus = 'Loaded';
          _interstitialLoadAttempts = 0;
          
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('AdService: InterstitialAd dismissed.');
              ad.dispose();
              _isInterstitialLoaded = false;
              _interstitialStatus = 'Dismissed';
              loadInterstitialAd(); // Load the next one
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: InterstitialAd failed to show: $error');
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
          debugPrint('AdService: InterstitialAd failed to load: $error');
          _isInterstitialLoaded = false;
          _interstitialStatus = 'Failed: $error';
          _lastError = 'Interstitial: $error';
          
          if (error.message.contains('javascript engine') || error.message.contains('JavaScriptEngine')) {
            debugPrint('AdService: JavaScript Engine error detected. Falling back to Simulated Ads.');
            _isMockAd = true;
            _loadMockAds();
          } else {
            _interstitialLoadAttempts++;
            if (_interstitialLoadAttempts < 3) {
              // Retry loading
              loadInterstitialAd();
            } else {
              notifyListeners();
            }
          }
        },
      ),
    );
  }

  void showInterstitialAd(BuildContext context) {
    if (_isPro) {
      debugPrint('AdService: Pro version active. Skipping interstitial ad.');
      return;
    }

    if (_isMockAd) {
      if (_isInterstitialLoaded) {
        _isInterstitialLoaded = false;
        _interstitialStatus = 'Dismissed (Mock)';
        notifyListeners();
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const MockInterstitialAdDialog(),
        ).then((_) {
          _loadMockAds();
        });
      } else {
        debugPrint('AdService: Simulated InterstitialAd not loaded yet.');
      }
      return;
    }

    if (!_isSupportedPlatform) return;
    if (_isInterstitialLoaded && _interstitialAd != null) {
      debugPrint('AdService: Showing InterstitialAd...');
      _interstitialAd!.show();
    } else {
      debugPrint('AdService: InterstitialAd not loaded yet.');
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

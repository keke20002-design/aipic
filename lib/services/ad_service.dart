import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _kBannerId = 'ca-app-pub-5381891295736795/9154797915';
const _kRewardedId = 'ca-app-pub-5381891295736795/4661755222';

/// google_mobile_ads는 Android/iOS 전용
bool get _adsSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  RewardedInterstitialAd? _rewardedAd;
  bool _isLoading = false;

  void preloadRewardedAd() {
    if (!_adsSupported || _rewardedAd != null || _isLoading) return;
    _isLoading = true;
    RewardedInterstitialAd.load(
      adUnitId: _kRewardedId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
        },
      ),
    );
  }

  /// 20% 확률로 광고 표시. 광고 없거나 확률 미달이면 즉시 onComplete 호출.
  void maybeShowRewardedAd({required VoidCallback onComplete}) {
    if (!_adsSupported || _rewardedAd == null || Random().nextDouble() >= 0.2) {
      onComplete();
      return;
    }
    _showAd(onComplete: onComplete);
  }

  /// 무조건 광고 표시 시도. 광고 없으면 즉시 onComplete 호출.
  void showRewardedAd({required VoidCallback onComplete}) {
    if (!_adsSupported || _rewardedAd == null) {
      onComplete();
      return;
    }
    _showAd(onComplete: onComplete);
  }

  void _showAd({required VoidCallback onComplete}) {
    final ad = _rewardedAd!;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
        onComplete();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        a.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
        onComplete();
      },
    );
    ad.show(onUserEarnedReward: (adItem, reward) {});
  }

  BannerAd? createBannerAd({required VoidCallback onLoaded}) {
    if (!_adsSupported) return null;
    return BannerAd(
      adUnitId: _kBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('[AdService] Banner failed: $error');
        },
      ),
    )..load();
  }
}

/// 하단 배너 광고 위젯 (Android/iOS 전용, 다른 플랫폼은 빈 공간)
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = AdService().createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_adsSupported || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}

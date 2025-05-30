import 'package:flutter/material.dart';
import 'package:interactive_media_ads/interactive_media_ads.dart';
import 'package:interactive_media_ads_demo/utils/urls.dart';
import 'package:video_player/video_player.dart';

class AdVideoController extends ChangeNotifier with WidgetsBindingObserver {
  late final VideoPlayerController contentVideoController;
  late final AdsLoader adsLoader;
  AdsManager? adsManager;

  bool shouldShowContentVideo = true;

  AppLifecycleState? _lastLifecycleState = AppLifecycleState.resumed;

  late final AdDisplayContainer adsDisplayContainer;

  AdVideoController() {
    WidgetsBinding.instance.addObserver(this);

    contentVideoController = VideoPlayerController.networkUrl(
      Uri.parse(
        Urls.contentVideoUrl,
      ),
    )
      ..addListener(_contentVideoListener)
      ..initialize().then((_) => notifyListeners());

    adsDisplayContainer = AdDisplayContainer(onContainerAdded: (container) {
      adsLoader = AdsLoader(
        container: container,
        onAdsLoaded: (OnAdsLoadedData data) {
          adsManager = data.manager;
          adsManager!.setAdsManagerDelegate(AdsManagerDelegate(
            onAdEvent: _onAdEvent,
            onAdErrorEvent: _onAdErrorEvent,
          ));
          adsManager!.init();
        },
        onAdsLoadError: (AdsLoadErrorData data) {
          debugPrint('Ads load error: ${data.error.message}');
          resumeContent();
        },
      );

      _requestAds(container);
    });
  }

  void _contentVideoListener() {
    if (contentVideoController.value.isInitialized) {
      if (contentVideoController.value.isCompleted) {
        adsLoader.contentComplete();
      }
      notifyListeners();
    }
  }

  Future<void> _requestAds(AdDisplayContainer container) async {
    await adsLoader.requestAds(AdsRequest(adTagUrl: Urls.adTagUrl));
  }

  void _onAdEvent(AdEvent event) {
    debugPrint('Ad event: ${event.type} | ad: ${event.adData}');
    switch (event.type) {
      case AdEventType.loaded:
        adsManager?.start();
        break;
      case AdEventType.contentPauseRequested:
        pauseContent();
        break;
      case AdEventType.contentResumeRequested:
        resumeContent();
        break;
      case AdEventType.allAdsCompleted:
        adsManager?.destroy();
        adsManager = null;
        break;
      case AdEventType.clicked:
      case AdEventType.complete:
      default:
        break;
    }
  }

  void _onAdErrorEvent(AdErrorEvent event) {
    debugPrint('Ad error event: ${event.error.message}');
    resumeContent();
  }

  Future<void> resumeContent() async {
    shouldShowContentVideo = true;
    notifyListeners();
    await contentVideoController.play();
  }

  Future<void> pauseContent() async {
    shouldShowContentVideo = false;
    notifyListeners();
    await contentVideoController.pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!shouldShowContentVideo) {
          resumeContent();
        }
        break;
      case AppLifecycleState.inactive:
        if (!shouldShowContentVideo &&
            _lastLifecycleState != AppLifecycleState.resumed) {
          pauseContent();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
    _lastLifecycleState = state;
  }

  @override
  void dispose() {
    contentVideoController.dispose();
    adsManager?.destroy();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

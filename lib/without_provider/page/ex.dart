import 'package:flutter/material.dart';
import 'package:interactive_media_ads/interactive_media_ads.dart';
import 'package:interactive_media_ads_demo/utils/urls.dart';
import 'package:video_player/video_player.dart';

class AdDemo extends StatefulWidget {
  const AdDemo({super.key});

  @override
  State<AdDemo> createState() => _AdDemoState();
}

class _AdDemoState extends State<AdDemo>
    with WidgetsBindingObserver {
  late final AdsLoader adsLoader;
  AdsManager? _adsManager;
  AppLifecycleState? _lastLifecycleState = AppLifecycleState.resumed;
  bool shouldShowContentVideo = true;
  late final VideoPlayerController _contentVideoController;

  late final AdDisplayContainer adsDisplayContainer = AdDisplayContainer(
    onContainerAdded: (AdDisplayContainer container) {
      adsLoader = AdsLoader(
          container: container,
          onAdsLoaded: (OnAdsLoadedData data) {
            final AdsManager manager = data.manager;
            _adsManager = manager;
            manager.setAdsManagerDelegate(
                AdsManagerDelegate(onAdEvent: (AdEvent event) {
              debugPrint('Ad event: ${event.type} => ${event.adData}');
              switch (event.type) {
                case AdEventType.loaded:
                  manager.start();
                  break;
                case AdEventType.contentPauseRequested:
                  pauseContent();
                  break;
                case AdEventType.contentResumeRequested:
                  resumeContent();
                  break;
                case AdEventType.allAdsCompleted:
                  manager.destroy();
                  _adsManager = null;
                  break;
                case AdEventType.clicked:
                case AdEventType.complete:
                default:
                  debugPrint('Unknown ad event: ${event.type}');
                  break;
              }
            }, onAdErrorEvent: (AdErrorEvent event) {
              debugPrint('Ad error event: ${event.error.message}');
              resumeContent();
            }));
            manager.init();
          },
          onAdsLoadError: (AdsLoadErrorData data) {
            debugPrint('OnAdsLoadErrorData: ${data.error.message}');
            resumeContent();
          });
      _requestAds(container);
    },
  );

  Future<void> _requestAds(AdDisplayContainer container) async {
    return adsLoader.requestAds(AdsRequest(adTagUrl: Urls.adTagUrl));
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _contentVideoController = VideoPlayerController.networkUrl(
      Uri.parse(
        Urls.contentVideoUrl,
      ),
    )
      ..addListener(() {
        if (_contentVideoController.value.isCompleted) {
          adsLoader.contentComplete();
        }
        setState(() {});
      })
      ..initialize().then((_) {
        setState(() {});
      });
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

  Future<void> resumeContent() async {
    setState(() {
      shouldShowContentVideo = true;
    });
    await _contentVideoController.play();
  }

  Future<void> pauseContent() async {
    setState(() {
      shouldShowContentVideo = false;
    });
    await _contentVideoController.pause();
  }

  @override
  void dispose() {
    _contentVideoController.dispose();
    _adsManager?.destroy();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
        child: SizedBox(
          width: 400,
          child: !_contentVideoController.value.isInitialized
              ? Container()
              : AspectRatio(
                  aspectRatio: _contentVideoController.value.aspectRatio,
                  child: Stack(
                    children: <Widget>[
                      adsDisplayContainer,
                      if (shouldShowContentVideo)
                        VideoPlayer(_contentVideoController)
                    ],
                  ),
                ),
        ),
      )),
      floatingActionButton:
          _contentVideoController.value.isInitialized && shouldShowContentVideo
              ? FloatingActionButton(
                  onPressed: () {
                    _contentVideoController.value.isPlaying
                        ? _contentVideoController.pause()
                        : _contentVideoController.play();
                  },
                  child: Icon(
                    _contentVideoController.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                )
              : null,
    );
  }
}
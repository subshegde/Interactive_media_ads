import 'package:flutter/material.dart';
import 'package:interactive_media_ads_demo/ads/provider/adProvider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class AdExampleDemoWidget extends StatelessWidget {
  const AdExampleDemoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdVideoController(),
      child: const AdExampleView(),
    );
  }
}

class AdExampleView extends StatelessWidget {
  const AdExampleView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdVideoController>();

    if (!controller.contentVideoController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white,));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('IMA',style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 400,
            child: AspectRatio(
              aspectRatio: controller.contentVideoController.value.aspectRatio,
              child: Stack(
                children: [
                  controller.adsDisplayContainer,
                  if (controller.shouldShowContentVideo)
                    VideoPlayer(controller.contentVideoController),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton:
          controller.contentVideoController.value.isInitialized &&
                  controller.shouldShowContentVideo
              ? FloatingActionButton(
                  backgroundColor: Colors.white70,
                  onPressed: () {
                    final isPlaying =
                        controller.contentVideoController.value.isPlaying;
                    isPlaying
                        ? controller.contentVideoController.pause()
                        : controller.contentVideoController.play();
                  },
                  child: Icon(
                      color: Colors.black,
                      controller.contentVideoController.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow),
                )
              : null,
    );
  }
}

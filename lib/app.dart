
import 'package:flutter/material.dart';
import 'package:interactive_media_ads_demo/with_provider/ads/pages/adExampleDemoWidget.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: const AdExampleDemoWidget(),
    );
  }
}

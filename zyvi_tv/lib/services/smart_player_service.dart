import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';

enum BandwidthProfile { low, high }

class SmartPlayerService {
  late BetterPlayerController _controller;
  BandwidthProfile _profile = BandwidthProfile.high;

  BetterPlayerController get controller => _controller;
  BandwidthProfile get currentProfile => _profile;

  void initializeSpeedOptimizedPlayer(String streamUrl,
      {BandwidthProfile profile = BandwidthProfile.high}) {
    _profile = profile;

    final bufferConfig = _profile == BandwidthProfile.low
        ? const BetterPlayerBufferingConfiguration(
            bufferForPlaybackMs: 3000,
            bufferForPlaybackAfterRebufferMs: 5000,
            minBufferMs: 10000,
            maxBufferMs: 30000,
          )
        : const BetterPlayerBufferingConfiguration(
            bufferForPlaybackMs: 500,
            bufferForPlaybackAfterRebufferMs: 1000,
            minBufferMs: 1500,
            maxBufferMs: 5000,
          );

    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        autoPlay: true,
        looping: false,
        allowedScreenSleep: false,
        showPlaceholderUntilPlay: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableSkips: false,
          enableFullscreen: true,
          enableMute: true,
          enableProgressText: false,
          enableProgressBar: false,
          controlBarColor: Colors.black38,
        ),
      ),
    );

    final dataSource = BetterPlayerDataSource.network(
      streamUrl,
      liveStream: true,
      bufferingConfiguration: bufferConfig,
    );

    _controller.setupDataSource(dataSource);
  }

  void updateStreamSourceInstantly(String newUrl,
      {BandwidthProfile profile = BandwidthProfile.high}) {
    _controller.clearCache();
    initializeSpeedOptimizedPlayer(newUrl, profile: profile);
  }

  void disposePlayer() {
    _controller.dispose();
  }
}

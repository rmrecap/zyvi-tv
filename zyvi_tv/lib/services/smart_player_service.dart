import 'dart:async';
import 'package:flutter/material.dart';
import 'package:better_player_enhanced/better_player.dart';

enum BandwidthProfile { low, medium, high, auto }

class SmartPlayerService {
  late BetterPlayerController _controller;
  BandwidthProfile _profile = BandwidthProfile.auto;
  String _currentUrl = '';

  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  StreamSubscription? _positionSub;
  Timer? _positionTimer;

  BetterPlayerController get controller => _controller;
  BandwidthProfile get currentProfile => _profile;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get bufferedStream => _bufferedController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

  String get profileLabel {
    switch (_profile) {
      case BandwidthProfile.low: return 'Low';
      case BandwidthProfile.medium: return 'Medium';
      case BandwidthProfile.high: return 'High';
      case BandwidthProfile.auto: return 'Auto';
    }
  }

  void initializeSpeedOptimizedPlayer(String streamUrl,
      {BandwidthProfile profile = BandwidthProfile.auto}) {
    _profile = profile;
    _currentUrl = streamUrl;

    final bufferConfig = _buildBufferConfig(profile);

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
          enableFullscreen: false,
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
    _controller.addEventsListener(_onPlayerEvent);
    _startPositionUpdates();
  }

  BetterPlayerBufferingConfiguration _buildBufferConfig(BandwidthProfile profile) {
    switch (profile) {
      case BandwidthProfile.low:
        return const BetterPlayerBufferingConfiguration(
          bufferForPlaybackMs: 5000,
          bufferForPlaybackAfterRebufferMs: 8000,
          minBufferMs: 15000,
          maxBufferMs: 30000,
        );
      case BandwidthProfile.medium:
        return const BetterPlayerBufferingConfiguration(
          bufferForPlaybackMs: 3000,
          bufferForPlaybackAfterRebufferMs: 5000,
          minBufferMs: 20000,
          maxBufferMs: 40000,
        );
      case BandwidthProfile.high:
        return const BetterPlayerBufferingConfiguration(
          bufferForPlaybackMs: 1500,
          bufferForPlaybackAfterRebufferMs: 3000,
          minBufferMs: 30000,
          maxBufferMs: 60000,
        );
      case BandwidthProfile.auto:
        return const BetterPlayerBufferingConfiguration(
          bufferForPlaybackMs: 3000,
          bufferForPlaybackAfterRebufferMs: 5000,
          minBufferMs: 20000,
          maxBufferMs: 40000,
        );
    }
  }

  void _startPositionUpdates() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final value = _controller.videoPlayerController?.value;
      if (value == null) return;
      _positionController.add(value.position);
      _durationController.add(value.duration ?? Duration.zero);
      if (value.buffered.isNotEmpty) {
        _bufferedController.add(value.buffered.first.end);
      }
    });
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
      _handlePlayerErrorFallback();
    }
  }

  void _handlePlayerErrorFallback() {
    _controller.clearCache();
    final fallbackDataSource = BetterPlayerDataSource.network(
      _currentUrl,
      liveStream: true,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        bufferForPlaybackMs: 5000,
        bufferForPlaybackAfterRebufferMs: 8000,
        minBufferMs: 15000,
        maxBufferMs: 30000,
      ),
    );
    _controller.setupDataSource(fallbackDataSource);
    _startPositionUpdates();
  }

  void cycleQuality() {
    const profiles = BandwidthProfile.values;
    final currentIndex = profiles.indexOf(_profile);
    final nextIndex = (currentIndex + 1) % profiles.length;
    final newProfile = profiles[nextIndex];
    updateStreamSourceInstantly(_currentUrl, profile: newProfile);
  }

  void updateStreamSourceInstantly(String newUrl,
      {BandwidthProfile profile = BandwidthProfile.auto}) {
    _controller.clearCache();
    initializeSpeedOptimizedPlayer(newUrl, profile: profile);
  }

  void switchToUrl(String newUrl) {
    updateStreamSourceInstantly(newUrl, profile: _profile);
  }

  void disposePlayer() {
    _positionTimer?.cancel();
    _positionSub?.cancel();
    _positionController.close();
    _bufferedController.close();
    _durationController.close();
    _controller.dispose();
  }
}

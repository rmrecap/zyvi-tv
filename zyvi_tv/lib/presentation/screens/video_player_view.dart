import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player_enhanced/better_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../data/models/channel_model.dart';
import '../../services/smart_player_service.dart';
import '../../services/pip_service.dart';
import '../widgets/custom_player_controls.dart';

class VideoPlayerView extends StatefulWidget {
  final List<ChannelModel> channels;
  final int initialIndex;

  const VideoPlayerView({
    super.key,
    required this.channels,
    this.initialIndex = 0,
  });

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView>
    with WidgetsBindingObserver {
  final SmartPlayerService _playerService = SmartPlayerService();
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    _enterFullscreen();
    _playCurrent();
    WakelockPlus.enable();
    PipService.enable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _exitFullscreen();
    _playerService.disposePlayer();
    WakelockPlus.disable();
    PipService.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      PipService.enterPictureInPicture();
    }
  }

  void _playCurrent() {
    if (_currentIndex < widget.channels.length) {
      final channel = widget.channels[_currentIndex];
      if (channel.sources.isNotEmpty) {
        _playerService.initializeSpeedOptimizedPlayer(channel.sources.first.url);
      }
    }
  }

  void _onNext() {
    if (_currentIndex < widget.channels.length - 1) {
      setState(() => _currentIndex++);
      _playCurrent();
    }
  }

  void _onPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _playCurrent();
    }
  }

  void _onQualityChange() {
    _playerService.cycleQuality();
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  void _onBackPressed() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          BetterPlayer(
            controller: _playerService.controller,
          ),
          CustomPlayerControls(
            playerService: _playerService,
            channels: widget.channels,
            currentIndex: _currentIndex,
            onBack: _onBackPressed,
            onNext: _onNext,
            onPrev: _onPrev,
            onQualityChange: _onQualityChange,
          ),
        ],
      ),
    );
  }
}

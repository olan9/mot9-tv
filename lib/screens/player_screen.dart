import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../services/watch_history_service.dart';

class PlayerScreen extends StatefulWidget {
  final String id;
  final String title;
  final String url;
  final String? poster;
  final String type;
  final int startPositionMs;

  const PlayerScreen({
    super.key,
    required this.id,
    required this.title,
    required this.url,
    this.poster,
    this.type = 'movie',
    this.startPositionMs = 0,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _ctrl;
  bool _loading = true;
  bool _error = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _ctrl.initialize();
      if (widget.startPositionMs > 0) {
        await _ctrl.seekTo(Duration(milliseconds: widget.startPositionMs));
      }
      _ctrl.play();
      _ctrl.addListener(_onProgress);
      if (mounted) setState(() => _loading = false);
      _hideControlsDelayed();
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  void _onProgress() {
    if (_ctrl.value.isPlaying) {
      WatchHistoryService.save(WatchEntry(
        id: widget.id,
        name: widget.title,
        poster: widget.poster,
        url: widget.url,
        positionMs: _ctrl.value.position.inMilliseconds,
        durationMs: _ctrl.value.duration.inMilliseconds,
        watchedAt: DateTime.now(),
        type: widget.type,
      ));
    }
  }

  void _hideControlsDelayed() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _ctrl.value.isPlaying) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _hideControlsDelayed();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onProgress);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              _toggleControls();
            } else if (event.logicalKey == LogicalKeyboardKey.goBack ||
                event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
            } else if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
              if (!_loading && !_error) {
                _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
                setState(() {});
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _ctrl.seekTo(_ctrl.value.position + const Duration(seconds: 10));
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _ctrl.seekTo(_ctrl.value.position - const Duration(seconds: 10));
            }
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
            else if (_error)
              Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white54, size: 56),
                  const SizedBox(height: 12),
                  const Text('تعذّر تشغيل المحتوى', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
                    child: const Text('رجوع'),
                  ),
                ],
              ))
            else
              Center(child: AspectRatio(
                aspectRatio: _ctrl.value.aspectRatio,
                child: VideoPlayer(_ctrl),
              )),
            if (_showControls && !_loading && !_error) ...[
              // Top bar
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  decoration: const BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  )),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              // Bottom controls
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  decoration: const BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  )),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(_ctrl, allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFFE50914),
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                            onPressed: () => _ctrl.seekTo(_ctrl.value.position - const Duration(seconds: 10)),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(_ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
                            onPressed: () {
                              _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                            onPressed: () => _ctrl.seekTo(_ctrl.value.position + const Duration(seconds: 10)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

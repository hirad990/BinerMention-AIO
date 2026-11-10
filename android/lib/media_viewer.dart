import 'localized_text.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BinerMediaViewer {
  const BinerMediaViewer._();

  static Future<void> open(
    BuildContext context, {
    required String url,
    String? mimeType,
    String? title,
  }) async {
    if (!url.startsWith('https://')) return;
    final video = mimeType?.startsWith('video/') == true ||
        RegExp(r'\.(mp4|webm)(\?|$)', caseSensitive: false).hasMatch(url);
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: _BinerMediaViewerPage(url: url, isVideo: video, title: title ?? 'رسانه'),
        ),
      ),
    );
  }
}

class _BinerMediaViewerPage extends StatefulWidget {
  const _BinerMediaViewerPage({required this.url, required this.isVideo, required this.title});
  final String url;
  final bool isVideo;
  final String title;

  @override
  State<_BinerMediaViewerPage> createState() => _BinerMediaViewerPageState();
}

class _BinerMediaViewerPageState extends State<_BinerMediaViewerPage> {
  VideoPlayerController? _video;
  bool _ready = false;
  bool _failed = false;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _video = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
      }).catchError((_) {
        if (mounted) setState(() { _ready = false; _failed = true; });
      });
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  String _time(Duration value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    return hours > 0 ? '${two(hours)}:${two(minutes)}:${two(seconds)}' : '${two(minutes)}:${two(seconds)}';
  }

  Future<void> _setSpeed(double value) async {
    setState(() => _speed = value);
    await _video?.setPlaybackSpeed(value);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _video;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF05070B),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: BinerLocalizedText(widget.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        actions: [
          if (widget.isVideo && _ready)
            PopupMenuButton<double>(
              tooltip: 'سرعت پخش',
              initialValue: _speed,
              onSelected: _setSpeed,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 1, child: BinerLocalizedText('1×')),
                PopupMenuItem(value: 1.5, child: BinerLocalizedText('1.5×')),
                PopupMenuItem(value: 2, child: BinerLocalizedText('2×')),
                PopupMenuItem(value: 3, child: BinerLocalizedText('3×')),
              ],
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Center(child: BinerLocalizedText('${_speed}×', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
            ),
        ],
      ),
      body: Center(
        child: widget.isVideo
            ? (controller == null || !_ready || !controller.value.isInitialized
                ? (_failed
                    ? const Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.error_outline_rounded, color: Colors.white70, size: 42),
                        SizedBox(height: 10),
                        BinerLocalizedText('پخش ویدیو ممکن نشد.', style: TextStyle(color: Colors.white70)),
                      ])
                    : const CircularProgressIndicator(color: Color(0xFF54C8FF)))
                : AspectRatio(
                    aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
                    child: Stack(alignment: Alignment.center, children: [
                      VideoPlayer(controller),
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: controller,
                        builder: (context, current, _) => current.isPlaying
                            ? GestureDetector(onTap: () => controller.pause(), child: const SizedBox.expand())
                            : IconButton.filled(
                                onPressed: () => controller.play(),
                                style: IconButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white, fixedSize: const Size(62, 62)),
                                icon: const Icon(Icons.play_arrow_rounded, size: 34),
                              ),
                      ),
                    ]),
                  ))
            : InteractiveViewer(
                minScale: .6,
                maxScale: 5,
                panEnabled: true,
                child: Center(
                  child: Image.network(
                    widget.url,
                    cacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round().clamp(1, 1600).toInt(),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    loadingBuilder: (context, child, progress) => progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator(color: Color(0xFF54C8FF))),
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white70, size: 48),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: widget.isVideo && _ready && controller != null
          ? ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, current, _) => SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Row(children: [
                    BinerLocalizedText(_time(current.position), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Expanded(
                      child: VideoProgressIndicator(controller, allowScrubbing: true, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), colors: const VideoProgressColors(playedColor: Color(0xFF54C8FF), bufferedColor: Colors.white24, backgroundColor: Colors.white12)),
                    ),
                    BinerLocalizedText(_time(current.duration), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    IconButton(
                      onPressed: () => current.isPlaying ? controller.pause() : controller.play(),
                      color: const Color(0xFF54C8FF),
                      icon: Icon(current.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
                  ]),
                ),
              ),
            )
          : null,
    );
  }
}

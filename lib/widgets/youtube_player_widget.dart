import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YouTubePlayerWidget extends StatefulWidget {
  final String videoId;

  const YouTubePlayerWidget({super.key, required this.videoId});

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Player loaded
          },
        ),
      )
      ..loadHtmlString(_getHtml(widget.videoId));
  }

  String _getHtml(String videoId) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { margin: 0; padding: 0; background: #000; }
          #player { width: 100%; height: 100%; }
        </style>
      </head>
      <body>
        <div id="player"></div>
        <script src="https://www.youtube.com/iframe_api"></script>
        <script>
          var player;
          function onYouTubeIframeAPIReady() {
            player = new YT.Player('player', {
              height: '100%',
              width: '100%',
              videoId: '$videoId',
              playerVars: {
                'playsinline': 1,
                'controls': 0,
                'modestbranding': 1,
                'rel': 0
              },
              events: {
                'onReady': onPlayerReady,
                'onStateChange': onPlayerStateChange
              }
            });
          }

          function onPlayerReady(event) {
            event.target.playVideo();
          }

          function onPlayerStateChange(event) {
            if (event.data == YT.PlayerState.PLAYING) {
              sendToFlutter('playing');
            } else if (event.data == YT.PlayerState.PAUSED) {
              sendToFlutter('paused');
            } else if (event.data == YT.PlayerState.ENDED) {
              sendToFlutter('ended');
            }
          }

          function sendToFlutter(message) {
            if (window.FlutterPlayer) {
              window.FlutterPlayer.postMessage(message);
            }
          }

          function play() {
            if (player && player.playVideo) {
              player.playVideo();
            }
          }

          function pause() {
            if (player && player.pauseVideo) {
              player.pauseVideo();
            }
          }

          function seekTo(seconds) {
            if (player && player.seekTo) {
              player.seekTo(seconds, true);
            }
          }

          function getCurrentTime() {
            if (player && player.getCurrentTime) {
              return player.getCurrentTime();
            }
            return 0;
          }

          function setVolume(volume) {
            if (player && player.setVolume) {
              player.setVolume(volume * 100);
            }
          }
        </script>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
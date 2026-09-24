import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/lyrics.dart';
import '../services/itunes_service.dart';
import '../services/lyrics_service.dart';
import '../services/youtube_service.dart';

class MusicProvider extends ChangeNotifier {
  final ITunesService _itunesService = ITunesService();
  final LyricsService _lyricsService = LyricsService();
  final YouTubeService _youtubeService = YouTubeService();

  List<Song> _searchResults = [];
  List<Song> _queue = [];
  Song? _currentSong;
  Lyrics? _currentLyrics;
  bool _isPlaying = false;
  double _currentPosition = 0.0;
  double _volume = 1.0;
  bool _isLoading = false;
  String? _errorMessage;

  List<Song> get searchResults => _searchResults;
  List<Song> get queue => _queue;
  Song? get currentSong => _currentSong;
  Lyrics? get currentLyrics => _currentLyrics;
  bool get isPlaying => _isPlaying;
  double get currentPosition => _currentPosition;
  double get volume => _volume;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> searchSongs(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _itunesService.searchSongs(query);
    } catch (e) {
      _errorMessage = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playSong(Song song) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Search for YouTube video ID
      final videoId = await _youtubeService.searchVideoId(song.title, song.artist);
      final songWithVideo = song.copyWith(youtubeVideoId: videoId);

      _currentSong = songWithVideo;
      _queue = [songWithVideo];
      _isPlaying = true;
      _currentPosition = 0.0;

      // Load lyrics
      _currentLyrics = await _lyricsService.searchLyrics(song.title, song.artist);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void playNext() {
    if (_queue.isEmpty) return;

    final currentIndex = _currentSong != null ? _queue.indexOf(_currentSong!) : -1;
    if (currentIndex < _queue.length - 1) {
      playSong(_queue[currentIndex + 1]);
    }
  }

  void playPrevious() {
    if (_queue.isEmpty) return;

    final currentIndex = _currentSong != null ? _queue.indexOf(_currentSong!) : -1;
    if (currentIndex > 0) {
      playSong(_queue[currentIndex - 1]);
    }
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void seekTo(double position) {
    _currentPosition = position;
    notifyListeners();
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }

  void updatePosition(double position) {
    _currentPosition = position;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  set searchResults(List<Song> value) {
    _searchResults = value;
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
}
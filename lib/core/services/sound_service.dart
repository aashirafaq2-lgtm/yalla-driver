import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  Timer? _ringtoneTimeoutTimer;
  bool _isPlayingRingtone = false;

  bool get isPlayingRingtone => _isPlayingRingtone;

  /// Plays incoming ride request ringtone with auto-looping and a hard safety timeout
  /// of 25 seconds to guarantee it NEVER rings indefinitely.
  Future<void> playRideRequest({int timeoutSeconds = 25}) async {
    try {
      stopRingtone();
      _isPlayingRingtone = true;

      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/ride_request.mp3'), volume: 1.0);

      // Hard safety timer: automatically stop after timeoutSeconds
      _ringtoneTimeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
        debugPrint('[SoundService] Ringtone reached $timeoutSeconds s timeout, stopping.');
        stopRingtone();
      });
    } catch (e) {
      debugPrint('[SoundService] Error playing ride request ringtone: $e');
    }
  }

  /// Stops ringtone immediately (called on Accept, Decline, Cancel, or Dismiss)
  Future<void> stopRingtone() async {
    _ringtoneTimeoutTimer?.cancel();
    _ringtoneTimeoutTimer = null;
    _isPlayingRingtone = false;
    try {
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.stop();
    } catch (e) {
      debugPrint('[SoundService] Error stopping ringtone: $e');
    }
  }

  Future<void> playRideAccepted() async {
    try {
      stopRingtone();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.play(AssetSource('sounds/ride_accepted.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('[SoundService] Error playing ride accepted sound: $e');
    }
  }

  Future<void> playRideCompleted() async {
    try {
      stopRingtone();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.play(AssetSource('sounds/ride_completed.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('[SoundService] Error playing ride completed sound: $e');
    }
  }

  Future<void> playRideCancelled() async {
    try {
      stopRingtone();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.play(AssetSource('sounds/ride_cancelled.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('[SoundService] Error playing ride cancelled sound: $e');
    }
  }

  Future<void> stop() async {
    await stopRingtone();
  }

  void dispose() {
    _ringtoneTimeoutTimer?.cancel();
    _player.dispose();
  }
}

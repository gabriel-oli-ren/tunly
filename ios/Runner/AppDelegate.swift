import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    setupAudioSession()
    setupRemoteControl()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupAudioSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(
        .playback,
        mode: .default,
        options: [.allowAirPlay, .allowBluetooth, .mixWithOthers]
      )
      try session.setActive(true)
    } catch {
      print("Failed to setup audio session: \(error)")
    }
  }
  
  private func setupRemoteControl() {
    UIApplication.shared.beginReceivingRemoteControlEvents()
    self.becomeFirstResponder()
  }
  
  override var canBecomeFirstResponder: Bool {
    return true
  }
  
  override func remoteControlReceived(with event: UIEvent?) {
    guard let event = event, event.type == .remoteControl else { return }
    
    switch event.subtype {
    case .remoteControlPlay:
      // Handle play - will be handled by Flutter youtube player
      break
    case .remoteControlPause:
      // Handle pause - will be handled by Flutter youtube player
      break
    case .remoteControlNextTrack:
      // Handle next track
      break
    case .remoteControlPreviousTrack:
      // Handle previous track
      break
    default:
      break
    }
  }
}
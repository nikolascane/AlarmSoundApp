//
//  AudioPlayer.swift
//  AlarmSoundApp
//
//  Created by Nik Cane on 29.03.2020.
//  Copyright © 2020 Nik Cane. All rights reserved.
//

import UIKit
import AVFoundation

public enum PlaybackOptions: Int {
  case infinite = -1
  case once = 1
}

final internal class AudioPlayer: NSObject {
  var player: AVAudioPlayer?
  
  internal init(url: URL, playbackOptions: PlaybackOptions) {
    do {
      self.player = try AVAudioPlayer(contentsOf: url)
      self.player?.numberOfLoops = playbackOptions.rawValue
    }catch let error{
      print("Initializing player error: \(error)")
    }
    super.init()
    self.player?.delegate = self
  }
  
  internal func play() {
    if self.player?.isPlaying == false {
      self.player?.prepareToPlay()
    }
    self.player?.play()
  }
  
  internal func pause() {
    self.player?.pause()
  }
  
  internal func resume() {
    self.play()
  }
}

extension AudioPlayer: AVAudioPlayerDelegate {
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    print("Decode error: \(error)")
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    print("Playback finished")
  }
}

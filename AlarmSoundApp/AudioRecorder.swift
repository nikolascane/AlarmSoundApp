//
//  AudioRecorder.swift
//  AlarmSoundApp
//
//  Created by Nik Cane on 29.03.2020.
//  Copyright © 2020 Nik Cane. All rights reserved.
//

import UIKit
import AVFoundation

public enum RecordOptions {
  case using(name: String, ext: String)
  case randomFile
  case timeBased
}

public enum RecordQiality {
  case voice
  case byDefault
  case highQuality
}

final internal class AudioRecorder: NSObject {
  var recorder: AVAudioRecorder?
  internal init(url: URL, settings: [String: Any]) {
    do {
      if let format = AVAudioFormat.init(settings: settings) {
        self.recorder = try AVAudioRecorder(url: url, format: format)
      }
    }catch let error {
      print("Can't create recoder: \(error)")
    }
    super.init()
    self.recorder?.delegate = self
  }
  
  internal func record(atTime: TimeInterval, forDuration: TimeInterval) throws {
    try AVAudioSession.sharedInstance().setActive(true)
    if self.recorder?.prepareToRecord() == true {
      self.recorder?.record(atTime: atTime, forDuration: forDuration)
    }
  }
}

extension AudioRecorder: AVAudioRecorderDelegate {
  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    print("Encode error: \(error)")
  }
  
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    print("Record finished")
  }
}

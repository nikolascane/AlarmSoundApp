//
//  SoundManager.swift
//  AlarmSoundApp
//
//  Created by Nik Cane on 29.03.2020.
//  Copyright © 2020 Nik Cane. All rights reserved.
//

import UIKit
import AVFoundation

public enum SoundError: Error {
  case fileNameIsEmpty
  case wrongFileName
  case pathIsNotDefined
}

protocol Player {
  func play(url: URL, playbackOptions: PlaybackOptions)
  func pause()
  func resume()
  func stop()
}

protocol Recorder {
  func record(name: String) throws
  func record(to url: URL?) throws
  func record(options: RecordOptions) throws
}

private let defaultFileExtension = "m4a"

final public class SoundManager {
  public static let sharedInstance = SoundManager()
  
  public var recordQuality: RecordQiality = .byDefault
  public var recordDuration: Int = 60
  
  private var player: AudioPlayer?
  private var recorder: AudioRecorder?
  
  
  public func configureAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
    }
    catch let error {
      print("Can't set: \(error)")
    }
  }
}

extension SoundManager: Player {
  public func play(url: URL, playbackOptions: PlaybackOptions) {
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    }
    catch let error {
      print("Can't activate Audio session \(error)")
    }
    self.player = AudioPlayer(url: url, playbackOptions: playbackOptions)
    self.player?.play()
  }
  
  public func pause() {
    self.player?.pause()
  }
  
  public func resume() {
    self.player?.resume()
  }
  
  public func stop() {
    do {
      try AVAudioSession.sharedInstance().setActive(false)
    }
    catch let error {
      print("Can't stop audio session:\(error)")
    }
  }
}

extension SoundManager: Recorder {
  
  public func record(name: String) throws {
    guard !name.isEmpty else {
      throw(SoundError.fileNameIsEmpty)
    }
    let fileName = try self.decompose(name: name)
    try self.record(options: .using(name: fileName.name, ext: fileName.ext))
  }
  
  private func decompose(name: String) throws -> (name: String, ext: String) {
    guard name.contains(".") else {
      throw(SoundError.wrongFileName)
    }
    let nameComponents = name.components(separatedBy: ".")
    guard nameComponents.count == 2 else {
      throw(SoundError.wrongFileName)
    }
    if let name = nameComponents.first, let ext = nameComponents.last {
      return (name: name, ext: ext)
    }
    throw(SoundError.wrongFileName)
  }
  
  public func record(to url: URL?) throws {
    try self.startRecord(url: url)
  }
  
  public func record(options: RecordOptions) throws {
    switch options {
    case .using(name: let name, ext: let ext):
      try startRecordUsing(name: name, ext: ext)
    case .randomFile:
      try self.startRandomRecord()
    case .timeBased:
      try self.startTimeBasedRecord()
    }
  }
  
  private func startRecordUsing(name: String, ext: String) throws {
    let url = PathManager.namedDirectory(name, ext: ext)
    try self.startRecord(url: url)
  }
  
  private func startRandomRecord() throws {
    let url = PathManager.randomDirectory()?.appendingPathExtension(defaultFileExtension)
    try self.startRecord(url: url)
  }
  
  private func startTimeBasedRecord() throws {
    let url = PathManager.timeBasedDirectory()?.appendingPathExtension(defaultFileExtension)
    try self.startRecord(url: url)
  }
  
  private func startRecord(url: URL?) throws {
    guard let url = url else {
      throw(SoundError.pathIsNotDefined)
    }
    self.recorder = AudioRecorder(url: url, settings: self.recordSettings(quality: self.recordQuality))
    try self.recorder?.record(atTime: 0, forDuration: 30)
  }
  
  
  
  private func recordSettings(quality: RecordQiality) -> [String: Any] {
    switch quality {
    case .voice:
      return RecordSettings.voiceSettings()
    case .byDefault:
      return RecordSettings.defaultSettings()
    case .highQuality:
      return RecordSettings.hqSettings()
    }
  }
}

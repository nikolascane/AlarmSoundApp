//
//  AlarmViewModel.swift
//  AlarmSoundApp
//
//  Created by Nik Cane on 29.03.2020.
//  Copyright © 2020 Nik Cane. All rights reserved.
//

import Foundation
import Combine
import SoundMan
import UIKit

enum ApplicationState: String {
  case idle = "Idle"
  case playing = "Playing"
  case recording = "Recording"
  case paused = "Paused"
  case alarm = "Alarm"
}

enum AlarmTime: String {
  case minute
  case hour
  case day
  case week
  
  var value: TimeInterval {
    switch self {
    case .minute: return 60
    case .hour:   return 60*60
    case .day:    return 24*60*60
    case .week:   return 7*24*60*60
    }
  }
}

struct Minute: Identifiable {
  let id: Int
}

enum AlarmError: Swift.Error, CustomStringConvertible, Identifiable {
  var id: String { self.description }
  
  case incorrectAlarmTime(String)
  case alarm(String)
  case cannotStartRecording(String)
  case settingsChanged(String)
  case unknown
  
  var description: String {
    switch self {
    case .incorrectAlarmTime(let error):
      return "Incorrect alarm time: \(error)"
    case .alarm(let error):
      return "Attention: \(error)"
    case .cannotStartRecording(let error):
      return "Can't start recording: \(error)"
    case .settingsChanged(let error):
      return "App settings are changed: \(error)"
    case .unknown:
      return "The unknown error has occured"
    }
  }
}

enum PickerType {
  case sleepTime
  case alarmDate
}

enum InternalSound: String {
  case nature
  case alarm
  
  var url: URL? {
    var name = ""
    switch self {
    case .alarm: name = "alarm"
    case .nature: name = "nature"
    }
    if let path = Bundle.main.path(forResource: name, ofType: "m4a") {
      return URL(fileURLWithPath: path)
    }
    return nil
  }
}

private let recordsKey = "recordedSoundsKey"

class AlarmViewModel: ObservableObject {
  
  @Published var appState: ApplicationState = .idle
  @Published var maxTimeRange = AlarmTime.day
  @Published var alarmError: AlarmError?
  @Published var commandName: String = ""
  
  @Published var alarmDate = Date(timeIntervalSinceNow: AlarmTime.hour.value)
  @Published var alarmTime: String = ""
  @Published var sleepTime: Int = 1
  
  @Published var soundMuted: Bool = false
  @Published var muteButtonTitle: String = ""
  @Published var abortButtonTitle: String = ""
  
  @Published var records: [URL] = []
  
  private var countdownTimer: CountdownTimer?
  
  private var subscriptions = Set<AnyCancellable>()
  
  var minutes: [Minute] = (1...60).map{ Minute(id: $0) }
  var alarmTimeRange: ClosedRange<Date> {
    Date(timeIntervalSinceNow: TimeInterval(self.sleepTime) * AlarmTime.minute.value)...Date(timeIntervalSinceNow: self.maxTimeRange.value)
  }
  
  private let soundManager = SoundManager()
  
  init() {
    self.configSoundManager()
    self.configBinding()
    self.configNotifications()
  }
  
}
 
//MARK: Setup
extension AlarmViewModel {
  
  private func configNotifications() {
    NotificationManager.requestNotificaiton()
    NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self]_ in
      if let self = self,
        (self.appIsPlaying(state: self.appState) || self.appIsRecording(state: self.appState)) {
        self.scheduleNotification()
      }
    }
    NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
      NotificationManager.cancelNotificaiton()
    }
  }
  
  private func configSoundManager() {
    self.soundManager.configureAudioSession()
    self.soundManager.delegate = self
  }
  
  private func configBinding() {
    self.$appState
      .map(self.buttonCommandName)
      .assign(to: \.commandName, on: self)
      .store(in: &subscriptions)
    self.$appState
      .map(self.abortButtonName)
      .assign(to: \.abortButtonTitle, on: self)
      .store(in: &subscriptions)
    self.$appState
      .combineLatest(self.$soundMuted)
      .map{state, muted in
        if self.appIsPlaying(state: state) {
          return muted ? "play" : "mute"
        }
        return ""
      }
      .assign(to: \.muteButtonTitle, on: self)
      .store(in: &subscriptions)
    self.$alarmDate
      .map(specifyAlarmTimeDecscription(date:))
      .assign(to: \.alarmTime, on: self)
      .store(in: &subscriptions)
    self.$alarmDate
      .combineLatest(self.$sleepTime)
      .filter{_ in
        return self.appIsRecording(state: self.appState) || self.appIsPlaying(state: self.appState)
      }
      .map{_ in
        AlarmError.settingsChanged("alarm time was changed.\nApp stops activity")
      }
      .handleEvents(receiveOutput: { _ in
        self.stopPlayRecordFlow()
      })
      .assign(to: \.alarmError, on: self)
      .store(in: &subscriptions)
    self.$sleepTime
      .filter(self.sleepTimeAndAlarmOutOfSync)
      .sink{ _ in
        self.synchronizeAlarmDate()
      }
      .store(in: &subscriptions)
  }
}

//MARK: Logic
extension AlarmViewModel {
  
  private func setDefaultState() {
    self.appState = .idle
    self.sleepTime = 1
    self.alarmDate = Date(timeIntervalSinceNow: AlarmTime.hour.value)
  }
  
  private func specifyAlarmTimeDecscription(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm"
    return formatter.string(from: date)
  }
  
  
  private func sleepTimeAndAlarmOutOfSync(_ sleepTime: Int) -> Bool {
    let timeOffset = TimeInterval(sleepTime) * AlarmTime.minute.value
    return self.alarmDate < Date(timeIntervalSinceNow: timeOffset)
  }
  
  private func synchronizeAlarmDate() {
      self.alarmDate = Date(timeIntervalSinceNow: AlarmTime.hour.value)
      self.alarmError = .incorrectAlarmTime("Alarm time was set before sleep time expired.\nIt was automatically adjusted according to new sleep time settings")
  }
  
  private func appIsPlaying(state: ApplicationState) -> Bool {
    switch state {
    case .idle, .alarm, .recording:
      return false
    default:
      return true
    }
  }
  
  private func appIsRecording(state: ApplicationState) -> Bool {
    return state == .recording
  }
  
  private func buttonCommandName(_ state: ApplicationState) -> String {
    switch state {
    case .idle, .paused, .alarm:
      return "Play"
    case .playing, .recording:
      return "Pause"
    }
  }
  
  private func abortButtonName(_ state: ApplicationState) -> String {
    switch state {
    case .playing, .recording, .paused:
      return "abort"
    default:
      return ""
    }
  }
  
  func playbackCommand() {
    switch self.appState {
    case .idle:()
      self.startPlayRecordFlow()
    case .playing:()
      self.pausePlayFlow()
    case .recording: ()
      self.pauseRecordFlow()
    case .paused:()
      self.resumePlayRecordFlow()
    case .alarm:
      return
    }
  }
  
  func mute() {
    guard self.appIsPlaying(state: self.appState) else  {return}
    if self.soundMuted {
      self.soundMuted = false
      self.soundManager.resumePlaying()
    }
    else {
      self.soundMuted = true
      self.soundManager.pausePlaying()
    }
  }
  
  private func startPlayRecordFlow() {
    if let url = InternalSound.nature.url {
      self.soundManager.play(url: url, playbackOptions: .infinite)

      let sleepDuration = TimeInterval(self.sleepTime) * AlarmTime.minute.value
      self.countdownTimer = CountdownTimer(duration: sleepDuration, start: true, timeElapsed: { [weak self] in
        self?.sleepTimeElapsed()
      })
      self.appState = .playing
    }
    else {
      self.alarmError = AlarmError.cannotStartRecording("sound file not found")
    }
  }
  
  private func sleepTimeElapsed() {
    self.soundManager.pausePlaying()
    self.stopCoundownTimer()
    self.startTimeBasedRecording()
  }
  
  private func startTimeBasedRecording() {
    do {
      try self.soundManager.record(options: .timeBased, duration: self.alarmDate.timeIntervalSinceNow)
      self.appState = .recording
    }
    catch let error {
      self.alarmError = error as? AlarmError ?? .unknown
    }
  }
  
  private func resumePlayRecordFlow() {
    self.countdownTimer?.resume()
    self.soundManager.resumePlaying()
    self.appState = .playing
  }
  
  private func pausePlayFlow() {
    self.countdownTimer?.pause()
    self.soundManager.pausePlaying()
    self.appState = .paused
  }
  
  private func pauseRecordFlow() {
    self.soundManager.pauseRecording()
    self.appState = .paused
  }
  
  private func stopCoundownTimer() {
    self.countdownTimer?.pause()
    self.countdownTimer = nil
  }
  
  func stopPlayRecordFlow() {
    self.stopCoundownTimer()
    self.soundManager.stop()
    self.setDefaultState()
  }
  
  private func finishPlayRecordFlow() {
    self.stopPlayRecordFlow()
    self.setTimeWentOffAlarm()
    self.appState = .alarm
  }
  
  private func setTimeWentOffAlarm() {
    if let url = InternalSound.alarm.url {
      self.soundManager.play(url: url, playbackOptions: .once)
    }
    self.alarmError = AlarmError.alarm("Time went off!")
  }
  
  private func scheduleNotification() {
    NotificationManager
      .scheduleNotification(alarmDate: self.alarmDate, message: "Record finished", title: "Time went off!")
  }
}

//MARK: Storage
extension AlarmViewModel {
  private func storeRecordedURL(_ url: URL) {
    self.records.append(url)
    StorageManager.store(list: records, as: recordsKey)
  }
}

extension AlarmViewModel: SoundManagerDelegate {
  func audioRecorderEncodeError(error: Error?) { }
  func audioRecorderDidFinishRecording(successfully: Bool) {
    self.finishPlayRecordFlow()
  }
  func audioPlayerDecodeError(error: Error?) {}
  func audioPlayerDidFinishPlaying(successfully: Bool) {}
}

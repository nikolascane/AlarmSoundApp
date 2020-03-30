//
//  AlarmViewModel.swift
//  AlarmSoundApp
//
//  Created by Nik Cane on 29.03.2020.
//  Copyright © 2020 Nik Cane. All rights reserved.
//

import Foundation
import Combine

enum ApplicationState: String {
  case idle = "Idle"
  case playing = "Playing"
  case recording = "Recording"
  case paused = "Paused"
  case alarm = "Alarm"
}

protocol AlarmModel {
  var sleepTime: Int {get set}
  var alarmTime: Date {get set}
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

enum AlarmError: Error {
  case incorrectAlarmTime(String)
  case alarm(String)
}

enum PickerType {
  case sleepTime
  case alarmDate
}

class AlarmViewModel: ObservableObject, AlarmModel {
  
  @Published var alarmTime = Date(timeIntervalSinceNow: AlarmTime.hour.value)
  @Published var appState: ApplicationState = .idle
  @Published var maxTimeRange = AlarmTime.day
  @Published var alarmError: AlarmError?
  @Published var commandName: String = ""
  
  var sleepTime: Int = 1 {
    didSet {
      self.synchronizeAlarmTime(with:self.sleepTime)
    }
  }
  
  private var subscriptions = Set<AnyCancellable>()
  
  var minutes: [Minute] = (1...60).map{ Minute(id: $0) }
  var alarmTimeRange: ClosedRange<Date> {
    Date(timeIntervalSinceNow: TimeInterval(self.sleepTime) * AlarmTime.minute.value)...Date(timeIntervalSinceNow: AlarmTime.day.value)
  }
  
  init() {
    self.$appState
      .map(self.buttonCommandName(state:))
      .assign(to: \.commandName, on: self)
      .store(in: &subscriptions)
  }
  
  private func synchronizeAlarmTime(with sleepTime: Int) {
    let timeOffset = TimeInterval(sleepTime) * AlarmTime.minute.value
    if self.alarmTime < Date(timeIntervalSinceNow: timeOffset) {
      self.alarmTime = Date(timeIntervalSinceNow: AlarmTime.hour.value)
      self.alarmError = .incorrectAlarmTime("Alarm time was set before sleep time expired.\nIt was automatically adjusted according to new sleep time settings")
    }
  }
  
  private func buttonCommandName(state: ApplicationState) -> String {
    switch state {
    case .idle, .paused, .alarm:
      return "Play"
    case .playing, .recording:
      return "Pause"
    }
  }
  
  func command() {
    switch self.appState {
    case .idle:
      self.startPlayRecordFlow()
    case .paused:
      self.resumePlayRecordFlow()
    case .playing:
      self.pausePlayFlow()
    case .recording:
      self.pauseRecordFlow()
    case .alarm:
      self.setTimeWentOffAlarm()
    }
  }
  
  private func startPlayRecordFlow() {
    
  }
  
  private func resumePlayRecordFlow() {
    
  }
  
  private func pausePlayFlow() {
    
  }
  
  private func pauseRecordFlow() {
    
  }
  
  private func setTimeWentOffAlarm() {
    self.alarmError = AlarmError.alarm("Time went off!")
  }
}

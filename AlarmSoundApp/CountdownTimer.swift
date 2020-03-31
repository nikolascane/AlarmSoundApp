//
//  CountdownTimer.swift
//  AlarmSoundApp
//
//  Created by Nik Cane on 31.03.2020.
//  Copyright © 2020 Nik Cane. All rights reserved.
//

import UIKit
import Combine

class CountdownTimer: NSObject {
  private var countdown: TimeInterval = -1 {
    didSet {
      if self.countdown == 0 {
        self.countdown = -1
        self.timeElapsed?()
      }
    }
  }
  
  private var timeElapsed: (()->())?
  
  private var timer: Timer?
  
  init(duration: TimeInterval, start: Bool, timeElapsed: @escaping ()->()) {
    self.countdown = duration
    self.timeElapsed = timeElapsed
    super.init()
    if start {
      self.resume()
    }
  }
  
  func pause() {
    self.timer?.invalidate()
    self.timer = nil
  }
  
  func resume() {
    self.timer = Timer(timeInterval: 1.0, repeats: true, block: { [weak self] _ in
      self?.countdown -= 1
    })
    if let timer = self.timer {
      RunLoop.current.add(timer, forMode: .common)
    }
  }
}

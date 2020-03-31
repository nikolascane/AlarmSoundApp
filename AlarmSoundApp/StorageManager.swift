//
//  StorageManager.swift
//  AlarmSoundApp
//
//  Created by Nik Cane on 29.03.2020.
//  Copyright © 2020 Nik Cane. All rights reserved.
//

import UIKit
import Combine

class StorageManager {
  static func store(list: [Any], as key: String) {
    DispatchQueue.global().async {
      UserDefaults.standard.set(list, forKey: key)
    }
  }
  
  static func retrieveList<T>(named: String, type: T, list: @escaping ([T])->()) {
    var subscriptions = Set<AnyCancellable>()
    Just(named)
      .subscribe(on: DispatchQueue.global())
      .map{ UserDefaults.standard.array(forKey: $0) as? [T] }
      .compactMap{ $0 }
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: { list($0) })
      .store(in: &subscriptions)
  }
}

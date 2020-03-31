//
//  NotificationManager.swift
//  AlarmSoundApp
//
//  Created by Nik Cane on 31.03.2020.
//  Copyright © 2020 Nik Cane. All rights reserved.
//

import UserNotifications

class NotificationManager: NSObject {
  static func requestNotificaiton() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
  }
  
  static func scheduleNotification(alarmDate: Date, message: String, title: String) {
    
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings(completionHandler: { [weak center] settings in
      if settings.authorizationStatus == .authorized {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.categoryIdentifier = "alarm"

        let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: alarmDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center?.add(request)
      }
    })
  }
  
  static func cancelNotificaiton() {
    let center = UNUserNotificationCenter.current()
    center.getPendingNotificationRequests { [weak center] pendingRequests in
      center?.removePendingNotificationRequests(withIdentifiers: pendingRequests.map{ $0.identifier })
    }
  }
}

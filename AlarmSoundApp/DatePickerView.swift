//
//  DatePickerView.swift
//  AlarmSoundApp
//
//  Created by Nik Cane on 30.03.2020.
//  Copyright © 2020 Nik Cane. All rights reserved.
//

import SwiftUI

struct DatePickerView: View {
  @EnvironmentObject var viewModel: AlarmViewModel
  @Binding var showAlarmTime: Bool
  
  var body: some View {
    VStack {
      Text("Select sleep time")
        .padding()
      HStack {
        Spacer()
        Button("Done") {
          self.showAlarmTime = false
        }
        .padding()
      }
      Spacer()
      DatePicker(selection: self.$viewModel.alarmTime,
                in: self.viewModel.alarmTimeRange,
                displayedComponents: .hourAndMinute,
                label: { Text("Max 1 \(self.viewModel.maxTimeRange.rawValue)") })
    }
  }
}

struct DatePickerView_Previews: PreviewProvider {
    static var previews: some View {
      DatePickerView(showAlarmTime: .constant(true))
    }
}

//
//  MinutePickerView.swift
//  AlarmSoundApp
//
//  Created by Nik Cane on 28.03.2020.
//  Copyright © 2020 Nik Cane. All rights reserved.
//

import SwiftUI
import Combine

struct MinutePickerView: View {
  @ObservedObject var viewModel: AlarmViewModel
  @Binding var showSleepTime: Bool
  @State var sleepTime: Int = 1
  
  var body: some View {
    VStack {
      Text("Select sleep time")
        .padding()
      HStack {
        Spacer()
        Button("Done") {
          self.showSleepTime = false
        }
        .padding()
      }
      Spacer()
      Picker(selection: self.$viewModel.sleepTime, label: Text("Minutes"), content: {
        ForEach(self.viewModel.minutes){
          Text("\($0.id)")
        }
      })
      Spacer()
    }
  }
}

struct MinutePickerView_Previews: PreviewProvider {
    static var previews: some View {
      MinutePickerView(viewModel: AlarmViewModel(), showSleepTime: .constant(true))
    }
}

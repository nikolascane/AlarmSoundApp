//
//  ContentView.swift
//  AlarmSoundApp
//
//  Created by Nik Cane on 27.03.2020.
//  Copyright © 2020 Nik Cane. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  
  @State private var showSleepTime: Bool = false
  @State private var showAlarmTime: Bool = false
  
  @ObservedObject var viewModel: AlarmViewModel

  var body: some View {
    VStack {
      Text("\(self.viewModel.appState.rawValue)")
      Spacer()
      Button("Set sleep time: \(self.viewModel.sleepTime) minutes"){
        self.showSleepTime = true
      }
      .sheet(isPresented: $showSleepTime, content: {
        MinutePickerView(viewModel: self.viewModel, showSleepTime: self.$showSleepTime)
      })
      Button("Set alarm time: \(self.viewModel.alarmTime)") {
        self.showAlarmTime = true
      }
      .sheet(isPresented: self.$showAlarmTime, content: {
        DatePickerView(viewModel: self.viewModel, showAlarmTime: self.$showAlarmTime)
      })
      .padding()
      Spacer()
      Button(self.viewModel.commandName){
        self.viewModel.playbackCommand()
      }
      .alert(item: self.$viewModel.alarmError, content: { error in
        Alert(title: Text(""),
              message: Text(error.description),
              dismissButton: .cancel({
                self.viewModel.stopPlayRecordFlow()
              }))
      })
      Spacer()
      HStack {
        Button(self.viewModel.abortButtonTitle){
          self.viewModel.stopPlayRecordFlow()
        }
        Spacer()
        Button(self.viewModel.muteButtonTitle){
          self.viewModel.mute()
        }
      }
      Spacer()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      ContentView(viewModel: AlarmViewModel())
    }
}

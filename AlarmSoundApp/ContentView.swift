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
  
  @EnvironmentObject var viewModel: AlarmViewModel

  var body: some View {
    VStack {
      Text("\(self.viewModel.appState.rawValue)")
      Spacer()
      Button("Set sleep time"){
        self.showSleepTime = true
      }
      .sheet(isPresented: $showSleepTime, content: {
        MinutePickerView(showSleepTime: self.$showSleepTime)
          .environmentObject(self.viewModel)
      })
      Button("Set alarm time") {
        self.showAlarmTime = true
      }
      .sheet(isPresented: self.$showAlarmTime, content: {
        DatePickerView(showAlarmTime: self.$showAlarmTime)
          .environmentObject(self.viewModel)
      })
      .padding()
      Spacer()
      Button(self.viewModel.commandName){
        self.viewModel.command()
      }
      Spacer()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

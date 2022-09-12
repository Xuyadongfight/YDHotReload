//
//  Project4.swift
//  YDHotReloadSupport
//
//  Created by 徐亚东 on 2022/6/20.
//

import SwiftUI

struct Project4: View {
    @State private var sleepAmount = 8.0
    @State private var wakeUp = Date.now
    var body: some View {
        VStack{
            Stepper("\(sleepAmount.formatted()) hours",value: $sleepAmount,in: 4...12,step: 0.25)
            DatePicker("Please enter a date",selection: $wakeUp,in:Date.now...)
                .labelsHidden()
        }.frame(width: 300, height: 300, alignment: .center)
    }
}

struct Project4_Previews: PreviewProvider {
    static var previews: some View {
        Project4()
    }
}

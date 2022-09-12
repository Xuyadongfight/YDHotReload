//
//  Project1.swift
//  YDHotReloadSupport
//
//  Created by 徐亚东 on 2022/6/15.
//

import Foundation
import SwiftUI

struct Project1 : View{
    @State private var checkAmount = 0.0
    @State private var numberOfPeople = 2
    @State private var tipPercentage = 20
    let tipPercentages = [10,15,20,25,0]
    var totalPerPerson :Double{
        let peopleCount = Double(numberOfPeople + 2)
        let tipSelection = Double(tipPercentage)
        
        let tipValue = checkAmount / 100 * tipSelection
        let grandTotal = checkAmount + tipValue
        let amountPerPerson = grandTotal / peopleCount
        return amountPerPerson
    }
    var body: some View{
        NavigationView{
            Form {
                Section {
                    TextField("Amount",value: $checkAmount,format: .currency(code: Locale.current.currencyCode ?? "USD"))
                    Picker("Number of people",selection: $numberOfPeople){
                        ForEach(2..<100){
                            Text("\($0) people")
                        }
                    }
                }
                Section {
                    Text(totalPerPerson,format: .currency(code: Locale.current.currencyCode ?? "USD"))
                }
                Section{
                    Picker("Tip percentage",selection: $tipPercentage){
                        ForEach(tipPercentages,id: \.self){
                            Text($0,format: .percent)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("How much tip do you want to leave?")
                }
                .navigationTitle("WeSplit")
            }
        }
    }
}

struct Project1Ext : View{
    var body: some View{
        Text("aaa")
    }
}

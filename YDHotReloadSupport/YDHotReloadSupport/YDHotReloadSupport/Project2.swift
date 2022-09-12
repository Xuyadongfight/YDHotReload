//
//  Project2.swift
//  YDHotReloadSupport
//
//  Created by 徐亚东 on 2022/6/15.
//

import Foundation
import SwiftUI

struct Project2 : View{
    @State private var countries = ["Estonia","France","Germany",
                     "Ireland","Italy","Nigeria"].shuffled()
    @State private var correctAnswer = Int.random(in: 0...2)
    @State private var showingScore = false
    @State private var scoreTitle = ""
    
    var body: some View{
        ZStack{
            RadialGradient(stops: [.init(color: .blue, location: 0.3),.init(color: .red, location: 0.3)], center: .top, startRadius: 200, endRadius: 400).ignoresSafeArea()
            VStack(spacing:15){
                VStack{
                    Text("Tap the flag of")
                        .foregroundColor(.white).font(.subheadline.weight(.heavy))
                    Text(countries[correctAnswer])
                        .foregroundColor(.white).font(.largeTitle.weight(.semibold))
                }
            
                ForEach(0..<3){ number in
                    Button(){
                        flagTapped(number)
                    } label: {
                        Image(countries[number])
                            .renderingMode(.original)
                            .clipShape(Capsule())
                            .shadow(radius: 5)

                    }
                }
            }
        }.alert(scoreTitle,isPresented: $showingScore){
            Button("Continue",action: askQuestion)
        } message: {
            Text("Your score is ???")
        }
    }
    func flagTapped(_ number: Int){
        if number == correctAnswer {
            scoreTitle = "Correct"
        }else{
            scoreTitle = "Wrong"
        }
        showingScore = true
    }
    func askQuestion() {
        countries = countries.shuffled()
        correctAnswer = Int.random(in: 0...2)
    }
}

struct Project2Previews: PreviewProvider {
    static var previews: some View {
        Project2()
    }
}

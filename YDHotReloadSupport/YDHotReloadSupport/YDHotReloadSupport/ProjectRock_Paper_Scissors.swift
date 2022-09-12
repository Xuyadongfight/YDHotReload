//
//  ProjectRock_Paper_Scissors.swift
//  YDHotReloadSupport
//
//  Created by 徐亚东 on 2022/6/20.
//

import SwiftUI
enum GameSelect : Int {
    case rock
    case paper
    case scissor
    
    func toStr()->String{
        let strs = ["rock","paper","scissor"]
        return strs[self.rawValue]
    }
    func drawNeed()->GameSelect{
        return self
    }
    func winNeed()->GameSelect{
        var winInt = self.rawValue + 1
        winInt = (winInt == 3 ? 0 : winInt)
        return .init(rawValue: winInt) ?? .rock
    }
    func loseNeed()->GameSelect{
        var winInt = self.rawValue - 1
        winInt = (winInt == -1 ? 2 : winInt)
        return .init(rawValue: winInt) ?? .rock
    }
}

struct ProjectRock_Paper_Scissors: View {
    var selections : [GameSelect] = [.rock,.paper,.scissor]
    
    @State var randomSel : GameSelect = .rock
    @State var randomRes : Bool = false
    @State var selected : GameSelect = .rock
    @State var haveSelected = false
    
    var result : Bool {
        var correct = GameSelect.rock
        if randomRes {
            correct = randomSel.winNeed()
        }else{
            correct = randomSel.loseNeed()
        }
        return correct == selected
    }
    
    var body: some View {
        let selectBind = Binding {
            selected
        } set: {
            haveSelected = true
            selected = $0
        }
        VStack(){
            HStack{
                Text("Target:")
                    .font(.largeTitle)
                    .bold()
                VStack{
                    Text(randomSel.toStr())
                        .font(.largeTitle)
                        .padding()
                    Text(randomRes ? "need win":"need lose")
                        .font(.title)
                        .padding()
                }
            }.frame(maxWidth: .infinity, minHeight: 300)
            
            Picker("chose",selection: selectBind){
                ForEach(selections,id: \.self){
                    Text($0.toStr()).padding()
                }
            }.pickerStyle(.segmented)
                .padding(10)
            
            haveSelected ?
            Text(result ? "Correct" : "Wrong")
                .foregroundColor(result ? .green : .red)
            :
            Text("Please chose one to complete the target!")
                .foregroundColor(.gray)
            
            Spacer()
            
            Button("Reset"){
                selected = .rock
                randomSel = selections[Int.random(in: 0...2)]
                randomRes = Int.random(in: 0...1) == 1
                haveSelected = false
            }
            
            Spacer()
        }.frame(width: 400, height: 800, alignment: .top)
        
    }
}

struct ProjectRock_Paper_Scissors_Previews: PreviewProvider {
    static var previews: some View {
        ProjectRock_Paper_Scissors()
    }
}

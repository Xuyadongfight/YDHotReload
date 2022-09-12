//
//  Project3.swift
//  YDHotReloadSupport
//
//  Created by 徐亚东 on 2022/6/16.
//

import SwiftUI

struct WaterMark : ViewModifier{
    var text : String
    func body(content:Content)->some View{
        ZStack(alignment:.bottomTrailing){
            content
            Text(text)
                .font(.caption)
                .foregroundColor(.white)
                .padding(5)
                .background(.black)
        }
    }
}

struct GridStack<Content:View> : View{
    let rows : Int
    let columns : Int
    let content : (Int,Int) -> Content
    var body: some View{
        VStack{
            ForEach(0..<rows,id: \.self){row in
                HStack{
                    ForEach(0..<columns,id: \.self){ column in
                        content(row,column)
                    }
                }
            }
        }
    }
}

extension View{
    func watermarked(with text:String)->some View{
        modifier(WaterMark(text: text))
    }
}

struct Project3: View {
    var body: some View {
        GridStack(rows: 3, columns: 3) { row, column in
            Text("R\(row)C\(column)")
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
                .background(.gray)
        }.frame(maxWidth:.infinity,maxHeight: .infinity)
            .background(.white)
            
    }
}


struct Project3_Previews: PreviewProvider {
    static var previews: some View {
        Project3()
    }
}

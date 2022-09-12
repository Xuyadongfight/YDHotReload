//
//  NewTestLabel.swift
//  YDHotReloadDemo
//
//  Created by 徐亚东 on 2022/9/5.
//
import UIKit
class NewTestLabel:UILabel{
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

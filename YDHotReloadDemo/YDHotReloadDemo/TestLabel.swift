//
//  TestLabel.swift
//  YDHotReloadDemo
//
//  Created by 徐亚东 on 2022/9/2.
//

import UIKit
class TestLabel:UILabel{
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

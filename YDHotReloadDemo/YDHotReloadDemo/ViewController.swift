//
//  ViewController.swift
//  YDHotReloadDemo
//
//  Created by 徐亚东 on 2022/2/8.
//

import UIKit
class ViewController: UIViewController {
    var name:String{
        return "abc"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        let view = UIView()
        view.frame = .init(x: 100, y: 100, width: 100, height: 100)
        view.backgroundColor = .lightGray
        self.view.addSubview(view)
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}
extension ViewController{
    func changeColor(){
        self.view.backgroundColor = .red
    }
}

class TestView:UIView{
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .red
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class NewTestView:UIView{
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .yellow
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

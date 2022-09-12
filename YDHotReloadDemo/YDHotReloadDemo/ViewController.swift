//
//  ViewController.swift
//  YDHotReloadDemo
//
//  Created by 徐亚东 on 2022/2/8.
//

import UIKit
class ViewController: UIViewController {
    var name:String{
        return "abcdef"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        /*
        let temp = TestView()
        temp.frame = .init(x: 200, y: 200, width: 110, height: 200)
        self.view.addSubview(temp)
        
        let temp1 = NewTestView()
        temp1.frame = .init(x: 200, y: 400, width: 110, height: 200)
        self.view.addSubview(temp1)
        
        let lab = TestLabel()
        lab.frame = .init(x: 0, y: 100, width: 200, height: 40)
        lab.textColor = .green
        lab.text = "aaaaaa"
        self.view.addSubview(lab)
//        self.changeColor()
        // Do any additional setup after loading the view.
        self.test1()
        print("修改成功",self,lab)
        
        let view1 = UIView()
        view1.frame = .init(x: 0, y: 0, width: 100, height: 100)
        view1.backgroundColor = .blue
        self.view.addSubview(view1)
        */
    }
    func test1(){
        let label = TestLabel()
        label.text = "测试"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .black
        label.frame = .init(x: 0, y: 0, width: 200, height: 100)
        label.center = self.view.center
        self.view.addSubview(label)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(name)
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

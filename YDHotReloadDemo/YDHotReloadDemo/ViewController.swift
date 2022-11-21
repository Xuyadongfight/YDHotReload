//
//  ViewController.swift
//  YDHotReloadDemo
//
//  Created by 徐亚东 on 2022/2/8.
//

import UIKit
class ViewController: UIViewController {
    var numberLines : Int{
        return 0
    }
    var tempWidth : CGFloat {
        return 100
    }
    var tempFont : UIFont {
        return .systemFont(ofSize: 20)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        let title = [String].init(repeating: "test", count: 10).joined(separator: "------")
        let tempSize = title.getSizeOfNumberLines(width: tempWidth, font: self.tempFont, numberline: self.numberLines)
        let label = UILabel()
        label.tag = 100
        label.backgroundColor = .lightGray
        label.font = self.tempFont
        label.text = title
        label.numberOfLines = self.numberLines
        label.frame = .init(x: 100, y: 200, width: tempSize.width, height: tempSize.height)
        self.view.addSubview(label)
//        
        let btnPresent = UIButton.init(type: .custom)
        btnPresent.setTitleColor(.red, for: .normal)
        btnPresent.setTitle("push", for: .normal)
        btnPresent.addTarget(self, action: #selector(actionOfPush), for: .touchUpInside)
        btnPresent.frame = .init(x: 0, y: 300, width: 80, height: 40)
        self.view.addSubview(btnPresent)
//        
        let btnDismiss = UIButton.init(type: .custom)
        btnDismiss.setTitleColor(.red, for: .normal)
        btnDismiss.setTitle("dismiss", for: .normal)
        btnDismiss.addTarget(self, action: #selector(actionOfDismiss), for: .touchUpInside)
        btnDismiss.frame = .init(x: 300, y: 300, width: 80, height: 40)
        self.view.addSubview(btnDismiss)
    }
    
    @objc func actionOfPush(){
        let vc = TestViewController()
        self.present(vc, animated: true)
    }
    @objc func actionOfDismiss(){
        self.dismiss(animated: true)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
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

extension String{
    func getSizeOfNumberLines(width:CGFloat,font:UIFont,numberline:Int = 0)->CGSize{
        let label = UILabel()
        label.text = self
        label.frame = .init(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude)
        label.font = font
        label.numberOfLines = numberline
        label.sizeToFit()
        let lineSize = label.bounds.size
        return lineSize
    }
}

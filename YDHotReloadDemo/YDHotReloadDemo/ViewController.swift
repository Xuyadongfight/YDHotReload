//
//  ViewController.swift
//  YDHotReloadDemo
//
//  Created by 徐亚东 on 2022/2/8.
//

import UIKit

enum ZFFilterShowType:String{
    case eList = "行样式"
    case eFlow = "瀑布流"
}
protocol ZFFilterProtocol{
    func didSetData(data:ZFFilterModel)
    func didSelect(isSelected:Bool)
}

class ZFFilterModel{
    var showValue : String
    
    var filterKey : String
    var filterValue : String
    
    var filterLayout : ZFFilterLayout?
    var filterItems : [ZFFilterModel]?
    
    //自定义筛选
    var filterCustom : [ZFFilterModel]?
    
    var isSelected : Bool
    
    init(key:String,value:String) {
        self.filterKey = key
        self.filterValue = value
        self.showValue = self.filterValue
        self.isSelected = false
    }
}

class ZFFilterLayout{
    var layoutStyle : ZFFilterShowType = .eList
    
    var layoutContainerFrame : CGRect = .zero
    var layoutItemSize : CGSize = .zero
    
    init(containerFrame:CGRect,itemSize:CGSize,style:ZFFilterShowType = .eList){
        self.layoutStyle = style
        self.layoutContainerFrame = containerFrame
        self.layoutItemSize = itemSize
    }
}



class ZFFilterLabItemView : UIView{
    
    var filterModel : ZFFilterModel?
    
    fileprivate lazy var vTitle : UILabel = {
        let temp = UILabel()
        temp.font = UIFont.systemFont(ofSize: 14)
        temp.textColor = .black
        return temp
    }()
    
    func setUp(){
        if let upModel = self.filterModel {
            self.didSetData(data: upModel)
        }
    }
    
    func didSetData(data: ZFFilterModel) {
        self.filterModel = data
        self.vTitle.text = data.showValue
        
        self.didSelect(isSelected: self.filterModel?.isSelected ?? false)
    }
    
    func didSelect(isSelected: Bool) {
        if isSelected {
            self.vTitle.textColor = .red
        }else{
            self.vTitle.textColor = .black
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.vTitle)
        self.vTitle.frame = self.bounds
        self.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(actionOfSelect)))
    }
    
    @objc func actionOfSelect(){
        self.filterModel?.isSelected = !(self.filterModel?.isSelected ?? false)
        self.didSelect(isSelected: self.filterModel?.isSelected ?? false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}





class ZFFilterBaseView : UIView{
    
    var allContainerView : UIView?
    
    var closureOfItem : ((ZFFilterBaseView,ZFFilterModel)->())?
    
    var filterModel : ZFFilterModel?

    var subItems = [ZFFilterBaseView]()
    
   
    
    
    fileprivate lazy var vTitle : UILabel = {
        let temp = UILabel()
        temp.textAlignment = .center
        temp.font = UIFont.systemFont(ofSize: 14)
        temp.textColor = .black
        return temp
    }()
    fileprivate lazy var vTapGesture : UITapGestureRecognizer = {
        let temp = UITapGestureRecognizer(target: self, action: #selector(actionOfTap))
        return temp
    }()
    fileprivate lazy var vScroll : UIScrollView = {
        let temp = UIScrollView()
        temp.backgroundColor = .lightGray
        temp.frame = self.filterModel?.filterLayout?.layoutContainerFrame ?? .zero
        return temp
    }()
    
    @objc func actionOfTap(){
        self.filterModel?.isSelected = !(self.filterModel?.isSelected ?? false)
        self.setSelected(isSelected: self.filterModel?.isSelected ?? false)
    }
    
    func setSelected(isSelected:Bool){
        if isSelected {
            self.vTitle.textColor = .red
            self.vScroll.isHidden = false
            if self.subItems.count == 0{
                self.createItems(subItemType: ZFFilterBaseView.self)
            }
        }else{
            self.vTitle.textColor = .black
            self.vScroll.isHidden = true
        }
    }
    
    func setUp(){
        self.vTitle.text = self.filterModel?.showValue
        self.setSelected(isSelected: self.filterModel?.isSelected ?? false)
        self.vScroll.frame = self.filterModel?.filterLayout?.layoutContainerFrame ?? .zero
    }
    
    func clear(){
        self.subItems.forEach{$0.removeFromSuperview()}
        self.subItems.removeAll()
    }
    
    func createItems(subItemType:ZFFilterBaseView.Type){
        let itemSize = self.filterModel?.filterLayout?.layoutItemSize ?? .zero
        
        if let itemModels = self.filterModel?.filterItems{
            var curX : CGFloat = 0
            var curY : CGFloat = 0
            for (index,itemModel) in itemModels.enumerated(){
                let item = subItemType.init(frame: .init(x: curX, y: curY, width: itemSize.width, height: itemSize.height))
                item.filterModel = itemModel
                item.tag = index
                curY += itemSize.height
                item.vTitle.text = itemModel.showValue
                item.setUp()
                
                
                self.vScroll.addSubview(item)
                self.vScroll.contentSize = .init(width: curX + itemSize.width, height: curY + itemSize.height)
                self.subItems.append(item)
                
            }
        }
    }
    
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.vTitle)
        self.addGestureRecognizer(self.vTapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.vTitle.frame = self.bounds
        self.allContainerView?.addSubview(self.vScroll)
    }
}




//MARK: -------

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
    
    func createTestData()->ZFFilterModel{
        let filterModel = ZFFilterModel(key: "区域key", value: "区域")
        filterModel.filterItems = Array(0...10).map{ item1 in
            let tempModel = ZFFilterModel(key:"区域sub_key",value:"区域_\(item1)")
//            tempModel.filterItems = Array(0...10).map{ZFFilterModel(key: "区域sub_sub_key", value: "区域_\(item1)_\($0)")}
            return tempModel
        }
        return filterModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .lightGray
        let testModel = self.createTestData()
        
        
        let filterView = ZFFilterBaseView()
        filterView.allContainerView = self.view
        filterView.backgroundColor = .lightGray
        filterView.frame = .init(x: 100, y: 100, width: 100, height: 40)
        
        testModel.filterLayout = .init(containerFrame: .init(x: 0, y: 140, width: 100, height: 300), itemSize: .init(width: 100, height: 30))
        filterView.filterModel = testModel
        self.view.addSubview(filterView)
        
        filterView.setUp()
        
//
        print(testModel)
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
        
        let btnTest = UIButton.init(type: .custom)
        btnTest.setTitleColor(.red, for: .normal)
        btnTest.setTitle("Test Click", for: .normal)
        btnTest.addTarget(self, action: #selector(testQueue), for: .touchUpInside)
        btnTest.frame = .init(x: 150, y: 400, width: 0, height: 0)
        btnTest.sizeToFit()
        self.view.addSubview(btnTest)
        
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
    
    @objc func testQueue(){
        let queue_main = DispatchQueue.main
        let queue_serial = DispatchQueue.init(label: "serial_1")
        let queue_concurrent = DispatchQueue.global(qos: .background)
        
        queue_main.sync {
            print(Thread.current,"1")
        }
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

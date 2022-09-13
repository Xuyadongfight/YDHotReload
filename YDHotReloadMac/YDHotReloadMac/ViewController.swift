//
//  ViewController.swift
//  YDHotReloadMac
//
//  Created by 徐亚东 on 2022/9/13.
//

import Cocoa

enum myError :Error{
    
}

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            if event.modifierFlags.contains([.command]){
                print("hot reload ")
//                self.hotreload()
                DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                    self.runShell("/usr/local/bin/hot")
                }
            }
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func hotreload(){
        let task = Process()
        let path = "/usr/local/bin/hot"
        
        let fileManager = FileManager.default
        let fileExist = fileManager.fileExists(atPath: path)
        let readAble = fileManager.isReadableFile(atPath: path)
        if fileExist {
            print(path,"存在")
        }
        if readAble {
            print("可读")
        }
        
        let url : URL? = .init(fileURLWithPath: path)
        
        if let upUrl = url{
            task.executableURL
        }
        do{
            try task.run()
        } catch let error{
            print(error.localizedDescription)
        }
    }
    
    func runShell(_ command: String) -> Int32 {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = [command]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }

}


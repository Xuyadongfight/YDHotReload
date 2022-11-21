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

    func runShell(_ command: String) -> Int32 {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = [command]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }

}


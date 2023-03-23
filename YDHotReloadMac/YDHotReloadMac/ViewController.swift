//
//  ViewController.swift
//  YDHotReloadMac
//
//  Created by 徐亚东 on 2022/9/13.
//

import Cocoa

/*
 public static var capsLock: NSEvent.ModifierFlags { get } // Set if Caps Lock key is pressed.

 public static var shift: NSEvent.ModifierFlags { get } // Set if Shift key is pressed.

 public static var control: NSEvent.ModifierFlags { get } // Set if Control key is pressed.

 public static var option: NSEvent.ModifierFlags { get } // Set if Option or Alternate key is pressed.

 public static var command: NSEvent.ModifierFlags { get } // Set if Command key is pressed.

 public static var numericPad: NSEvent.ModifierFlags { get } // Set if any key in the numeric keypad is pressed.

 public static var help: NSEvent.ModifierFlags { get } // Set if the Help key is pressed.

 public static var function: NSEvent.ModifierFlags { get } // Set if any function key is pressed.
*/

class ViewController: NSViewController {
    var operations = [String]()
    
    var debugStrs = [String]()
    
    let btnSize = CGSize.init(width: 100, height: 30)
    
    lazy var btnAccess : NSButton = {
        let btn = NSButton.init(title: "设置监听", target: self, action: #selector(actionOfAccess))
        return btn
    }()
    
    @objc func actionOfAccess(){
        if AXIsProcessTrusted(){
            self.addGlobal()
            self.btnAccess.title = "设置成功"
            self.btnAccess.isEnabled = false
        }else{
            self.btnAccess.isHidden = false
            NSWorkspace.shared.open(URL(string:"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.actionOfAccess()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.btnAccess)
        self.btnAccess.frame.origin = .init(x: (self.view.bounds.size.width - btnSize.width)/2, y: (self.view.bounds.size.height - btnSize.height)/2)
        self.actionOfAccess()
    }
    
    func addGlobal(){
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.debugStrs.append("keydown - \(event)")
            if let upChar = event.characters,upChar == "s"{
                self.operations.append(upChar)
                self.patternOperation()
            }
//            self.writeDebug()
        }
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            self.debugStrs.append("flagsChanged - \(event)")
            if event.modifierFlags.contains(.command){
                self.operations.append("command")
                self.patternOperation()
            }
//            self.writeDebug()
        }
    }
    func addLocal(){
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if let upChar = event.characters,upChar == "s"{
                self.operations.append(upChar)
                self.patternOperation()
            }
            return event
        }
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            if event.modifierFlags.contains(.command){
                self.operations.append("command")
                self.patternOperation()
            }
            return event
        }
    }
    
    func patternOperation(){
        guard self.operations.count <= 2 else {
            self.operations.removeAll()
            return
        }
        if let firstChar = self.operations.first,firstChar == "command"{
            if self.operations.count == 2{
                if let lastChar = self.operations.last,lastChar == "s"{
                    print("hot reload")
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                        let res = self.runShell("/usr/local/bin/hot")
                        print(res)
                    }
                    self.operations.removeAll()
                }else{
                    self.operations.removeFirst()
                }
            }
        }else{
            self.operations.removeAll()
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
    
    func writeDebug(){
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first ?? ""
        let debugStr = debugStrs.joined(separator: "\n")
        try? debugStr.write(toFile: path + "/test", atomically: true, encoding: .utf8)
    }

    
    private func pollAccessibility(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if AXIsProcessTrusted() {
                self.addGlobal()
                completion()
            } else {
                NSWorkspace.shared.open(URL(string:"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                self.pollAccessibility(completion: completion)
            }
        }
    }
    
}


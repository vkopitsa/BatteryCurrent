//
//  StatusMenuController.swift
//  BS
//
//  Created by Vladimir Kopitsa on 9/30/17.
//  Copyright © 2017 Vladimir Kopitsa. All rights reserved.
//

import Cocoa
import IOKit.ps
import IOKit

class StatusMenuController: NSObject {
    
    var interval:TimeInterval!
    var timer: Timer!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let icon_battery_charging = NSImage(named: NSImage.Name(rawValue: "icon_battery_charging"))
    let icon_battery = NSImage(named: NSImage.Name(rawValue: "icon_battery"))
    var isCharging = false
    var isBattery = false
    
    override func awakeFromNib() {
        setup()
        setupViews()
    }
    
    //MARK: SETUP
    func setup() {
        self.interval = TimeInterval(10)
        updateTimer()
    }
    
    func setupViews() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        statusItem.image = icon_battery
        
        update()
    }
    
    func updateTimer() {
        if timer != nil {
            if timer.isValid == true {
                timer.invalidate()
            }
        }
        
        timer = Timer(timeInterval: interval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
    }
    
    @objc func update() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        var isBreak = false
        
        for ps in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as Dictionary
            for (key, val) in info {
                // Power
                if ((key as! String == kIOPSPowerSourceStateKey) && (val as! String == kIOPSACPowerValue)) {
                    // fix overhead
                    if(!isCharging){
                        statusItem.image = icon_battery_charging
                    }

                    isCharging = true
                    isBattery = false
                    
                    isBreak = true
                }
                
                // Battery
                if ((key as! String == kIOPSPowerSourceStateKey) && (val as! String == kIOPSBatteryPowerValue)) {
                    // fix overhead
                    if (!isBattery){
                        statusItem.image = icon_battery
                    }

                    isBattery = true
                    isCharging = false
                    
                    isBreak = true
                }
                
                if ((key as! String == kIOPSCurrentKey)) {
                    self.statusItem.title  = "\(((val as? Double)! / 1000).roundTo(places: 2))"
                    
                    // fix overhead
                    if(isBreak){
                        break
                    }
                }
            }
        }
    }
}

extension Double {
    func roundTo(places:Int) -> Double {
        guard self != 0.0 else {
            return 0
        }
        let divisor = pow(10.0, Double(places) - ceil(log10(fabs(self))))
        return (self * divisor).rounded() / divisor
    }
}

//
//  TimerUIApplication.swift
//  DetectInactivity
//  If the app is idle, require the RA to rescan the wristband, and/or log in again.
//
//  Created by Alex DeCastro on 11/17/2019.
//

import UIKit

class TimerUIApplication: UIApplication {

    // Timeout period is set here.
    let qrTimerSeconds: TimeInterval = 30 * 60 // 30 minutes
    let loginTimerSeconds: TimeInterval = 180 * 60 // 3 hours

    static let QRTimeoutNotification = "kQRTimeoutNotification"
    static let LoginTimeoutNotification = "kLoginTimeoutNotification"

    var qrTimer: Timer?
    var loginTimer: Timer?

    // If the screen receives a touch, reset the timers.
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)

        if event.allTouches?.first(where: { $0.phase == .began }) != nil {
            resetQRTimer()
            resetLoginTimer()
        }
    }

    func invalidateTimers() {
        print("TimerUIApplication: invalidateTimers:")
        qrTimer?.invalidate()
        loginTimer?.invalidate()
    }

    func resetQRTimer() {
        print("TimerUIApplication: resetQRTimer:")
        qrTimer?.invalidate()
        qrTimer = Timer.scheduledTimer(timeInterval: qrTimerSeconds, target: self, selector: #selector(TimerUIApplication.qrTimerExceeded), userInfo: nil, repeats: false)
    }
    func resetLoginTimer() {
        print("TimerUIApplication: resetLoginTimer:")
        loginTimer?.invalidate()
        loginTimer = Timer.scheduledTimer(timeInterval: loginTimerSeconds, target: self, selector: #selector(TimerUIApplication.loginTimerExceeded), userInfo: nil, repeats: false)
    }

    @objc func qrTimerExceeded() {
        print("TimerUIApplication: qrTimerExceeded:")
        Foundation.NotificationCenter.default.post(name: NSNotification.Name(rawValue: TimerUIApplication.QRTimeoutNotification), object: nil)
    }
    @objc func loginTimerExceeded() {
        print("TimerUIApplication: loginTimerExceeded:")
        Foundation.NotificationCenter.default.post(name: NSNotification.Name(rawValue: TimerUIApplication.LoginTimeoutNotification), object: nil)
    }
}

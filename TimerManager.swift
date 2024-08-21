//
//  TimerManager.swift
//  MC2Maps
//
//  Created by Evelyn Hong on 8/21/24.
//

import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var counter: Double = 0.0
    private var lastResetDate = Calendar.current.startOfDay(for: Date())
    private var timer: Timer?
    private var timerCancellable: Cancellable?
    
    init() {
        startTimer()
    }
    
    func startTimer() {
        // 기존 타이머가 존재하면 중지
        stopTimer()
        
        // 타이머를 설정하고 주기적으로 업데이트
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCounter()
        }
        
        // Run loop에 타이머 추가
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    func stopTimer() {
        // 타이머가 존재하면 무효화하고 해제
        timer?.invalidate()
        timer = nil
    }
    
    private func updateCounter() {
        self.counter += 1
        checkForMidnight()
    }
    
    private func checkForMidnight() {
        let currentDate = Date()
        let startOfDay = Calendar.current.startOfDay(for: currentDate)
        
        if startOfDay > lastResetDate {
            self.counter = 0.0
            self.lastResetDate = startOfDay
        }
    }
    
    func timeString(from seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return "\(hours)시간 \(minutes)분 \(secs)초"
    }
}





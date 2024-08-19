//
//  Timetest.swift
//  MC2Maps
//
//  Created by Evelyn Hong on 8/19/24.
//

import SwiftUI
import Combine
import CoreLocation

class CustomLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    @Published var isLocationStable: Bool = false
    private var lastLocation: CLLocation?
    private var locationUpdateTime: Date?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        if let lastLocation = lastLocation, let locationUpdateTime = locationUpdateTime {
            let distance = newLocation.distance(from: lastLocation)
            let timeSinceLastUpdate = Date().timeIntervalSince(locationUpdateTime)
            
            // 위치가 5미터 이내로 이동했고, 10초 이상 위치가 동일하다면 위치 안정화
            if distance < 5 && timeSinceLastUpdate > 10 {
                isLocationStable = true
            } else {
                isLocationStable = false
                self.locationUpdateTime = Date()
            }
        } else {
            self.locationUpdateTime = Date()
        }
        
        lastLocation = newLocation
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
}

struct Timetest: View {
    // 타이머 값 (초 단위)
    @State private var counter: Double = 0.0
    // 자정 여부 확인을 위한 날짜 추적 변수
    @State private var lastResetDate = Calendar.current.startOfDay(for: Date())
    // 타이머 퍼블리셔
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    // 위치 매니저 인스턴스
    @StateObject private var locationManager = CustomLocationManager()

    var body: some View {
        VStack {
            // 타이머 값을 시간과 분으로 표시하는 레이블
            Text(timeString(from: counter))
                .foregroundColor(Color.green)
                .padding()
                .onReceive(timer) { _ in
                    if locationManager.isLocationStable {
                        self.counter += 1
                    }
                    checkForMidnight()
                }
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }

    // 초 단위를 "x시간 x분" 형식으로 변환하는 함수
    func timeString(from seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return "\(hours)시간 \(minutes)분"
    }

    // 자정을 체크하여 타이머를 리셋하는 함수
    func checkForMidnight() {
        let currentDate = Date()
        let startOfDay = Calendar.current.startOfDay(for: currentDate)

        // 마지막으로 자정을 확인한 날짜가 오늘이 아니면 리셋
        if startOfDay > lastResetDate {
            self.counter = 0.0
            self.lastResetDate = startOfDay
        }
    }
}

struct Timetest_Previews: PreviewProvider {
    static var previews: some View {
        Timetest()
    }
}




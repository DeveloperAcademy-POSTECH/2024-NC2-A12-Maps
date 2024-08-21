// MapsView.swift
// MC2Maps
//
// Created by donghwan on 6/14/24.
//

import SwiftUI
import MapKit
import CoreLocation

//MARK: 실제 뷰
struct MapsView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900,longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @State private var annotations: [AnnotationItem] = []
    @State private var timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect() // 20초마다 실행
    @State private var midnightTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect() // 자정 확인 타이머
    
    @StateObject private var locationManager = LocationManager() // corelocation
    @State private var baseLocation: CLLocationCoordinate2D? // baseLocation을 현재 위치로 사용
    
    @State private var specialAnnotationCounter = 0 // 스페셜 어노테이션 수
    
    @State private var selectedSpecialAnnotation: AnnotationItem? = nil // 선택된 어노테이션(선택 시 업데이트; sheet를 통해 모달 올리기)
    
    @State private var roadAddress: String? = nil
    
    @State private var lastLocation: CLLocation? // 마지막 위치
    @State private var lastLocationUpdate: Date? // 마지막 위치 업데이트 시간
    @State private var hasStayedAtLocation: Bool = false // 현재 위치에서 00초 이상 머물렀는지 여부
    @State private var cloverCounts: (threeLeaf: Int, fourLeaf: Int) = (0, 0) // 세잎, 네잎 클로버 수
    
    let maxAnnotations = 48 // 최대 어노테이션 수
    let gridSize = 6
    let cellSize = 0.0001
    let stayDuration: TimeInterval = 3 // 머물러야 하는 시간
    let distanceThreshold: CLLocationDistance = 75 // 위치 변화 임계값
    
    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true,
            annotationItems: annotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                if annotation.isSpecial {
                    Image("네잎")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .scaleEffect(selectedSpecialAnnotation == annotation ? 2.0 : 1.0)
                        .rotationEffect(Angle(degrees: selectedSpecialAnnotation == annotation ? 10 : 0))
                        .animation(.interpolatingSpring(mass: 2, stiffness: 80, damping: 10, initialVelocity: 0))
                        .onTapGesture {
                            withAnimation {
                                if selectedSpecialAnnotation == annotation {
                                    selectedSpecialAnnotation = nil
                                } else {
                                    selectedSpecialAnnotation = annotation
                                    updateCloverCounts()
                                }
                            }
                        }
                } else {
                    Image("세잎")
                        .resizable()
                        .frame(width: 25, height: 25)
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapScaleView()
            MapCompass()
            MapPitchToggle()
            //안됨;이유찾기
        }
        .mapStyle(.standard)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            if let userLocation = locationManager.location {
                region = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                baseLocation = userLocation.coordinate
            }
        }
        .onChange(of: locationManager.locationManager.authorizationStatus) { newStatus in
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                if let userLocation = locationManager.location {
                    region = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                    baseLocation = userLocation.coordinate
                }
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            if let newLocation = newLocation {
                if let lastLocation = lastLocation {
                    let distance = newLocation.distance(from: lastLocation)
                    if distance > distanceThreshold {
                        // 위치가 임계값 이상으로 변동된 경우
                        self.lastLocation = newLocation
                        self.lastLocationUpdate = Date()
                        hasStayedAtLocation = false
                        // 위치 변경 시 specialAnnotationCounter 초기화
                        specialAnnotationCounter = 0
                        // 기존 타이머 무효화 및 새로운 타이머 설정
                        timer.upstream.connect().cancel()
                        timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
                    } else {
                        // 위치가 변경되지 않은 경우
                        if let lastUpdate = lastLocationUpdate {
                            if Date().timeIntervalSince(lastUpdate) >= stayDuration {
                                hasStayedAtLocation = true
                            }
                        }
                    }
                } else {
                    // 첫 번째 위치 업데이트일 경우
                    self.lastLocation = newLocation
                    self.lastLocationUpdate = Date()
                }
            }
        }
        .onReceive(timer) { _ in
            if hasStayedAtLocation {
                addAnnotation()
                hasStayedAtLocation = false // 어노테이션 추가 후 플래그 초기화
            }
        }
        .onReceive(midnightTimer) { _ in
            checkMidnight()
        }
        //MARK: 올라오는 모달 : 네잎 클로바 선택 시
        .sheet(item: $selectedSpecialAnnotation) { annotation in
            ModalView(annotation: convertToPointAnnotation(annotation), selectedSpecialAnnotation: $selectedSpecialAnnotation, cloverCounts: $cloverCounts)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
        }
    }
    
    //MARK: 어노테이션을 추가하는 함수
    func addAnnotation() {
        guard annotations.count < maxAnnotations, let baseLocation = baseLocation else {
            return // 최대 어노테이션 수에 도달하면 추가하지 않음
        }
        
        specialAnnotationCounter += 1
        let isSpecial = (specialAnnotationCounter % 4 == 0)
        // 4로 나눈 나머지가 0일 때 isSpecial이 true, 나머지는 false
        
        let index = annotations.count
        let row = index / gridSize
        let column = index % gridSize
        
        // 그리드 셀 내에서 무작위 오프셋 계산
        let offsetLat = (Double(row) + Double.random(in: 0...1)) * 0.0001
        let offsetLon = (Double(column) + Double.random(in: 0...1)) * 0.0001
        
        // 변동 위치 계산
        let newCoordinate = calculateOffsetCoordinate(base: baseLocation, offsetLat: offsetLat, offsetLon: offsetLon)
        let newAnnotation = AnnotationItem(coordinate: newCoordinate, isSpecial: isSpecial)
        
        // 새로운 어노테이션 추가
        annotations.append(newAnnotation)
    }
    
    //MARK: 계산된 새로운 좌표 반환
    func calculateOffsetCoordinate(base: CLLocationCoordinate2D, offsetLat: Double, offsetLon: Double) -> CLLocationCoordinate2D {
        let newLatitude = base.latitude + offsetLat
        let newLongitude = base.longitude + offsetLon
        return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
    }
    
    //MARK: 자정을 확인하는 함수
    func checkMidnight() {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: now)
        if components.hour == 0 && components.minute == 0 {
            // 자정이면 어노테이션 초기화
            annotations.removeAll()
            // 자정을 넘으면 즉시 첫 어노테이션 추가
            addAnnotation()
            cloverCounts = (0, 0) // 자정에 클로버 수 초기화
        }
    }
    
    //MARK: 클로버 수를 업데이트하는 함수
    func updateCloverCounts() {
        cloverCounts.threeLeaf = annotations.filter { !$0.isSpecial }.count
        cloverCounts.fourLeaf = annotations.filter { $0.isSpecial }.count
    }
    // MKPointAnnotation으로 변환하는 함수
            func convertToPointAnnotation(_ annotationItem: AnnotationItem) -> MKPointAnnotation {
                let annotation = MKPointAnnotation()
                annotation.coordinate = annotationItem.coordinate
                return annotation
            }
}


// MARK: preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MapsView()
    }
}

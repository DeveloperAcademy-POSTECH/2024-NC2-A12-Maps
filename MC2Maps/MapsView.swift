//
//  ContentView.swift
//  MC2Maps
//
//  Created by donghwan on 6/14/24.
//

import SwiftUI
import MapKit
import CoreLocation

//MARK: 커스텀 어노테이션 구조체 생성
struct AnnotationItem: Identifiable, Equatable{
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var isSpecial: Bool
    static func == (lhs: AnnotationItem, rhs: AnnotationItem) -> Bool {
        return lhs.id == rhs.id // 여기서는 ID가 같으면 같은 어노테이션으로 간주
    }
}
// MARK: - 위치 기반 클로버 수 저장 구조체
struct LocationCloverCounts {
    let location: CLLocation
    var cloverCounts: (threeLeaf: Int, fourLeaf: Int)
}
//MARK: 실제 뷰
struct MapsView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900,longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @State private var annotations: [AnnotationItem] = []
    @State private var timer = Timer.publish(every: 20
                                             , on: .main, in: .common).autoconnect() // 5초마다 실행
    @State private var midnightTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect() // 자정 확인 타이머
    
    @StateObject private var locationManager = LocationManager()// corelocation
    //    @State private var isRegionSet = false // 초기 위치 설정 여부
    @State private var baseLocation : CLLocationCoordinate2D? // baseLocation을 현재위치로 사용
    
    @State private var specialAnnotationCounter = 0//스페셜한 어노테이션 수
    @State private var selectedSpecialAnnotation: AnnotationItem? = nil // 선택된 어노테이션(선택시 업데이트;sheet를 통해 모달 올리기)
    
    @State private var roadAddress: String? = nil
    
    @State private var lastLocation: CLLocation? // 마지막 위치
    @State private var lastLocationUpdate: Date? // 마지막 위치 업데이트 시간
    @State private var hasStayedAtLocation: Bool = false // 현재 위치에서 00초 이상 머물렀는지 여부
    @State private var locationCloverCounts: [LocationCloverCounts] = []
    
    
    let geoServiceManager = GeoServiceManager()
    let maxAnnotations = 48 // 최대 어노테이션 수
    let gridSize = 6
    let cellSize = 0.0001
    let stayDuration: TimeInterval = 30 // 머물러야 하는 시간
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
                            withAnimation() {
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
            .mapControls{
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
                if let userLocation = newLocation {
                    baseLocation = userLocation.coordinate
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
                            // 위치 변경시 specialAnnotationCounter 초기화
                            specialAnnotationCounter = 0
                            // 기존 타이머 무효화 및 새로운 타이머 설정
                            timer.upstream.connect().cancel()
                            timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()
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
                    // 클로버 수 업데이트
                    updateCloverCounts()
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
        //MARK: 올라오는 모달 : 네잎클로바 선택시
            .sheet(item: $selectedSpecialAnnotation) { annotation in
                VStack {
                    HStack{
                        Text("네잎클로버")
                            .font(.title)
                        Image("네잎")
                            .resizable()
                            .frame(width: 30,height: 30)
                    }
                    Text("북: \(annotation.coordinate.latitude)")
                    Text("동: \(annotation.coordinate.longitude)")
                    // 도로명 주소 표시
                    if let roadAddress = roadAddress {
                        Text("주소: \(roadAddress)")
                    } else {
                        Text("주소를 불러오는 중...")
                            .onAppear {
                                let location = CLLocation(latitude: annotation.coordinate.latitude,
                                                          longitude: annotation.coordinate.longitude)
                                geoServiceManager.getRoadAddress(for: location) { address in
                                    self.roadAddress = address
                                }
                            }
                    }
                    Text("오늘은 이곳에서 00만큼 머물렀습니다")
                    // 클로버 수 표시
                    if let locationData = locationCloverCounts.first(where: { isWithinRadius(from: CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude), to: $0.location, radius: distanceThreshold) }) {
                                        Text("세잎 클로버: \(locationData.cloverCounts.threeLeaf)개")
                                        Text("네잎 클로버: \(locationData.cloverCounts.fourLeaf)개")
                                    } else {
                                        Text("클로버 수를 가져오는 중...")
                                    }
                    Button("Close") {
                        selectedSpecialAnnotation = nil
                    }
                    Spacer()
                    
                        .presentationDetents([.fraction(0.1), .medium, .large])
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)
                        .interactiveDismissDisabled()
                }
            }
    }
    
    //MARK: 어노테이션을 추가하는 함수
    func addAnnotation() {
        guard annotations.count < maxAnnotations, let baseLocation = baseLocation else {
            return // 최대 어노테이션 수에 도달하면 추가하지 않음
        }
        
        specialAnnotationCounter += 1
        let isSpecial = (specialAnnotationCounter % 4 == 0)
        //4로 나눈 나머지가 0일때 isSpecial이 true, 나머지는 false
        
        let index = annotations.count
        let row = index / gridSize
        let column = index % gridSize
        
        // 그리드 셀 내에서 무작위 오프셋 계산
        let offsetLat = (Double(row) + Double.random(in: 0...1)) * 0.0001
        let offsetLon = (Double(column) + Double.random(in: 0...1)) * 0.0001
        
        //변동 위치 계산
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
            locationCloverCounts.removeAll()
        }
    }
    //MARK: 클로버 수를 업데이트하는 함수
    func updateCloverCounts() {
            guard let currentLocation = locationManager.location else { return }
            
            let radius = distanceThreshold
            
            // 현재 위치를 기준으로 반경 내 클로버 수 계산
            let newCloverCounts = (
                threeLeaf: annotations.filter {
                    !$0.isSpecial && isWithinRadius(from: currentLocation, to: CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude), radius: radius)
                }.count,
                fourLeaf: annotations.filter {$0.isSpecial && isWithinRadius(from: currentLocation, to: CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude), radius: radius)
                }.count
                )// 현재 위치에 대한 클로버 수 업데이트 또는 새로 추가
        if let index = locationCloverCounts.firstIndex(where: { isWithinRadius(from: currentLocation, to: $0.location, radius: radius) }) {
            locationCloverCounts[index].cloverCounts = newCloverCounts
        } else {
            locationCloverCounts.append(LocationCloverCounts(location: currentLocation, cloverCounts: newCloverCounts))
        }
    }
    // MARK: - 거리 계산 함수
    func isWithinRadius(from: CLLocation, to: CLLocation, radius: CLLocationDistance) -> Bool {
        return from.distance(from: to) <= radius
    }
                    
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.locationManager.allowsBackgroundLocationUpdates = true //백그라운드에서 동작
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
    
    
}
//MARK: preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MapsView()
    }
}

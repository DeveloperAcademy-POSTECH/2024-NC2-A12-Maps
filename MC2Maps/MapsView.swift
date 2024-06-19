//
//  ContentView.swift
//  MC2Maps
//
//  Created by donghwan on 6/14/24.
//

import SwiftUI
import MapKit
import CoreLocation

// 커스텀 어노테이션 구조체 생성
struct AnnotationItem: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var isSpecial: Bool
}

struct MapsView: View {
    @State private var region = MKCoordinateRegion(
        /*center: CLLocationCoordinate2D(latitude: 36.01385, longitude: 129.32547)*/
        center: CLLocationCoordinate2D(latitude: 37.334_900,longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    @State private var annotations: [AnnotationItem] = []
    @State private var timer = Timer.publish(every: 3
                                             , on: .main, in: .common).autoconnect() // 5초마다 실행
    @State private var midnightTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect() // 자정 확인 타이머

    @StateObject private var locationManager = LocationManager()// corelocation
    //    @State private var isRegionSet = false // 초기 위치 설정 여부
    @State private var baseLocation : CLLocationCoordinate2D? // baseLocation을 현재위치로 사용

    @State private var specialAnnotationCounter = 0//스페셜한 어노테이션 수
    @State private var selectedSpecialAnnotation: AnnotationItem? // 선택된 어노테이션(선택시 업데이트;sheet를 통해 모달 올리기)

    let maxAnnotations = 48 // 최대 어노테이션 수
    let gridSize = 6
    let cellSize = 0.0001

    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true,
            annotationItems: annotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                if annotation.isSpecial {
                    Image("네잎")
                        .resizable()
                        .frame(width: 25, height: 25)
                    //                        . scaleEffect(selectedSpecialAnnotation == annotation ? 1.2 : 1.0) // 클릭된 핀이면 크기를 키우는 애니메이션
                    //                        .animation(.spring()) // 스프링 애니메이션 적용
                        .animation(.interactiveSpring())
                        .onTapGesture {
                            withAnimation{
                                selectedSpecialAnnotation = annotation
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
            .onReceive(timer) { _ in
                addAnnotation()
            }
            .onReceive(midnightTimer) { _ in
                checkMidnight()
            }
        // 올라오는 모달 : 네잎클로바 선택시
            .sheet(item: $selectedSpecialAnnotation) { annotation in
                VStack {
                    HStack{
                        Text("네잎")
                            .font(.title)
                        Image("네잎")
                            .resizable()
                            .frame(width: 30,height: 30)
                    }
                    Text("Latitude: \(annotation.coordinate.latitude)")
                    Text("Longitude: \(annotation.coordinate.longitude)")
                    Text("오늘은 이곳에서 00만큼 머물렀습니다")
                    Button("Close") {
                        selectedSpecialAnnotation = nil
                    }
                }
            }
    }

    // 어노테이션을 추가하는 함수
    func addAnnotation() {
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
        //6초 뒤에 실행
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
    // 계산된 새로운 좌표 반환
    func calculateOffsetCoordinate(base: CLLocationCoordinate2D, offsetLat: Double, offsetLon: Double) -> CLLocationCoordinate2D {
        let newLatitude = base.latitude + offsetLat
        let newLongitude = base.longitude + offsetLon
        return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
    }

    // 자정을 확인하는 함수
    func checkMidnight() {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: now)
        if components.hour == 0 && components.minute == 0 {
            // 자정이면 어노테이션 초기화
            annotations.removeAll()
            // 자정을 넘으면 즉시 첫 어노테이션 추가
            addAnnotation()
        }
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

#Preview {
    MapsView()
}

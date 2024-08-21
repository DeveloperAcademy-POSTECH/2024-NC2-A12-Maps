import SwiftUI
import MapKit
import CoreLocation

struct MapsView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @State private var annotations: [AnnotationItem] = []
    @State private var timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    @State private var midnightTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    @StateObject private var locationManager = LocationManager()
    @State private var baseLocation: CLLocationCoordinate2D?
    
    @State private var specialAnnotationCounter = 0
    @State private var selectedSpecialAnnotation: AnnotationItem? = nil
    
    @State private var roadAddress: String? = nil
    @State private var lastLocation: CLLocation?
    @State private var lastLocationUpdate: Date?
    @State private var hasStayedAtLocation: Bool = false
    @State private var cloverCounts: (threeLeaf: Int, fourLeaf: Int) = (0, 0)
    
    @State private var totalElapsedTime: TimeInterval = 0 // 총 경과 시간
    @State private var cloverCreationTime: Date? = nil // 첫 클로버가 생성된 시간
    @State private var elapsedTimeTimer: Timer? // 실시간 경과 시간 업데이트 타이머
    
    let maxAnnotations = 48
    let gridSize = 6
    let cellSize = 0.0001
    let stayDuration: TimeInterval = 3
    let distanceThreshold: CLLocationDistance = 75
    
    var body: some View {
        VStack {
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
                            self.lastLocation = newLocation
                            self.lastLocationUpdate = Date()
                            hasStayedAtLocation = false
                            specialAnnotationCounter = 0
                            timer.upstream.connect().cancel()
                            timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
                        } else {
                            if let lastUpdate = lastLocationUpdate {
                                if Date().timeIntervalSince(lastUpdate) >= stayDuration {
                                    hasStayedAtLocation = true
                                }
                            }
                        }
                    } else {
                        self.lastLocation = newLocation
                        self.lastLocationUpdate = Date()
                    }
                }
            }
            .onReceive(timer) { _ in
                if hasStayedAtLocation {
                    addAnnotation()
                    hasStayedAtLocation = false
                }
            }
            .onReceive(midnightTimer) { _ in
                checkMidnight()
            }
            
        }
        .sheet(item: $selectedSpecialAnnotation) { annotation in
            ModalView(annotation: convertToPointAnnotation(annotation), selectedSpecialAnnotation: $selectedSpecialAnnotation, cloverCounts: $cloverCounts, elapsedTime: totalElapsedTime)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
        }
    }
    
    func addAnnotation() {
        guard annotations.count < maxAnnotations, let baseLocation = baseLocation else {
            return
        }
        
        specialAnnotationCounter += 1
        let isSpecial = (specialAnnotationCounter % 4 == 0)
        
        let index = annotations.count
        let row = index / gridSize
        let column = index % gridSize
        
        let offsetLat = (Double(row) + Double.random(in: 0...1)) * 0.0001
        let offsetLon = (Double(column) + Double.random(in: 0...1)) * 0.0001
        
        let newCoordinate = calculateOffsetCoordinate(base: baseLocation, offsetLat: offsetLat, offsetLon: offsetLon)
        let newAnnotation = AnnotationItem(coordinate: newCoordinate, isSpecial: isSpecial)
        
        annotations.append(newAnnotation)
        
        // 첫 클로버 생성 시 경과 시간 계산을 시작
        if cloverCreationTime == nil {
            cloverCreationTime = Date()
            startElapsedTimeTimer() // 경과 시간을 실시간으로 업데이트하는 타이머 시작
        }
    }
    
    func startElapsedTimeTimer() {
        elapsedTimeTimer?.invalidate() // 기존 타이머가 있다면 무효화
        elapsedTimeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let creationTime = cloverCreationTime {
                totalElapsedTime = Date().timeIntervalSince(creationTime)
            }
        }
    }
    
    func calculateOffsetCoordinate(base: CLLocationCoordinate2D, offsetLat: Double, offsetLon: Double) -> CLLocationCoordinate2D {
        let newLatitude = base.latitude + offsetLat
        let newLongitude = base.longitude + offsetLon
        return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
    }
    
    func checkMidnight() {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: now)
        if components.hour == 0 && components.minute == 0 {
            annotations.removeAll()
            addAnnotation()
            cloverCounts = (0, 0)
            elapsedTimeTimer?.invalidate() // 자정에 타이머를 멈춤
            cloverCreationTime = nil
        }
    }
    
    func updateCloverCounts() {
        cloverCounts.threeLeaf = annotations.filter { !$0.isSpecial }.count
        cloverCounts.fourLeaf = annotations.filter { $0.isSpecial }.count
    }
    
    // 시간을 포맷팅하는 함수
    func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func convertToPointAnnotation(_ annotationItem: AnnotationItem) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = annotationItem.coordinate
        return annotation
    }
}

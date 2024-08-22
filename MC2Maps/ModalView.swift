import SwiftUI
import MapKit
import CoreLocation

struct ModalView: View {
    let annotation: MKPointAnnotation
    @Binding var selectedSpecialAnnotation: AnnotationItem?
    @State private var roadAddress: String? = nil
    @State private var placeName: String? = nil
    @State private var placeCategory: String? = nil
    @Binding var cloverCounts: (threeLeaf: Int, fourLeaf: Int)
    
    let elapsedTime: TimeInterval // 실시간으로 업데이트되는 경과 시간
    
    init(annotation: MKPointAnnotation, selectedSpecialAnnotation: Binding<AnnotationItem?>, cloverCounts: Binding<(threeLeaf: Int, fourLeaf: Int)>, elapsedTime: TimeInterval) {
        self.annotation = annotation
        self._selectedSpecialAnnotation = selectedSpecialAnnotation
        self._cloverCounts = cloverCounts
        self.elapsedTime = elapsedTime
        
        self.items = [
            ("좌표", "북 \(annotation.coordinate.latitude)°, 동 \(annotation.coordinate.longitude)°")
        ]
    }
    
    let items: [(String, String)]
    private let geoServiceManager = GeoServiceManager()
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    selectedSpecialAnnotation = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(.systemGray4))
                }
            }
            .padding(.trailing, 18)
            .padding(.top, 16)
            
            HStack {
                VStack(alignment: .leading) {
                    if let placeName = placeName {
                        Text("\(placeName)")
                            .font(.title)
                            .fontWeight(.bold)
                    } else {
                        Text("정보를 불러오는 중...")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    if let placeCategory = placeCategory {
                        Text("\(placeCategory)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.leading, 18)
                .onAppear {
                    let location = CLLocation(latitude: annotation.coordinate.latitude,
                                              longitude: annotation.coordinate.longitude)
                    fetchPlaceName(for: location)
                }
                Spacer()
            }
            
            HStack {
                HStack {
                    Spacer()
                    VStack {
                        Image("네잎원")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("\(cloverCounts.fourLeaf)개")
                    }
                    Spacer()
                }
                .padding()
                .background(.white)
                .cornerRadius(10)
                
                HStack {
                    Spacer()
                    VStack {
                        Image("세잎원")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("\(cloverCounts.threeLeaf)개")
                    }
                    Spacer()
                }
                .padding()
                .background(.white)
                .cornerRadius(10)
            }
            .padding(.leading, 18)
            .padding(.trailing, 18)
            
            List {
                Section(header: Text("세부사항")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.black)
                    .padding(.leading, -10)
                ) {
                    VStack(alignment: .leading) {
                        Text("머문시간")
                            .font(.system(size: 17))
                            .foregroundColor(Color(UIColor.systemGray2))
                        
                        // 실시간 경과 시간 표시
                        Text(timeString(from: elapsedTime))
                            .foregroundColor(Color.green)
                    }
                }
                .textCase(nil)
                
                Section {
                    VStack(alignment: .leading) {
                        if let roadAddress = roadAddress {
                            Text("주소")
                                .font(.system(size: 17))
                                .foregroundColor(Color(UIColor.systemGray2))
                            Text(roadAddress)
                        } else {
                            Text("주소")
                                .font(.system(size: 17))
                                .foregroundColor(Color(UIColor.systemGray2))
                            Text("주소를 불러오는 중...")
                                .onAppear {
                                    let location = CLLocation(latitude: annotation.coordinate.latitude,
                                                              longitude: annotation.coordinate.longitude)
                                    geoServiceManager.getRoadAddress(for: location) { address in
                                        self.roadAddress = address
                                    }
                                }
                        }
                    }
                    
                    ForEach(items, id: \.0) { item in
                        VStack(alignment: .leading) {
                            Text(item.0)
                                .font(.system(size: 17))
                                .foregroundColor(Color(UIColor.systemGray2))
                            Text(item.1)
                        }
                    }
                }
            }
            .scrollDisabled(true)
            .listSectionSpacing(22)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    func fetchPlaceName(for location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("장소 정보를 불러오는 데 실패했습니다: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                self.placeName = placemark.name ?? "알 수 없는 장소"
                
                if let areasOfInterest = placemark.areasOfInterest, !areasOfInterest.isEmpty {
                    self.placeCategory = areasOfInterest.first
                } else if let subLocality = placemark.subLocality {
                    self.placeCategory = subLocality
                } else {
                    self.placeCategory = "알 수 없는 장소 유형"
                }
            }
        }
    }
    
    // 경과 시간을 문자열로 변환하는 함수
    func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        return String(format: "%02d시간 %02d분 %02d초", hours, minutes, seconds)
    }
}

import SwiftUI
import MapKit
import CoreLocation

//MARK: 모달 뷰
struct ModalView: View {
    @StateObject private var timerManager = TimerManager()
    
    let annotation: MKPointAnnotation // MKPointAnnotation 대신 AnnotationItem 사용
    
    @Binding var selectedSpecialAnnotation: AnnotationItem? // 바인딩 추가
    
    @State private var roadAddress: String? = nil
    @State private var stayDuration: String = "0시간 0분 0초"
    @State private var placeName: String? = nil
    @State private var placeCategory: String? = nil
    @Binding var cloverCounts: (threeLeaf: Int, fourLeaf: Int) // @Binding 추가
    
    init(annotation: MKPointAnnotation, selectedSpecialAnnotation: Binding<AnnotationItem?>, cloverCounts: Binding<(threeLeaf: Int, fourLeaf: Int)>) {
        self.annotation = annotation
        self._selectedSpecialAnnotation = selectedSpecialAnnotation
        self._cloverCounts = cloverCounts
        
        self.items = [
            ("좌표", "북 \(annotation.coordinate.latitude)°, 동 \(annotation.coordinate.longitude)°")
        ]
    }
    
    let items: [(String, String)]
    private let geoServiceManager = GeoServiceManager()
    
    func cell(text: String) -> some View {
        HStack {
            Text(text)
                .fontWeight(.semibold)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    selectedSpecialAnnotation = nil // 모달 닫기
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
                    fetchPlaceName(for: location) // 함수를 여기서 호출
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
                        Text("\(cloverCounts.fourLeaf)개") // 클로버 수 표시
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
                        Text("\(cloverCounts.threeLeaf)개") // 클로버 수 표시
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
                        Text(timerManager.timeString(from: timerManager.counter))
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
            .onAppear {
                loadStayDuration()
            }
            .onDisappear {
                // 장소가 변경되거나 뷰가 사라질 때 타이머를 중지합니다.
                timerManager.stopTimer()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    func loadStayDuration() {
        let fileManager = FileManager.default
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent("stayDuration.txt")
            
            do {
                let durationText = try String(contentsOf: fileURL, encoding: .utf8)
                stayDuration = durationText.trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                print("파일을 읽는 데 오류가 발생했습니다: \(error)")
            }
        }
    }
    
    //    func fetchPlaceName(for location: CLLocation) {
    //        let geocoder = CLGeocoder()
    //        geocoder.reverseGeocodeLocation(location) { placemarks, error in
    //            if let error = error {
    //                print("정보를 불러오는 데 실패했습니다: \(error.localizedDescription)")
    //                return
    //            }
    //
    //            if let placemark = placemarks?.first {
    //                if let name = placemark.name {
    //                    self.placeName = name
    //                } else {
    //                    let thoroughfare = placemark.thoroughfare ?? ""
    //                    let subThoroughfare = placemark.subThoroughfare ?? ""
    //                    let locality = placemark.locality ?? ""
    //                    let administrativeArea = placemark.administrativeArea ?? ""
    //                    let postalCode = placemark.postalCode ?? ""
    //
    //                    self.placeName = "\(administrativeArea) \(locality) \(thoroughfare) \(subThoroughfare) \(postalCode)".trimmingCharacters(in: .whitespaces)
    //                }
    //
    //                if let areasOfInterest = placemark.areasOfInterest, !areasOfInterest.isEmpty {
    //                    self.placeCategory = areasOfInterest.first
    //                } else if let subLocality = placemark.subLocality {
    //                    self.placeCategory = subLocality
    //                } else {
    //                    self.placeCategory = "기타"
    //                }
    //            }
    //        }
    //    }
    func fetchPlaceName(for location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("장소 정보를 불러오는 데 실패했습니다: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                // 장소 이름 설정
                self.placeName = placemark.name ?? "알 수 없는 장소"
                
                // 장소 카테고리 설정 (areasOfInterest를 사용하거나 다른 속성 활용)
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
}

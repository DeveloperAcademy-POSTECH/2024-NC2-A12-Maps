//
//  ModalView.swift
//  MC2Maps
//
//  Created by Evelyn Hong on 8/18/24.
//

import SwiftUI
import MapKit
import CoreLocation

struct ModalView: View {
    let annotation: MKPointAnnotation
    @State private var roadAddress: String? = nil // 주소를 저장
    @State private var cloverCounts: (threeLeaf: Int, fourLeaf: Int) = (0, 0) //클로버 갯수
    @State private var annotations: [AnnotationItem] = []
    @State private var stayDuration: String = "0시간 0분"
    @State private var placeName: String? = nil // 장소 이름을 저장
    @State private var placeCategory: String? = nil // 장소 카테고리(학교, 카페 등)를 저장
    
    let items: [(String, String)]
    
    
    // GeoServiceManager 인스턴스 추가
    private let geoServiceManager = GeoServiceManager()
    
    init(annotation: MKPointAnnotation) {
            self.annotation = annotation
            self.items = [
                ("좌표", "북 \(annotation.coordinate.latitude)°, 동 \(annotation.coordinate.longitude)°")
            ]
        }
    
    func cell(text: String) -> some View {
        HStack {
            Text(text)
                .fontWeight(.semibold)
        }
    }
    
    var body: some View {
            VStack{
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
                    .padding()
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
                                .frame(width: 20,height: 20)
                            cell(text: "\(cloverCounts.fourLeaf)개")
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
                                .frame(width: 20,height: 20)
                            cell(text: "\(cloverCounts.threeLeaf)개")
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
                    // 첫 번째 섹션 - '머무른 시간'
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
                                           Text(stayDuration)
                                               .foregroundColor(Color.green)
                                       }
                                   }
                                   .textCase(nil)
                    
                    // 두 번째 섹션 - '주소 및 좌표'
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
                            
                        }
                        .background(Color(UIColor.systemGroupedBackground))
                    }

    // 파일에서 머문시간 데이터를 불러오는 함수
     func loadStayDuration() {
         // 파일 경로 지정
         let fileManager = FileManager.default
         if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
             let fileURL = documentDirectory.appendingPathComponent("stayDuration.txt")
             
             do {
                 // 파일에서 문자열 읽기
                 let durationText = try String(contentsOf: fileURL, encoding: .utf8)
                 stayDuration = durationText.trimmingCharacters(in: .whitespacesAndNewlines)
             } catch {
                 print("파일을 읽는 데 오류가 발생했습니다: \(error)")
             }
         }
     }
     
     func updateCloverCounts() {
         cloverCounts.threeLeaf = annotations.filter { !$0.isSpecial }.count
         cloverCounts.fourLeaf = annotations.filter { $0.isSpecial }.count
     }
    
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

 struct ModalView_Previews: PreviewProvider {
     static var previews: some View {
         let exampleAnnotation = MKPointAnnotation()
         exampleAnnotation.coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
         
         return ModalView(annotation: exampleAnnotation)
     }
 }
//#Preview {
//    ModalView(annotation: MKPointAnnotation(), stayDuration: String())
//}


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
    @State private var roadAddress: String? = nil // 주소를 저장할 @State 변수
    
    let stayDuration: [(String, String)]
    let items: [(String, String)]
    
    // GeoServiceManager 인스턴스 추가
    private let geoServiceManager = GeoServiceManager()
    
    init(annotation: MKPointAnnotation, stayDuration: String) {
        self.annotation = annotation
        self.stayDuration = [("머문시간", stayDuration)]
        self.items = [
            ("좌표", "북 \(annotation.coordinate.latitude)°, 동 \(annotation.coordinate.longitude)°")
        ]
    }
    
    var body: some View {
        List {
            // 첫 번째 섹션 - '머무른 시간'
            Section(header: Text("세부사항")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.black)
                .padding(.vertical, 10)
                .padding(.leading, -10)
            ) {
                ForEach(stayDuration, id: \.0) { item in
                    VStack(alignment: .leading) {
                        Text(item.0)
                            .font(.system(size: 17))
                            .foregroundColor(Color(UIColor.systemGray2))
                        Text(item.1)
                            .foregroundColor(Color.green)
                    }
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

    }
}

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleAnnotation = MKPointAnnotation()
        exampleAnnotation.coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        return ModalView(annotation: exampleAnnotation, stayDuration: "2시간 30분")
    }
}



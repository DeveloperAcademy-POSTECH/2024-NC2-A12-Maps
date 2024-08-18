//
//  Maplocation.swift
//  MC2Maps
//
//  Created by Evelyn Hong on 8/15/24.
//

import SwiftUI
import CoreLocation

final class GeoServiceManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager!
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    // 좌표 -> 도로명 주소
    func getRoadAddress(for location: CLLocation, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let locale = Locale(identifier: "Ko-kr")
        geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { placeMarks, error in
            guard let placeMarks = placeMarks,
                  let address = placeMarks.last,
                  error == nil else {
                completion(nil) // 오류 발생 시 nil 반환
                return
            }
            let country = address.country ?? ""
            let administrativeArea = address.administrativeArea ?? ""
            let locality = address.locality ?? ""
            let subLocality = address.subLocality ?? ""
            let subThoroughfare = address.subThoroughfare ?? ""
            let fullAddress = "\(country)\n\(administrativeArea)\n\(locality)\n\(subLocality)\n\(subThoroughfare)"
            
            
            DispatchQueue.main.async {
                completion(fullAddress) // 주소 문자열을 반환
            }
        }
    }
}

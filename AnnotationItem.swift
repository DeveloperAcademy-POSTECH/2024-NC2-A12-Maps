//
//  AnnotationItem.swift
//  MC2Maps
//
//  Created by Evelyn Hong on 8/20/24.
//

// AnnotationItem.swift
import Foundation
import CoreLocation
import MapKit

struct AnnotationItem: Identifiable, Equatable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var isSpecial: Bool
    
    static func == (lhs: AnnotationItem, rhs: AnnotationItem) -> Bool {
        return lhs.id == rhs.id
    }
}

extension AnnotationItem {
    func toMKPointAnnotation() -> MKPointAnnotation {
        let mkAnnotation = MKPointAnnotation()
        mkAnnotation.coordinate = self.coordinate
        return mkAnnotation
    }
}

//
//  AnnotationModels.swift
//  MC2Maps
//
//  Created by Evelyn Hong on 8/21/24.
//

import Foundation
import CoreLocation

// MARK: - AnnotationItem

struct AnnotationItem: Identifiable, Equatable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var isSpecial: Bool
    
    static func == (lhs: AnnotationItem, rhs: AnnotationItem) -> Bool {
        return lhs.id == rhs.id // ID가 같으면 같은 어노테이션으로 간주
    }
}

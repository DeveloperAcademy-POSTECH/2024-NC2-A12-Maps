//
//  CloverManager.swift
//  MC2Maps
//
//  Created by Evelyn Hong on 8/21/24.
//

import Foundation
import CoreLocation

class CloverManager: ObservableObject {
    @Published var isCloverConditionMet: Bool = false
    
    func checkCloverGenerationCondition(location: CLLocation) {
        // 조건 확인 후, 조건이 충족되면 isCloverConditionMet를 true로 설정
        self.isCloverConditionMet = true // 예시로 조건을 충족시킴
    }
}

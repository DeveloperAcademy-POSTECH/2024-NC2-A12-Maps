//
//  AnnotationHelpers.swift
//  MC2Maps
//
//  Created by Evelyn Hong on 8/21/24.
//

import Foundation
import CoreLocation

// MARK: - Annotation Management

extension MapsView {
    // MARK: 어노테이션을 추가하는 함수
    func addAnnotation() {
        guard annotations.count < maxAnnotations, let baseLocation = baseLocation else {
            return // 최대 어노테이션 수에 도달하면 추가하지 않음
        }
        
        specialAnnotationCounter += 1
        let isSpecial = (specialAnnotationCounter % 4 == 0)
        // 4로 나눈 나머지가 0일 때 isSpecial이 true, 나머지는 false
        
        let index = annotations.count
        let row = index / gridSize
        let column = index % gridSize
        
        // 그리드 셀 내에서 무작위 오프셋 계산
        let offsetLat = (Double(row) + Double.random(in: 0...1)) * 0.0001
        let offsetLon = (Double(column) + Double.random(in: 0...1)) * 0.0001
        
        // 변동 위치 계산
        let newCoordinate = calculateOffsetCoordinate(base: baseLocation, offsetLat: offsetLat, offsetLon: offsetLon)
        let newAnnotation = AnnotationItem(coordinate: newCoordinate, isSpecial: isSpecial)
        
        // 새로운 어노테이션 추가
        annotations.append(newAnnotation)
    }
    
    // MARK: 계산된 새로운 좌표 반환
    func calculateOffsetCoordinate(base: CLLocationCoordinate2D, offsetLat: Double, offsetLon: Double) -> CLLocationCoordinate2D {
        let newLatitude = base.latitude + offsetLat
        let newLongitude = base.longitude + offsetLon
        return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
    }
    
    // MARK: 클로버 수를 업데이트하는 함수
    func updateCloverCounts() {
        cloverCounts.threeLeaf = annotations.filter { !$0.isSpecial }.count
        cloverCounts.fourLeaf = annotations.filter { $0.isSpecial }.count
    }
}

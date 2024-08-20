//
//  MapsViewModel.swift
//  MC2Maps
//
//  Created by Evelyn Hong on 8/20/24.
//

import SwiftUI
import MapKit
import CoreLocation

class MapsViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @Published var annotations: [AnnotationItem] = []
    @Published var baseLocation: CLLocationCoordinate2D?
    @Published var selectedSpecialAnnotation: AnnotationItem?
    @Published var hasStayedAtLocation: Bool = false // <-- 수정됨
    
    @State private var specialAnnotationCounter = 0
    @State private var lastLocation: CLLocation?
    @State private var lastLocationUpdate: Date?
    
    let maxAnnotations = 48
    let gridSize = 6
    let stayDuration: TimeInterval = 3
    let distanceThreshold: CLLocationDistance = 75
    
    // Timer and midnightTimer can be added as published properties as well if you need to observe them
    var timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    var midnightTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    func updateRegion(location: CLLocation?) {
        guard let location = location else { return }
        self.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        self.baseLocation = location.coordinate
    }
    
    func handleLocationChange(newLocation: CLLocation) {
        if let lastLocation = lastLocation {
            let distance = newLocation.distance(from: lastLocation)
            if distance > distanceThreshold {
                self.lastLocation = newLocation
                self.lastLocationUpdate = Date()
                hasStayedAtLocation = false
                specialAnnotationCounter = 0
            } else {
                if let lastUpdate = lastLocationUpdate, Date().timeIntervalSince(lastUpdate) >= stayDuration {
                    hasStayedAtLocation = true
                }
            }
        } else {
            self.lastLocation = newLocation
            self.lastLocationUpdate = Date()
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
    }
    
    private func calculateOffsetCoordinate(base: CLLocationCoordinate2D, offsetLat: Double, offsetLon: Double) -> CLLocationCoordinate2D {
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
        }
    }
}

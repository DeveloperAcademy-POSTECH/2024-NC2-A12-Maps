//
//  ContentView.swift
//  MC2Maps
//
//  Created by donghwan on 6/14/24.
//

// MapsView.swift
import SwiftUI
import MapKit

struct MapsView: View {
    @StateObject private var viewModel = MapsViewModel()
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        Map(coordinateRegion: $viewModel.region, showsUserLocation: true,
            annotationItems: viewModel.annotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                AnnotationView(annotation: annotation, selectedSpecialAnnotation: $viewModel.selectedSpecialAnnotation)
            }
        }
            .mapControls {
                MapUserLocationButton()
                MapScaleView()
                MapCompass()
                MapPitchToggle()
            }
            .mapStyle(.standard)
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                if let userLocation = locationManager.location {
                    viewModel.updateRegion(location: userLocation)
                }
            }
            .onChange(of: locationManager.location) { newLocation in
                if let newLocation = newLocation {
                    viewModel.handleLocationChange(newLocation: newLocation)
                    if viewModel.hasStayedAtLocation {
                        viewModel.addAnnotation()
                        viewModel.hasStayedAtLocation = false
                    }
                }
            }
            .onReceive(locationManager.locationManager.publisher(for: \.authorizationStatus)) { newStatus in
                if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                    if let userLocation = locationManager.location {
                        viewModel.updateRegion(location: userLocation)
                    }
                }
            }
            .onReceive(viewModel.timer) { _ in
                if viewModel.hasStayedAtLocation {
                    viewModel.addAnnotation()
                    viewModel.hasStayedAtLocation = false
                }
            }
            .onReceive(viewModel.midnightTimer) { _ in
                viewModel.checkMidnight()
            }
            .sheet(item: $viewModel.selectedSpecialAnnotation) { annotation in
                ScrollView{
                    ModalView(
                        annotation: annotation,
                        items: [
                            ("좌표", "북 \(annotation.coordinate.latitude)°, 동 \(annotation.coordinate.longitude)°")
                        ]
                    )
                    .presentationDetents([.fraction(0.1), .medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
                    .interactiveDismissDisabled()
                }
            }
    }
                }




//MARK: preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MapsView()
    }
}

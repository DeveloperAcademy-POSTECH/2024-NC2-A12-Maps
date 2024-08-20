//
//  AnnotationView.swift
//  MC2Maps
//
//  Created by Evelyn Hong on 8/20/24.
//

// AnnotationView.swift
import SwiftUI
import MapKit

struct AnnotationView: View {
    let annotation: AnnotationItem
    @Binding var selectedSpecialAnnotation: AnnotationItem?
    
    var body: some View {
        if annotation.isSpecial {
            Image("네잎")
                .resizable()
                .frame(width: 25, height: 25)
                .scaleEffect(selectedSpecialAnnotation == annotation ? 2.0 : 1.0)
                .rotationEffect(Angle(degrees: selectedSpecialAnnotation == annotation ? 10 : 0))
                .animation(.interpolatingSpring(mass: 2, stiffness: 80, damping: 10, initialVelocity: 0))
                .onTapGesture {
                    withAnimation {
                        if selectedSpecialAnnotation == annotation {
                            selectedSpecialAnnotation = nil
                        } else {
                            selectedSpecialAnnotation = annotation
                        }
                    }
                }
        } else {
            Image("세잎")
                .resizable()
                .frame(width: 25, height: 25)
        }
    }
}

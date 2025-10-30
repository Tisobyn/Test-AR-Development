//
//  ARViewContainer.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 30.10.2025.
//

import SwiftUI
import ARKit
import RealityKit

struct ARMeasurementView: UIViewRepresentable {
    typealias UIViewType = ARView
    
    let manager: ARMeasureManager

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        manager.setupARView(arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

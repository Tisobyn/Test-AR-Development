//
//  LengthMeasureManager.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 30.10.2025.
//

import Foundation
import Combine
import ARKit
import RealityKit
import FocusEntity

class LengthMeasureManager: ObservableObject, ARMeasureManager {
    
    private weak var arView: ARView?
    private weak var focus: CircularFocusEntity?
    
    private var collisionPoints: [AnchorEntity] = [] // Add this to track placed points
    
    private var isDebugOn = true
    
    func setupARView(_ arView: ARView) {
        self.arView = arView
        let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = [.horizontal, .vertical]
        arView.session.run(arConfig)
        self.focus = CircularFocusEntity(on: arView, style: .classic())
    }

    func addPoint() {
        guard let arView = arView else { return }
        let location = arView.center
        guard let result = arView.raycast(from: location, allowing: .existingPlaneInfinite, alignment: .any).first else { return }

        let worldTransform = result.worldTransform
        let pointPosition = SIMD3<Float>(worldTransform.columns.3.x,
                                         worldTransform.columns.3.y,
                                         worldTransform.columns.3.z)
        
        // 4. Create a visible marker
        let marker = createPointMarker()
        
        // 5. Create an AnchorEntity at the world position and add the marker to it
        let anchor = AnchorEntity(world: pointPosition)
        anchor.addChild(marker)
        
        // 6. Add the Anchor to the scene
        arView.scene.addAnchor(anchor)
        
        // Store the anchor
        collisionPoints.append(anchor)
    }
    
    
    private func createPointMarker() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.02)
        let material = SimpleMaterial(color: .green, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        return entity
    }
    
}

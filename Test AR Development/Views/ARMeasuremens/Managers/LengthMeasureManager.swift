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
    
#if DEBUG
    private var isDebugOn = true
#else
    private var isDebugOn = false
#endif
    
    func setupARView(_ arView: ARView) {
        self.arView = arView
        let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = [.horizontal, .vertical]
        arView.session.run(arConfig)
        self.focus = CircularFocusEntity(on: arView, style: .classic())
        
        if isDebugOn {
            arView.debugOptions = [.showAnchorOrigins, .showFeaturePoints]
        }
    }

    func addPointTapped() {
        addPointMarker()
    }
    
}

extension LengthMeasureManager {
    
    private func addPointMarker() {
        guard let arView = arView else { return }
    
        let pointPosition = calculatePointPosition()
        let pointMarker = ModelEntity.createPointMarker()
                
        // 5. Create an AnchorEntity at the world position and add the marker to it
        let anchor = AnchorEntity(world: pointPosition)
        anchor.addChild(pointMarker)
        
        // 6. Add the Anchor to the scene
        arView.scene.addAnchor(anchor)
        
        // Store the anchor
        collisionPoints.append(anchor)
    }
    
    private func calculatePointPosition() -> SIMD3<Float> {
        guard let focus = self.focus else { return SIMD3<Float>(0,0,0) }
        return focus.position(relativeTo: nil)
    }
    
    private func addPointMarker(pointMarker: ModelEntity, to pointPosition: SIMD3<Float>) {
        // 5. Create an AnchorEntity at the world position and add the marker to it
        let anchor = AnchorEntity(world: pointPosition)
        anchor.addChild(pointMarker)
        
        // 6. Add the Anchor to the scene
        arView?.scene.addAnchor(anchor)
        
        // Store the anchor
        collisionPoints.append(anchor)
    }
    
}

//
//  TemporalLineEntity.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 27.11.2025.
//

import RealityKit
import FocusEntity
import ARKit

@MainActor
final class TemporalLineEntity: Entity, HasAnchoring {
    
    internal weak var arView: ARView?
    let enityName = "TemporalLineEntity"
    var startingPoint: SIMD3<Float>
    var endingPoint: SIMD3<Float>
    
    init(on arView: ARView, startPoint: SIMD3<Float>, endPoint: SIMD3<Float>) {
        self.arView = arView
        self.startingPoint = startPoint
        self.endingPoint = endPoint
        super.init()
        addLine(startPoint: startPoint, endPoint: endPoint)
        arView.scene.addAnchor(self)
    }
    
    @MainActor @preconcurrency required init() {
        fatalError("init() has not been implemented")
    }
    
    private func addLine(startPoint: SIMD3<Float>, endPoint: SIMD3<Float>) {
        let direction = endPoint - startPoint
        let distance = length(direction)
        let entity = createLineEntity(distance: distance)
        self.addChild(entity)
    }
    
    private func createLineEntity(distance: Float) -> ModelEntity {
        let cylinder = MeshResource.generateBox(size: [0.005, 0.005, distance])
        var material = UnlitMaterial(color: .white)
        material.blending = .transparent(opacity: 0.5)
        
        let entity = ModelEntity(mesh: cylinder, materials: [material])
        entity.name = enityName
        entity.position = (startingPoint + endingPoint) / 2
        entity.look(at: endingPoint, from: entity.position, relativeTo: nil)
        return entity
    }
    
    public func changeEndPoint(_ newStartPoint: SIMD3<Float>,_ newEndPoint: SIMD3<Float>) {
        if let entity = self.children.first?.findEntity(named: enityName) {
            self.removeChild(entity)
        }
        
        self.endingPoint = newEndPoint
        self.startingPoint = newStartPoint
        let direction = newEndPoint - newStartPoint
        let distance = length(direction)
        let entity = createLineEntity(distance: distance)
        self.addChild(entity)
    }
    
}

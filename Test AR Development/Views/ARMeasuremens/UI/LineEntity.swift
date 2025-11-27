//
//  LineEntity.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 27.11.2025.
//

import RealityKit
import FocusEntity
import ARKit

@MainActor
final class LineEntity: Entity, HasAnchoring {
    
    internal weak var arView: ARView?
    let enityName = "LineEntity"
    private var startingPoint: SIMD3<Float>
    private var endingPoint: SIMD3<Float>
    
    init(on arView: ARView, startingPoint: SIMD3<Float>, endingPoint: SIMD3<Float>) {
        self.arView = arView
        self.startingPoint = startingPoint
        self.endingPoint = endingPoint
        super.init()
        self.name = enityName
        addLine(startPoint: startingPoint, endPoint: endingPoint)
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
        let cylinder = MeshResource.generateBox(size: [0.005, 0.005, distance], cornerRadius: 0.0025)
        let material = UnlitMaterial(color: .white)
        let entity = ModelEntity(mesh: cylinder, materials: [material])
        entity.name = enityName
        entity.position = (startingPoint + endingPoint) / 2
        entity.look(at: endingPoint, from: entity.position, relativeTo: nil)
        return entity
    }
    
}

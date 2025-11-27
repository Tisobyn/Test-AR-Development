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
    var startPoint: SIMD3<Float>
    var endPoint: SIMD3<Float>
    
    init(on arView: ARView, startPoint: SIMD3<Float>, endPoint: SIMD3<Float>) {
        self.arView = arView
        self.startPoint = startPoint
        self.endPoint = endPoint
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
        let cylinder = MeshResource.generateBox(size: [0.002, 0.002, distance])
        let material = SimpleMaterial(color: .red, isMetallic: false)
        let entity = ModelEntity(mesh: cylinder, materials: [material])
        entity.name = "LineEntity"
        entity.position = (startPoint + endPoint) / 2
        entity.look(at: endPoint, from: entity.position, relativeTo: nil)
        return entity
    }
    
    public func changeEndPoint(_ newStartPoint: SIMD3<Float>,_ newEndPoint: SIMD3<Float>) {
        if let entity = self.children.first?.findEntity(named: "LineEntity") {
            self.removeChild(entity)
        }
        
        self.endPoint = newEndPoint
        self.startPoint = newStartPoint
        let direction = newEndPoint - newStartPoint
        let distance = length(direction)
        let entity = createLineEntity(distance: distance)
        self.addChild(entity)
    }
        
}

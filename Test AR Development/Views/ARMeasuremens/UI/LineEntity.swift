//
//  LineEntity.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 27.11.2025.
//

import RealityKit
import FocusEntity
import ARKit
import Combine

@MainActor
final class LineEntity: Entity, HasAnchoring {
    
    internal weak var arView: ARView?
    let enityName = "LineEntity"
    private var startingPoint: SIMD3<Float>
    private var endingPoint: SIMD3<Float>
    
    private var labelCancellables = Set<AnyCancellable>()
    
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
        
        addDistanceLabel(
            distance: distance,
            startPoint: startingPoint,
            endPoint: endingPoint
        )
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
    
    private func addDistanceLabel(distance: Float, startPoint: SIMD3<Float>, endPoint: SIMD3<Float>) {
        guard let arView = arView else { return }

        // 1. Create text
        let distanceText = String(format: "%.2f m", distance)
        
        // Text mesh
        let textMesh = MeshResource.generateText(
            distanceText,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.02, weight: .medium),
            containerFrame: CGRect(x: 0, y: 0, width: 1, height: 1),
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        let textMaterial = UnlitMaterial(color: .black)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])

        // 2. Background plane (or rounded rectangle)
        let padding: Float = 0.01
        let textBounds = textMesh.bounds
        let width = Float(textBounds.extents.x) + padding
        let height = Float(textBounds.extents.y) + padding
        let depth: Float = 0.001
        
        let bgMesh = MeshResource.generatePlane(
            width: width,
            depth: height,
            cornerRadius: height / 2
        )
        let bgMaterial = UnlitMaterial(color: .white)
        let bgEntity = ModelEntity(mesh: bgMesh, materials: [bgMaterial])

        // 3. Container entity
        let container = Entity()
        container.addChild(bgEntity)
        container.addChild(textEntity)

        // Center text on background
        textEntity.position = SIMD3<Float>(0, 0, depth/2 + 0.0001) // slightly in front
        bgEntity.position = SIMD3<Float>(0, 0, 0)

        // Place container at center of line
        container.position = (startPoint + endPoint) / 2

        // Add container as child to line entity
        self.addChild(container)

        // 4. Billboard behavior: rotate container toward camera every frame
        arView.scene.subscribe(to: SceneEvents.Update.self) { [weak container, weak arView] _ in
            guard let container = container, let arView = arView else { return }

            // Get camera position
            let cameraPos = arView.cameraTransform.translation
            let direction = normalize(cameraPos - container.position)

            // Rotate container to face camera
            container.look(at: cameraPos, from: container.position, relativeTo: nil)
        }.store(in: &labelCancellables)
    }
    
}

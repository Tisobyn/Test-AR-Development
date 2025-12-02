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
    static let enityName = "LineEntity"
    private var startingPoint: SIMD3<Float>
    private var endingPoint: SIMD3<Float>
    
    private var labelCancellables = Set<AnyCancellable>()
    
    init(on arView: ARView, startingPoint: SIMD3<Float>, endingPoint: SIMD3<Float>) {
        self.arView = arView
        self.startingPoint = startingPoint
        self.endingPoint = endingPoint
        super.init()
        self.name = LineEntity.enityName
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
        entity.name = LineEntity.enityName
        entity.position = (startingPoint + endingPoint) / 2
        entity.look(at: endingPoint, from: entity.position, relativeTo: nil)
        return entity
    }
    
    private func addDistanceLabel(distance: Float, startPoint: SIMD3<Float>, endPoint: SIMD3<Float>) {
        // A. Create components using subfunctions
        let textEntity = createDistanceLabelTextEntity(distance: distance)
        
        // We need the text bounds to size the background
        guard let textMesh = textEntity.model?.mesh else { return }
        let bgEntity = createDistanceLabelBackground(textBounds: textMesh.bounds)
        
        let depthOffset: Float = 0.03
        bgEntity.position.z = depthOffset
        textEntity.position.z = depthOffset + 0.002
        
        // C. Create Container
        let container = Entity()
        container.addChild(bgEntity)
        container.addChild(textEntity)
        
        // D. Position Container
        // 1. Center of line
        container.position = (startPoint + endPoint) / 2
        
        // 2. Move Up (Y-Axis)
        // We calculate bgHeight from the mesh bounds to know how much to lift it
        let bgHeight = bgEntity.model?.mesh.bounds.extents.z ?? 0
        let halfLineThickness: Float = 0.0025
        container.position.y += (bgHeight / 2) + halfLineThickness
        
        self.addChild(container)
        
        // E. Billboard Logic
        setupBillboardBehavior(for: container)
    }
    
    private func createDistanceLabelTextEntity(distance: Float) -> ModelEntity {
        // 1. Format Text
        let distanceText = String(format: "%.2f m", distance)
        let font = MeshResource.Font.systemFont(ofSize: 0.02, weight: .bold)
        
        // 2. Generate Mesh
        let textMesh = MeshResource.generateText(
            distanceText,
            extrusionDepth: 0.001,
            font: font,
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        
        // 3. Create Entity
        let textMaterial = UnlitMaterial(color: .black)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        // 4. Center the pivot point
        // Text generates from bottom-left, so we offset position by negative center
        textEntity.position = -textMesh.bounds.center
        
        return textEntity
    }
    
    private func createDistanceLabelBackground(textBounds: BoundingBox) -> ModelEntity {
        // 1. Calculate Dimensions based on text size
        let padding: Float = 0.01
        let bgWidth = textBounds.extents.x + (padding * 2)
        let bgHeight = textBounds.extents.y + (padding * 1.5)
        
        // 2. Generate Plane Mesh
        // Note: In generatePlane, 'depth' is the height when looking top-down
        let bgMesh = MeshResource.generatePlane(
            width: bgWidth,
            depth: bgHeight,
            cornerRadius: bgHeight / 2
        )
        
        // 3. Create Entity
        let bgMaterial = UnlitMaterial(color: .white)
        let bgEntity = ModelEntity(mesh: bgMesh, materials: [bgMaterial])
        
        // 4. Rotate 90 degrees to stand upright
        // Planes generate flat (X-Z), we rotate on X to make it vertical (X-Y)
        bgEntity.orientation = simd_quatf(angle: .pi/2, axis: [1, 0, 0])
        
        return bgEntity
    }
    
    private func setupBillboardBehavior(for container: Entity) {
        guard let arView = arView else { return }
        
        arView.scene.subscribe(to: SceneEvents.Update.self) { [weak container, weak arView] _ in
            guard let container = container, let arView = arView else { return }
            
            let cameraPos = arView.cameraTransform.translation
            
            // 1. Look at camera
            container.look(at: cameraPos, from: container.position, relativeTo: nil)
            
            // 2. Rotate 180 degrees (Flip) so the front faces us
            container.transform.rotation *= simd_quatf(angle: .pi, axis: [0, 1, 0])
            
        }.store(in: &labelCancellables)
    }
    
}

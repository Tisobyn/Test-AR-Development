//
//  TemporalLineEntity.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 27.11.2025.
//

import RealityKit
import FocusEntity
import ARKit
import Combine

@MainActor
final class TemporalLineEntity: Entity, HasAnchoring {
    
    internal weak var arView: ARView?
    let enityName = "TemporalLineEntity"
    var startingPoint: SIMD3<Float>
    var endingPoint: SIMD3<Float>
    
    private var labelCancellables = Set<AnyCancellable>()
    
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
        let cylinder = MeshResource.generateBox(size: [0.005, 0.005, distance], cornerRadius: 0.0025)
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
    
    private func addDistanceLabel(distance: Float, startPoint: SIMD3<Float>, endPoint: SIMD3<Float>) {
        guard let arView = arView else { return }

        // 1. Create Text
        let distanceText = String(format: "%.2f m", distance)
        let font = MeshResource.Font.systemFont(ofSize: 0.02, weight: .bold)
        
        let textMesh = MeshResource.generateText(
            distanceText,
            extrusionDepth: 0.001,
            font: font,
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        
        let textMaterial = UnlitMaterial(color: .black)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        // Center the text
        let textBounds = textMesh.bounds
        textEntity.position = -textBounds.center
        textEntity.position.z += 0.002 // Text sits in front of background

        // 2. Create Background (Plane)
        // We use a Plane because it handles Corner Radius correctly (unlike a thin Box)
        let padding: Float = 0.01
        let bgWidth = textBounds.extents.x + (padding * 2)
        let bgHeight = textBounds.extents.y + (padding * 1.5)
        
        let bgMesh = MeshResource.generatePlane(
            width: bgWidth,
            depth: bgHeight,
            cornerRadius: bgHeight / 2 // Fully rounded ends
        )
        
        let bgMaterial = UnlitMaterial(color: .white)
        let bgEntity = ModelEntity(mesh: bgMesh, materials: [bgMaterial])
        
        // ROTATE PLANE: Planes lie flat (X-Z). Rotate 90deg on X to make it stand up (X-Y).
        bgEntity.orientation = simd_quatf(angle: .pi/2, axis: [1, 0, 0])

        // 3. Container
        let container = Entity()
        container.addChild(bgEntity)
        container.addChild(textEntity)

        // Position container
        container.position = (startPoint + endPoint) / 2
        container.position.y += 0.03
        
        self.addChild(container)

        // 4. Billboard (Face Camera)
        arView.scene.subscribe(to: SceneEvents.Update.self) { [weak container, weak arView] _ in
            guard let container = container, let arView = arView else { return }
            
            let cameraPos = arView.cameraTransform.translation
            
            // Step A: Look at the camera (This points the BACK of the object at the camera)
            container.look(at: cameraPos, from: container.position, relativeTo: nil)
            
            // Step B: Rotate 180 degrees (PI) on Y-axis to show the FRONT
            // This fixes both the "Mirrored Text" and the "Invisible Plane"
            container.transform.rotation *= simd_quatf(angle: .pi, axis: [0, 1, 0])
            
        }.store(in: &labelCancellables)
    }
    
}

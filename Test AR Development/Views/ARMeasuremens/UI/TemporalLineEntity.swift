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
    let lineEntityName = "TemporalLineEntity"
    let lineDistanceLabelName = "TemporalDistanceEntity"
    
    private var lineEntity: ModelEntity?
    private var labelContainer: Entity?
    private var textModel: ModelEntity?
    private var bgModel: ModelEntity?
    
    var startingPoint: SIMD3<Float>
    var endingPoint: SIMD3<Float>
    
    private var lastDistance: Float = 0.0 // ??
    
    private var labelCancellables = Set<AnyCancellable>()
    
    init(on arView: ARView, startingPoint: SIMD3<Float>, endingPoint: SIMD3<Float>) {
        self.arView = arView
        self.startingPoint = startingPoint
        self.endingPoint = endingPoint
        super.init()
        addLine(startingPoint: startingPoint, endingPoint: endingPoint)
        addDistanceLabel(startingPoint: startingPoint, endingPoint: endingPoint)
        arView.scene.addAnchor(self)
    }
    
    @MainActor @preconcurrency required init() {
        fatalError("init() has not been implemented")
    }
    
    private func addLine(startingPoint: SIMD3<Float>, endingPoint: SIMD3<Float>) {
        let direction = endingPoint - startingPoint
        let distance = length(direction)
        lineEntity = createLineEntity(distance: distance)
        lineEntity?.name = lineEntityName
        self.addChild(lineEntity!)
    }
    
    private func createLineEntity(distance: Float) -> ModelEntity {
        let cylinder = MeshResource.generateBox(size: [0.005, 0.005, distance], cornerRadius: 0.0025)
        var material = UnlitMaterial(color: .white)
        material.blending = .transparent(opacity: 0.5)
        
        let entity = ModelEntity(mesh: cylinder, materials: [material])
        entity.position = (startingPoint + endingPoint) / 2
        entity.look(at: endingPoint, from: entity.position, relativeTo: nil)
        return entity
    }
    
    private func addDistanceLabel(startingPoint: SIMD3<Float>, endingPoint: SIMD3<Float>) {
        let direction = endingPoint - startingPoint
        let distance = length(direction)
        // A. Create components using subfunctions
        textModel = createDistanceLabelTextEntity(distance: distance)
        
        // We need the text bounds to size the background
        guard let textMesh = textModel?.model?.mesh else { return }
        bgModel = createDistanceLabelBackground(textBounds: textMesh.bounds)
        
        let depthOffset: Float = 0.03
        bgModel?.position.z = depthOffset
        textModel?.position.z = depthOffset + 0.002
        
        // C. Create Container
        labelContainer = Entity()
        labelContainer?.addChild(bgModel!)
        labelContainer?.addChild(textModel!)
        
        // D. Position Container
        // 1. Center of line
        labelContainer?.position = (startingPoint + endingPoint) / 2
        
        // 2. Move Up (Y-Axis)
        // We calculate bgHeight from the mesh bounds to know how much to lift it
        let bgHeight = bgModel?.model?.mesh.bounds.extents.z ?? 0
        let halfLineThickness: Float = 0.0025
        labelContainer?.position.y += (bgHeight / 2) + halfLineThickness
        labelContainer?.name = lineDistanceLabelName
        self.addChild(labelContainer!)
        
        // E. Billboard Logic
        setupBillboardBehavior(for: labelContainer!)
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
    
    func changePoints(_ newStartingPoint: SIMD3<Float>, _ newEndingPoint: SIMD3<Float>) {
        guard let lineEntity = lineEntity,
              let labelContainer = labelContainer,
              let textModel = textModel,
              let bgModel = bgModel else { return }
        
        // 1. Calculate Math
        let vector = newEndingPoint - newStartingPoint
        let distance = length(vector)
        let midpoint = (newStartingPoint + newEndingPoint) / 2
        
        // 2. UPDATE LINE (Still stays in the middle)
        lineEntity.position = midpoint
        lineEntity.look(at: newEndingPoint, from: midpoint, relativeTo: nil)
        
        // Regenerate Line Mesh (Fast)
        lineEntity.model?.mesh = MeshResource.generateBox(
            size: [0.005, 0.005, distance],
            cornerRadius: 0.0025
        )
        
        // 3. UPDATE LABEL POSITION (MOVED TO ENDPOINT)
        // Change: Use newEndingPoint instead of midpoint
        labelContainer.position = newEndingPoint
        
        // Offset Logic:
        // We lift the label slightly UP (World Y) so it floats above the cursor
        // and doesn't block your view of the target dot.
        let bgHeight = bgModel.model?.mesh.bounds.extents.z ?? 0.05
        let hoverHeight: Float = 0.05 // 5cm above the point
        
        // Reset Y to the point's Y, then add offset
        labelContainer.position.y = newEndingPoint.y + (bgHeight / 2) + hoverHeight
        
        // 4. UPDATE LABEL TEXT (Throttled)
        if abs(distance - lastDistance) > 0.01 {
            let str = String(format: "%.2f m", distance)
            
            // Generate Text
            let font = MeshResource.Font.systemFont(ofSize: 0.02, weight: .bold)
            let newTextMesh = MeshResource.generateText(
                str,
                extrusionDepth: 0.001,
                font: font,
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            )
            
            textModel.model?.mesh = newTextMesh
            textModel.position = -newTextMesh.bounds.center
            textModel.position.z = 0.032
            
            // Resize Background
            let bounds = newTextMesh.bounds
            let padding: Float = 0.01
            let w = bounds.extents.x + (padding * 2)
            let h = bounds.extents.y + (padding * 1.5)
            
            let newBgMesh = MeshResource.generatePlane(width: w, depth: h, cornerRadius: h/2)
            bgModel.model?.mesh = newBgMesh
            
            lastDistance = distance
        }
    }
}

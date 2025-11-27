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

class LengthMeasureManager: NSObject, ObservableObject, ARMeasureManager {
    
    private weak var arView: ARView?
    private weak var focus: CircularFocusEntity?
    
    private var collisionPoints: [AnchorEntity] = [] // Add this to track placed points
    private var collisionPoints2: [AnchorPoint] = [] // Add this to t
    private var canDrawLine: Bool = false
    
    @Published var message: String = "Starting AR..."
    @Published var message2: String = ""
    @Published var message3: String = ""
#if DEBUG
    private var isDebugOn = false
#else
    private var isDebugOn = false
#endif
    
    func setupARView(_ arView: ARView) {
        self.arView = arView
        
        let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = [.horizontal, .vertical]
        arView.session.run(arConfig)
        arView.session.delegate = self
//
//       self.focus = CircularFocusEntity(on: arView, style: .classic())
        
        if isDebugOn {
            arView.debugOptions = [.showAnchorOrigins, .showFeaturePoints]
        }
    }

    func addPointTapped() {
        addPointMarker()
//        if canDrawLine { drawLineBetweenLastTwoPoints() }
    }
    
}

extension LengthMeasureManager {
    
    private func addPointMarker() {
        guard let arView = arView else { return }
        let pointPosition = calculatePointPosition()
        let pointMarker = ModelEntity.createPointMarker()
        let anchor = AnchorEntity(world: pointPosition)
        anchor.addChild(pointMarker)
        arView.scene.addAnchor(anchor)
        collisionPoints.append(anchor)
        canDrawLine = collisionPoints.count >= 2
    }
    
    private func calculatePointPosition() -> SIMD3<Float> {
        guard let focus = self.focus else { return SIMD3<Float>(0,0,0) }
        return focus.position(relativeTo: nil)
    }
    
//    private func drawLineBetweenLastTwoPoints() {
//        guard let arView = arView else { return }
//        
//        let count = collisionPoints.count
//        guard count >= 2 else { return }
//        
//        let startAnchor = collisionPoints[count - 2]
//        let endAnchor = collisionPoints[count - 1]
//        
//        let startPosition = startAnchor.position(relativeTo: nil)
//        let endPosition = endAnchor.position(relativeTo: nil)
//        
//        let vector = endPosition - startPosition
//        let distance = length(vector)
//        let midpoint = (startPosition + endPosition) / 2
//        
//        // --- NEW CODE: Add the Text Label ---
////        addMeasurementText(distance: distance, at: midpoint)
//        // ------------------------------------
//        
//        // ... (Your existing line drawing code remains below) ...
//        let lineMesh = MeshResource.generateBox(size: [0.005, 0.005, distance])
//        let lineMaterial = UnlitMaterial(color: .white)
//        let lineEntity = ModelEntity(mesh: lineMesh, materials: [lineMaterial])
//        
//        let lineAnchor = AnchorEntity(world: midpoint)
//        lineAnchor.addChild(lineEntity)
//        lineAnchor.look(at: endPosition, from: midpoint, relativeTo: nil)
//        
//        arView.scene.addAnchor(lineAnchor)
//    }
    
    private func addMeasurementText(distance: Float, at position: SIMD3<Float>) {
//        guard let arView = arView else { return }
//        
//        // 1. Format the distance (Meters to Centimeters)
//        // %.1f means 1 decimal place (e.g., "15.4 cm")
//        let cmValue = distance * 100
//        let textMesh = MeshResource.generateText(
//            String(format: "%.1f cm", cmValue),
//            extrusionDepth: 0.01,
//            font: .systemFont(ofSize: 0.05, weight: .bold),
//            containerFrame: .zero,
//            alignment: .center,
//            lineBreakMode: .byCharWrapping
//        )
//        
//        // 2. Create Material (Bright White for visibility)
//        let textMaterial = UnlitMaterial(color: .white)
//        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
//        
//        // 3. Create an Anchor at the midpoint
//        let textAnchor = AnchorEntity(world: position)
//        
//        // 4. Offset the text slightly UP (Y-axis) so it floats above the line
//        // Note: In AR, +Y is usually "up" relative to the world or anchor
//        textEntity.position.y += 0.05
//        
//        // 5. Add Billboard Component
//        // This makes the text automatically rotate to face the camera at all times
//        textEntity.components.set(BillboardComponent())
//        
//        textAnchor.addChild(textEntity)
//        arView.scene.addAnchor(textAnchor)
//        
//        // Track this anchor if you want to clear it later
//        collisionPoints.append(textAnchor)
    }
    
    
    
}

extension LengthMeasureManager: ARSessionDelegate {

    // 1. TRACKING STATE (Use message3 for technical details)
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var status = "Tracking: Normal"
        switch camera.trackingState {
        case .notAvailable: status = "Tracking: Unavailable"
        case .limited(let reason): status = "Tracking: Limited (\(reason))"
        case .normal: status = "Tracking: Normal"
        }
        
        // Update UI on the Main Thread
        DispatchQueue.main.async {
            self.message3 = status
            
            // Logic to update user instructions based on state
            if case .normal = camera.trackingState {
                self.message = "Tap screen to place point"
                if let arview = self.arView,
                   self.focus == nil
                {
                    self.focus = CircularFocusEntity(on: arview, style: .classic())
                }
                
            } else {
                self.message = "Move iPhone slowly..."
                // remove focus
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // removeAllLine
        // makeTempLine
        makeTempLine()
        // makeStableLine
    }
    
    private func removeAllLines() {
       
    }
    
    private func makeTempLine() {
        guard let lastPoint = collisionPoints.last else { return }
        guard let focus else { return }
        
        let pointPosition = lastPoint.position
        let finalPosition = focus.position
        drawTempLine(from: pointPosition, to: finalPosition)
    }
    
    func drawTempLine(from beginigPosition: SIMD3<Float>, to finalPosition: SIMD3<Float>) {
        let vector = beginigPosition - finalPosition
        let distance = length(vector)
        let midpoint = (beginigPosition + finalPosition) / 2
        
        let lineMesh =  MeshResource.generateBox(size: [0.005, 0.005, distance])
        let lineMaterial = UnlitMaterial(color: .white)
        let lineEntity = ModelEntity(mesh: lineMesh, materials: [lineMaterial])
     
        
        let lineAnchor = AnchorEntity(world: midpoint)
        
        lineAnchor.name = "temp-LineAnchor"
        lineAnchor.addChild(lineEntity)
        lineAnchor.look(at: finalPosition, from: midpoint, relativeTo: nil)
        
        arView?.scene.addAnchor(lineAnchor)
    }
    
    private func makeStableLines() {
        
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    // 2. ANCHOR UPDATES (Use message2 for statistics)
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
//        collisionPoints2.append(contentsOf: anchors)
        updateAnchorStats()
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
      // remove
        updateAnchorStats()
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        updateAnchorStats()
    }
    
    private func updateAnchorStats() {
        // Calculate stats
        let pointsCount = collisionPoints.count
        
        DispatchQueue.main.async {
            // e.g., "Active Points: 4"
            self.message2 = "Active Points: \(pointsCount)"
        }
    }
    
    // 2. Handle Errors
    // If the session crashes (e.g. camera in use by another app), handle it here.
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard let arError = error as? ARError else { return }
        
        let errorWithInfo = arError as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Join non-nil error messages
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.message = "Error: \(errorMessage)"
        }
    }
    
    // 3. Handle Interruptions
    // Examples: User receives a phone call or minimizes the app.
    func sessionWasInterrupted(_ session: ARSession) {
        self.message = "Session interrupted."
        // Create a visual blur or hide content if necessary
    }
    
    // 4. Handle Interruption Ended
    // When user returns to the app.
    func sessionInterruptionEnded(_ session: ARSession) {
        self.message = "Session resumed. Resetting tracking..."
        
        // Optional: Reset tracking if the user moved significantly while the app was backgrounded
        if let config = session.configuration {
            session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }
    }
}

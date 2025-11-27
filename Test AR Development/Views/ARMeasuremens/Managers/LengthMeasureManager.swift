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
    private var focus: CircularFocusEntity?
    private var tempLineEntity: TemporalLineEntity?
    private var lineEntity: LineEntity?
    
    var anchorEntities: [UUID: AnchorEntity] = [:]

    private var collisionPoints: [AnchorEntity] = [] 
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
        
        if isDebugOn {
            arView.debugOptions = [.showAnchorOrigins, .showFeaturePoints]
        }
    }

    func addPointTapped() {
        addPointMarker()
        if canDrawLine { addLineMarker() }
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
    
    private func addLineMarker() {
        guard let arView = arView else { return }
        let lastIndexOfPoints = collisionPoints.count - 1
        let startingPoint = collisionPoints[lastIndexOfPoints-1].position(relativeTo: nil)
        let endingPoint = collisionPoints[lastIndexOfPoints].position(relativeTo: nil)
        _ = LineEntity(on: arView, startingPoint: startingPoint, endingPoint: endingPoint)
    }
    
    private func calculatePointPosition() -> SIMD3<Float> {
        guard let focus = self.focus else { return SIMD3<Float>(0,0,0) }
        return focus.position(relativeTo: nil)
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
                
                if let arView = self.arView,
                   self.focus == nil
                {
                    self.focus = CircularFocusEntity(on: arView, style: .classic())
                    
                    if let focus = self.focus,
                       let lastPoint = self.collisionPoints.last
                    {
                        self.tempLineEntity = TemporalLineEntity(
                            on: arView,
                            startPoint: lastPoint.position(relativeTo: nil),
                            endPoint: focus.position(relativeTo: nil)
                        )
                    }
                }
                
            } else {
                self.message = "Move iPhone slowly..."
                // remove focus
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    }
    
    private func removeAllLines() {}
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    // 2. ANCHOR UPDATES (Use message2 for statistics)
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
   
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
      // remove
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("===== anchors \(anchors.count): \(anchors.map{ $0.name ?? "unknown"})")
        guard let lastPoint = collisionPoints.last,
              let arView = self.arView,
              let focus = self.focus
        else { return }
        self.tempLineEntity?.changeEndPoint(lastPoint.position(relativeTo: nil), focus.position(relativeTo: nil))
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

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

    private var allMeasurements: [[AnchorEntity]] = [[]]
    private var currentMeasurementPoints: [AnchorEntity] {
        return allMeasurements.last ?? []
    }
    
    private var canDrawLine: Bool = false
    private var canDrawTempLine: Bool = false
    
    @Published var message: String = "Starting AR..."
    @Published var status: String = ""
    
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
        if canDrawTempLine { initializeTemporaryLine() }
    }
    
    func cutMeasurement() {
        canDrawTempLine = false
        canDrawLine = false
        
        if !(currentMeasurementPoints.isEmpty) {
            allMeasurements.append([])
        }
    }
    
    func changeSelectedTool(_ tool: MeasurementTool) {
        
    }
    
    func undoLastPointAndLine() {
        
    }
    
    func reset() {
//        guard let arView = arView else { return }
//        // 1. VISUAL CLEANUP: Remove all existing points/lines from the Scene
//        // We loop through every "page" and every "point" we stored.
//        for anchor in arView.scene.anchors {
//            arView.scene.removeAnchor(anchor)
//        }
//        
//        // Remove the temporary line if it exists
//        tempLineEntity?.removeFromParent()
//        tempLineEntity = nil
//        
//        // 2. DATA CLEANUP: Reset variables to default
//        allMeasurements = [[]] // Reset to one empty list
//        canDrawLine = false
//        canDrawTempLine = false
//        
//        // 3. HARD RESET (Optional): Reset AR Tracking
//        // This makes the app "forget" the floor and start scanning from scratch.
//        // It is excellent for fixing tracking errors.
//        let config = ARWorldTrackingConfiguration()
//        config.planeDetection = [.horizontal, .vertical]
//        
//        // options: .resetTracking (Restarts the camera mapping)
//        // options: .removeExistingAnchors (Tells ARKit to delete its internal anchors)
//        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
//        
//        // 4. UI FEEDBACK
//        self.message = "Reset complete. Scan surroundings."
//        self.status = "Status: Resetting..."
    }
    
}

// UI added in Point Tapped

extension LengthMeasureManager {
    
    private func addPointMarker() {
        guard let arView = arView else { return }
        let pointPosition = calculatePointPosition()
        let pointMarker = ModelEntity.createPointMarker(color: .white)
        let anchor = AnchorEntity(world: pointPosition)
        anchor.addChild(pointMarker)
        arView.scene.addAnchor(anchor)
        
        if var currentSession = allMeasurements.last {
            currentSession.append(anchor)
            allMeasurements[allMeasurements.count - 1] = currentSession
        }
        canDrawLine = currentMeasurementPoints.count >= 2
        canDrawTempLine = currentMeasurementPoints.count > 0
    }
    
    private func addLineMarker() {
        guard let arView = arView else { return }
        let lastIndexOfPoints = currentMeasurementPoints.count - 1
        let startingPoint = currentMeasurementPoints[lastIndexOfPoints-1].position(relativeTo: nil)
        let endingPoint = currentMeasurementPoints[lastIndexOfPoints].position(relativeTo: nil)
        _ = LineEntity(on: arView, startingPoint: startingPoint, endingPoint: endingPoint)
    }
    
    private func calculatePointPosition() -> SIMD3<Float> {
        guard let focus = self.focus else { return SIMD3<Float>(0,0,0) }
        return focus.position(relativeTo: nil)
    }

    private func initializeTemporaryLine() {
        guard canDrawTempLine else { return }
        guard tempLineEntity == nil else { return }
        guard
            let focus = focus,
            let arView = self.arView,
            let lastPoint = self.currentMeasurementPoints.last
        else { return }
        
        self.tempLineEntity = TemporalLineEntity(
            on: arView,
            startingPoint: lastPoint.position(relativeTo: nil),
            endingPoint: focus.position(relativeTo: nil)
        )
    }
}

// Function for UI used in ARSessionDelegate
extension LengthMeasureManager {
    
    private func updateMessages(by trackingState: ARCamera.TrackingState) {
        switch trackingState {
        case .notAvailable:
            self.status = "Tracking: Unavailable"
            self.message = "Move iPhone slowly..."
        case .limited(let reason):
            self.status = "Tracking: Limited (\(reason))"
            self.message = "Move iPhone slowly..."
        case .normal:
            self.status = "Tracking: Normal"
            self.message = "Tap button to place point"
        }
    }
    
    private func ensureFocusEntity(by trackingState: ARCamera.TrackingState) {
        guard case .normal = trackingState else { return }
        guard self.focus == nil else { return }
        guard let arView = self.arView else { return }
        self.focus = CircularFocusEntity(on: arView, style: .classic())
    }
    
    private func updateTemporaryLine() {
        guard let tempLineEntity = tempLineEntity,
              let lastPoint = currentMeasurementPoints.last,
              let focus = self.focus
        else { return }
        tempLineEntity.changePoints(lastPoint.position(relativeTo: nil), focus.position(relativeTo: nil))
    }
    
}

extension LengthMeasureManager: ARSessionDelegate {

    // 1. TRACKING STATE (Use message3 for technical details)
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        self.updateMessages(by: camera.trackingState)

        DispatchQueue.main.async {
            self.ensureFocusEntity(by: camera.trackingState)
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        updateTemporaryLine()
    }
    
    
    // 2. ANCHOR UPDATES (Use message2 for statistics)
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) { }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) { }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) { }
    
    // Handling Errors
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool { return true }

    func sessionWasInterrupted(_ session: ARSession) { self.message = "Session interrupted." }

    func sessionInterruptionEnded(_ session: ARSession) { 
        self.message = "Session resumed. Resetting tracking..."
        if let config = session.configuration {
            session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }
    }
    
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
    
}

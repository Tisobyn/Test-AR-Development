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

    private var allMeasurementsPoints: [[AnchorEntity]] = [[]]
    private var allMeasurementsLines: [LineEntity] = []
    private var currentMeasurementPoints: [AnchorEntity] {
        return allMeasurementsPoints.last ?? []
    }
    
    private var canDrawLine: Bool = false
    private var canDrawTempLine: Bool = false
    
    @Published var selectedTool: MeasurementTool = .length
    
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
        arConfig.planeDetection = selectedTool.planeDetectionMode
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
            allMeasurementsPoints.append([])
        }
        
        tempLineEntity?.removeFromParent()
        tempLineEntity = nil
    }
    
    func changeSelectedTool(_ tool: MeasurementTool) {
        self.selectedTool = tool
        resetTracking()
    }
    
    func undoLastPointAndLine() {
        switch currentMeasurementPoints.count {
        case 0:
            if allMeasurementsPoints.count > 1 {
                undoCut()
            }
        case 1:
            undoLastPoint()
            recheckTempLine()
        default:
            undoLastPoint()
            undoLastLine()
            recheckTempLine()
        }
        
        self.message = "Undo last step"
    }
    
    func reset() {
        removeAllPointsAndLinesAnchors()
        clearAllData()
        resetTracking()
    }
    
}

// UI added in Point Tapped

extension LengthMeasureManager {
    
    private func addPointMarker() {
        guard let arView = arView else { return }
        let pointPosition = calculatePointPosition()
        let pointMarker = ModelEntity.createPointMarker(color: .white)
        let anchor = AnchorEntity(world: pointPosition)
        anchor.name = "MeasurementPoint"
        anchor.addChild(pointMarker)
        arView.scene.addAnchor(anchor)
        
        if var currentSession = allMeasurementsPoints.last {
            currentSession.append(anchor)
            allMeasurementsPoints[allMeasurementsPoints.count - 1] = currentSession
        }
        canDrawLine = currentMeasurementPoints.count >= 2
        canDrawTempLine = currentMeasurementPoints.count > 0
    }
    
    private func addLineMarker() {
        guard let arView = arView else { return }
        let lastIndexOfPoints = currentMeasurementPoints.count - 1
        let startingPoint = currentMeasurementPoints[lastIndexOfPoints-1].position(relativeTo: nil)
        let endingPoint = currentMeasurementPoints[lastIndexOfPoints].position(relativeTo: nil)
        let lineEntity = LineEntity(on: arView, startingPoint: startingPoint, endingPoint: endingPoint)
        allMeasurementsLines.append(lineEntity)
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

// Functions

extension LengthMeasureManager {
        
    private func removeAllPointsAndLinesAnchors() {
        guard let arView else { return }
        let itemsToRemove = arView.scene.anchors.filter { anchor in
            return anchor.name == "LineEntity" ||
            anchor.name == "TemporalLineEntity" ||
            anchor.name == "MeasurementPoint"
        }
        
        for anchor in itemsToRemove {
            arView.scene.removeAnchor(anchor)
        }
    }
    
    private func clearAllData() {
        guard arView != nil else { return }
        allMeasurementsPoints = [[]]
        allMeasurementsLines = []
        canDrawLine = false
        canDrawTempLine = false
        tempLineEntity?.removeFromParent()
        tempLineEntity = nil
        self.message = "Cleared. Ready to measure."
    }
    
    private func resetTracking() {
        guard let arView = arView else { return }
        focus?.destroy()
        focus = nil
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = selectedTool.planeDetectionMode
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        // 3. UI FEEDBACK
        self.message = "Reset complete. Scan surroundings."
    }
    
    private func recheckTempLine() {
        tempLineEntity?.removeFromParent()
        tempLineEntity = nil
        
        // 5. Update State
        let count = currentMeasurementPoints.count
        canDrawLine = count >= 2
        canDrawTempLine = count > 0
        
        // 6. Restart Temp Line (If there is still a point left to connect to)
        if canDrawTempLine {
            initializeTemporaryLine()
        }
    }
    
    private func undoCut() {
        allMeasurementsPoints.removeLast()
        canDrawLine = currentMeasurementPoints.count >= 2
        canDrawTempLine = currentMeasurementPoints.count > 0
        initializeTemporaryLine()
    }
    
    private func undoLastPoint() {
        guard let arView = arView else { return }
        guard var currentSession = allMeasurementsPoints.last, !currentSession.isEmpty else { return }
        let pointAnchor = currentSession.removeLast()
        arView.scene.removeAnchor(pointAnchor)
        allMeasurementsPoints[allMeasurementsPoints.count - 1] = currentSession
    }
    
    private func undoLastLine() {
        guard let arView = arView else { return }
    
        if let lineAnchor = allMeasurementsLines.popLast() {
            arView.scene.removeAnchor(lineAnchor)
        }
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
        guard let arView = self.arView else { return }
        switch trackingState {
        case .normal:
            guard self.focus == nil else { return }
            self.focus = CircularFocusEntity(on: arView, style: .classic())
        case .limited(_), .notAvailable:
            guard self.focus != nil else { return }
        }
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

import SwiftUI
import SceneKit

struct MeasurementMiniMap: UIViewRepresentable {
    
    var points: [[SIMD3<Float>]]
    @Binding var mode: MiniMapMode
    
    private let cameraNodeName = "MainCamera"
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        sceneView.autoenablesDefaultLighting = true
        
        // Setup Camera Node
        let cameraNode = SCNNode()
        cameraNode.name = cameraNodeName
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let scene = uiView.scene else { return }
        
        // 1. Rebuild Content
        scene.rootNode.childNode(withName: "MapContent", recursively: false)?.removeFromParentNode()
        
        // Calculate new bounds
        let bounds = calculateBounds(of: points)
        
        let contentNode = SCNNode()
        contentNode.name = "MapContent"
        
        // Dynamic sizing logic
        let maxDimension = max(bounds.x, bounds.y, bounds.z)
        let baseScale = CGFloat(max(maxDimension, 0.5))
        let adaptiveRadius = baseScale * 0.02
        
        // Draw Dots & Lines
        for section in points {
            guard !section.isEmpty else { continue }
            for (index, point) in section.enumerated() {
                let pos = SCNVector3(point.x, point.y, point.z)
                let dot = createDot(radius: adaptiveRadius * 2)
                dot.position = pos
                contentNode.addChildNode(dot)
                
                if index > 0 {
                    let prev = section[index - 1]
                    let prevPos = SCNVector3(prev.x, prev.y, prev.z)
                    let line = createLine(from: prevPos, to: pos, radius: adaptiveRadius)
                    contentNode.addChildNode(line)
                }
            }
        }
        
        // CENTER CONTENT
        contentNode.position = SCNVector3(-bounds.center.x, -bounds.center.y, -bounds.center.z)
        scene.rootNode.addChildNode(contentNode)
        
        // 2. UPDATE CAMERA (The Fix is inside here)
        updateCameraState(uiView: uiView, bounds: bounds)
    }
    
    private func updateCameraState(uiView: SCNView, bounds: (x: Float, y: Float, z: Float, center: SCNVector3)) {
        guard let scene = uiView.scene,
              let camNode = scene.rootNode.childNode(withName: cameraNodeName, recursively: true),
              let camera = camNode.camera else { return }
        
        // --- FIX: FORCE RESET CONTROLLER ---
        // 1. Ensure the view is using OUR camera node
        if uiView.pointOfView != camNode {
            uiView.pointOfView = camNode
        }
        
        // 2. Reset the internal controller target to the center (0,0,0)
        // This stops the camera from getting stuck looking at where the user panned.
        uiView.defaultCameraController.target = SCNVector3Zero
        uiView.defaultCameraController.inertiaEnabled = false // Stop spinning
        // -----------------------------------

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        
        switch mode {
        case .horizontal:
            // 2D Floor Plan
            uiView.allowsCameraControl = false
            camera.usesOrthographicProjection = true
            
            let maxDim = max(bounds.x, bounds.z)
            camera.orthographicScale = Double(max(maxDim, 0.5)) * 0.7
            
            camNode.position = SCNVector3(0, 20, 0)
            camNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            
        case .vertical:
            // 2D Wall View
            uiView.allowsCameraControl = false
            camera.usesOrthographicProjection = true
            
            let maxDim = max(bounds.x, bounds.y)
            camera.orthographicScale = Double(max(maxDim, 0.5)) * 0.7
            
            camNode.position = SCNVector3(0, 0, 20)
            camNode.eulerAngles = SCNVector3(0, 0, 0)
            
        case .threeD:
            // 3D Interactive
            uiView.allowsCameraControl = true // User takes control
            camera.usesOrthographicProjection = false
            camera.fieldOfView = 45
            
            let maxDim = max(bounds.x, bounds.y, bounds.z)
            let dist = Float(max(maxDim, 0.5)) * 1.8
            
            // Note: In 3D mode, if the user touches the screen, SceneKit overrides
            // this position. But because we reset 'target' above, it won't drift away.
            camNode.position = SCNVector3(0, dist, dist)
            camNode.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        }
        
        SCNTransaction.commit()
    }
    
    // ... (Keep helpers: createDot, createLine, calculateBounds) ...
    // Returns (Width-X, Height-Y, Length-Z, Center-Vector)
    private func calculateBounds(of sections: [[SIMD3<Float>]]) -> (x: Float, y: Float, z: Float, center: SCNVector3) {
        let allPoints = sections.flatMap { $0 }
        
        guard !allPoints.isEmpty else {
            return (1, 1, 1, SCNVector3Zero)
        }
        
        let minX = allPoints.map { $0.x }.min() ?? 0
        let maxX = allPoints.map { $0.x }.max() ?? 0
        let minY = allPoints.map { $0.y }.min() ?? 0
        let maxY = allPoints.map { $0.y }.max() ?? 0
        let minZ = allPoints.map { $0.z }.min() ?? 0
        let maxZ = allPoints.map { $0.z }.max() ?? 0
        
        let widthX = maxX - minX
        let heightY = maxY - minY
        let lengthZ = maxZ - minZ
        
        let centerX = minX + (widthX / 2)
        let centerY = minY + (heightY / 2)
        let centerZ = minZ + (lengthZ / 2)
        
        return (widthX, heightY, lengthZ, SCNVector3(centerX, centerY, centerZ))
    }
    
    private func createDot(radius: CGFloat) -> SCNNode {
        let sphere = SCNSphere(radius: radius)
        sphere.firstMaterial?.diffuse.contents = UIColor.white
        return SCNNode(geometry: sphere)
    }
    
    private func createLine(from start: SCNVector3, to end: SCNVector3, radius: CGFloat) -> SCNNode {
        let vector = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let cylinder = SCNCylinder(radius: radius, height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = UIColor.white
        let node = SCNNode(geometry: cylinder)
        node.position = SCNVector3((start.x + end.x) / 2, (start.y + end.y) / 2, (start.z + end.z) / 2)
        node.look(at: end, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 1, 0))
        return node
    }
}

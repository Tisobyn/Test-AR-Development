import SwiftUI
import SceneKit

struct MeasurementMiniMap: UIViewRepresentable {
    
    var points: [[SIMD3<Float>]]
    @Binding var mode: MiniMapMode // <--- NEW BINDING
    
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
        guard let scene = uiView.scene else { return }
        
        // 1. Clear old content
        scene.rootNode.childNode(withName: "MapContent", recursively: false)?.removeFromParentNode()
        
        // 2. Calculate 3D Bounds
        let bounds = calculateBounds(of: points)
        
        // Find the largest dimension of the drawing to set our Base Scale
        let maxDimension = max(bounds.x, bounds.y, bounds.z)
        let baseScale = CGFloat(max(maxDimension, 0.5))
        
        // Dynamic Thickness (Dots get smaller if the map is huge)
        let adaptiveRadius = baseScale * 0.02
        
        // 3. Rebuild Content
        let contentNode = SCNNode()
        contentNode.name = "MapContent"
        
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
        
        // 4. CENTER EVERYTHING (X, Y, and Z)
        // By negating the center, we move the drawing so its geometric center is at (0,0,0)
        contentNode.position = SCNVector3(-bounds.center.x, -bounds.center.y, -bounds.center.z)
        scene.rootNode.addChildNode(contentNode)
        
        // 5. Update Camera
        updateCameraState(uiView: uiView, bounds: bounds)
    }
    
    // Inside MeasurementMiniMap struct...
    
    private func updateCameraState(uiView: SCNView, bounds: (x: Float, y: Float, z: Float, center: SCNVector3)) {
        guard let scene = uiView.scene,
              let camNode = scene.rootNode.childNode(withName: cameraNodeName, recursively: true),
              let camera = camNode.camera else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        
        switch mode {
        case .horizontal:
            uiView.allowsCameraControl = false
            camera.usesOrthographicProjection = true
            
            // Fit based on Floor Area (X and Z)
            let maxDim = max(bounds.x, bounds.z)
            camera.orthographicScale = Double(max(maxDim, 0.5)) * 0.7
            
            // Look Down (Y-Axis)
            camNode.position = SCNVector3(0, 20, 0)
            camNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            
        case .vertical:
            uiView.allowsCameraControl = false
            camera.usesOrthographicProjection = true
            
            // Fit based on Wall Area (X and Y) <--- THIS FIXES VERTICAL ZOOM
            let maxDim = max(bounds.x, bounds.y)
            camera.orthographicScale = Double(max(maxDim, 0.5)) * 0.7
            
            // Look Forward (Z-Axis)
            camNode.position = SCNVector3(0, 0, 20)
            camNode.eulerAngles = SCNVector3(0, 0, 0)
            
        case .threeD:
            uiView.allowsCameraControl = true
            camera.usesOrthographicProjection = false
            camera.fieldOfView = 45
            
            // Fit everything
            let maxDim = max(bounds.x, bounds.y, bounds.z)
            let dist = Float(max(maxDim, 0.5)) * 1.8 // Move back enough to see it all
            
            // Angled View
            camNode.position = SCNVector3(0, dist, dist)
            camNode.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        }
        
        SCNTransaction.commit()
    }
    
    // ... (Keep createDot, createLine, calculateBounds helpers from previous code) ...
    // Note: Use UIColor.white for lines/dots to contrast with black background
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
    
    // Returns (Width-X, Height-Y, Length-Z, Center-Vector)
    private func calculateBounds(of sections: [[SIMD3<Float>]]) -> (x: Float, y: Float, z: Float, center: SCNVector3) {
        
        let allPoints = sections.flatMap { $0 }
        
        guard !allPoints.isEmpty else {
            return (1, 1, 1, SCNVector3Zero)
        }
        
        // 1. Calculate Min/Max for ALL 3 Axes
        let minX = allPoints.map { $0.x }.min() ?? 0
        let maxX = allPoints.map { $0.x }.max() ?? 0
        
        let minY = allPoints.map { $0.y }.min() ?? 0
        let maxY = allPoints.map { $0.y }.max() ?? 0
        
        let minZ = allPoints.map { $0.z }.min() ?? 0
        let maxZ = allPoints.map { $0.z }.max() ?? 0
        
        // 2. Dimensions
        let widthX = maxX - minX
        let heightY = maxY - minY
        let lengthZ = maxZ - minZ
        
        // 3. Center Point
        let centerX = minX + (widthX / 2)
        let centerY = minY + (heightY / 2) // <--- Crucial for Vertical centering
        let centerZ = minZ + (lengthZ / 2)
        
        return (widthX, heightY, lengthZ, SCNVector3(centerX, centerY, centerZ))
    }
}

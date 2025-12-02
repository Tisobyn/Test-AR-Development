import SwiftUI
import SceneKit

import SwiftUI
import SceneKit

struct MeasurementMiniMap: UIViewRepresentable {
    
    var points: [[SIMD3<Float>]]
    
    private let cameraNodeName = "OverheadCamera"
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        
        // 1. Setup Scene
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false // Disable user control, we handle auto-scale
        
        // 2. Setup Orthographic Camera (Best for Mini-Maps)
        let cameraNode = SCNNode()
        cameraNode.name = cameraNodeName
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true // Turns off 3D perspective distortion
        camera.orthographicScale = 1 // Default, will be updated dynamically
        cameraNode.camera = camera
        
        // Position high looking straight down
        cameraNode.position = SCNVector3(0, 20, 0)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let scene = uiView.scene else { return }
        
        // 1. Clear old content
        scene.rootNode.childNode(withName: "MapContent", recursively: false)?.removeFromParentNode()
        
        // 2. Calculate Bounds (Min/Max size of the drawing)
        let bounds = calculateBounds(of: points)
        let mapSize = max(bounds.width, bounds.height)
        
        // 3. Dynamic Sizing
        // If map is huge (10m), use thick lines. If small (10cm), use thin lines.
        // We set line thickness to roughly 1.5% of the total map size.
        let baseScale = max(mapSize, 0.5) // Minimum 0.5m scale to prevent infinite zoom on single dots
        let adaptiveRadius = CGFloat(baseScale * 0.015)
        
        // 4. Create Container
        let contentNode = SCNNode()
        contentNode.name = "MapContent"
        
        for section in points {
            guard !section.isEmpty else { continue }
            
            for (index, point) in section.enumerated() {
                let pos = SCNVector3(point.x, point.y, point.z)
                
                // Draw Dot (White)
                let dot = createDot(radius: adaptiveRadius * 2) // Dots are 2x thicker than lines
                dot.position = pos
                contentNode.addChildNode(dot)
                
                // Draw Line (White)
                if index > 0 {
                    let prev = section[index - 1]
                    let prevPos = SCNVector3(prev.x, prev.y, prev.z)
                    let line = createLine(from: prevPos, to: pos, radius: adaptiveRadius)
                    contentNode.addChildNode(line)
                }
            }
        }
        
        // 5. Center the Content
        // We move the content so its center is at (0,0,0) where the camera looks
        contentNode.position = SCNVector3(-bounds.center.x, 0, -bounds.center.z)
        scene.rootNode.addChildNode(contentNode)
        
        // 6. Update Camera Zoom (Scale to Fit)
        if let camNode = scene.rootNode.childNode(withName: cameraNodeName, recursively: false),
           let camera = camNode.camera {
            
            // Add 20% padding around the drawing
            let targetScale = (Double(baseScale) / 2.0) * 1.2
            
            // Animate the zoom for smoothness
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            camera.orthographicScale = targetScale
            SCNTransaction.commit()
        }
    }
    
    // MARK: - Builders
    
    private func createDot(radius: CGFloat) -> SCNNode {
        let sphere = SCNSphere(radius: radius)
        sphere.firstMaterial?.diffuse.contents = UIColor.white
        sphere.firstMaterial?.emission.contents = UIColor(white: 0.8, alpha: 1.0) // Slight glow
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
    
    // MARK: - Math Helpers
    
    // Returns width, height, and center point of the entire drawing
    private func calculateBounds(of sections: [[SIMD3<Float>]]) -> (width: Float, height: Float, center: SCNVector3) {
        
        // Flatten all points into one list
        let allPoints = sections.flatMap { $0 }
        
        guard !allPoints.isEmpty else {
            return (1, 1, SCNVector3Zero)
        }
        
        let minX = allPoints.map { $0.x }.min() ?? 0
        let maxX = allPoints.map { $0.x }.max() ?? 0
        let minZ = allPoints.map { $0.z }.min() ?? 0
        let maxZ = allPoints.map { $0.z }.max() ?? 0
        
        let width = maxX - minX
        let height = maxZ - minZ
        
        let centerX = minX + (width / 2)
        let centerZ = minZ + (height / 2)
        
        return (width, height, SCNVector3(centerX, 0, centerZ))
    }
}

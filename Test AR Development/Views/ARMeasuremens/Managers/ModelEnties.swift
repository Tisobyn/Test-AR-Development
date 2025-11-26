import RealityKit
import UIKit

extension ModelEntity {
    
    /// Creates a spherical point marker with a specific radius and color.
    static func createPointMarker(radius: Float = 0.01, color: UIColor = .white) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: radius)
        
        var material = UnlitMaterial()
        material.color = .init(tint: color)
        material.blending = .opaque
        
        // Create the ModelEntity using the mesh and material
        return ModelEntity(mesh: mesh, materials: [material])
    }
    
}

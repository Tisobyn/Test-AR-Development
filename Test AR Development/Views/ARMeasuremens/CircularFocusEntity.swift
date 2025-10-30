//
//  CircularFocusEntity.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 30.10.2025.
//

import RealityKit
import FocusEntity
import ARKit

@MainActor
final class CircularFocusEntity: FocusEntity {
    
    /// Gap between the two half-circles in radians. Default is π/6 (30 degrees)
    var ringGap: Float = Float.pi / 6
    var accentColor: UIColor = UIColor(hex: "#FEB317")
    
    required init(on arView: ARView, style: FocusEntityComponent.Style) {
        let focusComponent = FocusEntityComponent(style: style)
        super.init(on: arView, focus: focusComponent)
        self.name = "CircularFocusEntity"
        setupCircularVisuals()
    }
    
    required init(on arView: ARView, focus: FocusEntityComponent) {
        super.init(on: arView, focus: focus)
        self.name = "CircularFocusEntity"
        setupCircularVisuals()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    private func setupCircularVisuals() {
        // Remove existing children (default square visuals)
        self.children.removeAll()
        
        // CHANGED: Renamed function for clarity
        createQuadrantRing()
        addCirclarOuterPlane()
        addCirclarInnerPlane()
        addCenterDot()
    }
    
    // CHANGED: This function now creates 4 quadrant arcs
    private func createQuadrantRing() {
        // Create two half-circles with rounded ends and a configurable gap
        let outerRadius: Float = 0.08
        let innerRadius: Float = 0.07
        let ringThickness = outerRadius - innerRadius
        let midRadius = (outerRadius + innerRadius) / 2
        let gap = self.ringGap / 2 // We'll use half the gap on each side of the axis
        
        // Create the four quarter-circle arcs
        // Quadrant 1 (Top-Right)
        createHalfCircleArc(outerRadius: outerRadius, innerRadius: innerRadius, startAngle: gap, endAngle: (Float.pi / 2) - gap)
        
        // Quadrant 2 (Top-Left)
        createHalfCircleArc(outerRadius: outerRadius, innerRadius: innerRadius, startAngle: (Float.pi / 2) + gap, endAngle: Float.pi - gap)
        
        // Quadrant 3 (Bottom-Left)
        createHalfCircleArc(outerRadius: outerRadius, innerRadius: innerRadius, startAngle: Float.pi + gap, endAngle: (3 * Float.pi / 2) - gap)
        
        // Quadrant 4 (Bottom-Right)
        createHalfCircleArc(outerRadius: outerRadius, innerRadius: innerRadius, startAngle: (3 * Float.pi / 2) + gap, endAngle: (2 * Float.pi) - gap)

        // CHANGED: Add 8 rounded caps (at the end of each new arc)
        addQuadrantCaps(radius: midRadius, thickness: ringThickness)
    }
    
    private func createHalfCircleArc(outerRadius: Float, innerRadius: Float, startAngle: Float, endAngle: Float) {
        // This function is generic and doesn't need any changes.
        // It correctly generates an arc mesh between any two angles.
        
        let segments = 32
        let angleRange = endAngle - startAngle
        let segmentAngle = angleRange / Float(segments)
        
        var vertices: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        var normals: [SIMD3<Float>] = []
        
        // Create vertices for this arc
        for i in 0...segments {
            let angle = startAngle + Float(i) * segmentAngle
            let cosAngle = cos(angle)
            let sinAngle = sin(angle)
            
            // Outer vertex
            vertices.append(SIMD3<Float>(cosAngle * outerRadius, 0, sinAngle * outerRadius))
            normals.append(SIMD3<Float>(0, 1, 0))
            
            // Inner vertex
            vertices.append(SIMD3<Float>(cosAngle * innerRadius, 0, sinAngle * innerRadius))
            normals.append(SIMD3<Float>(0, 1, 0))
        }
        
        // Create triangles for this arc
        for i in 0..<segments {
            let current = UInt32(i * 2)
            let next = UInt32((i + 1) * 2)
            
            // First triangle
            indices.append(contentsOf: [current, current + 1, next])
            
            // Second triangle
            indices.append(contentsOf: [current + 1, next + 1, next])
        }
        
        // Create mesh for this arc
        var descriptor = MeshDescriptor(name: "HalfCircleArc")
        descriptor.positions = MeshBuffer(vertices)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)
        
        do {
            let mesh = try MeshResource.generate(from: [descriptor])
            
            // Create material
            var material = UnlitMaterial()
            material.color = .init(tint: accentColor)
            material.blending = .transparent(opacity: .init(floatLiteral: 0.9))
            
            // Create entity for this arc
            let arcEntity = ModelEntity(mesh: mesh, materials: [material])
            self.addChild(arcEntity)
            
        } catch {
            print("Failed to create arc: \(error)")
        }
    }
    
    // CHANGED: This function now adds 8 caps, one for each end of the 4 arcs
    private func addQuadrantCaps(radius: Float, thickness: Float) {
        let capRadius = thickness / 2
        let gap = self.ringGap / 2

        // Arc 1 (Top-Right)
        addCircularCap(at: gap, radius: radius, capRadius: capRadius)
        addCircularCap(at: (Float.pi / 2) - gap, radius: radius, capRadius: capRadius)
        
        // Arc 2 (Top-Left)
        addCircularCap(at: (Float.pi / 2) + gap, radius: radius, capRadius: capRadius)
        addCircularCap(at: Float.pi - gap, radius: radius, capRadius: capRadius)
        
        // Arc 3 (Bottom-Left)
        addCircularCap(at: Float.pi + gap, radius: radius, capRadius: capRadius)
        addCircularCap(at: (3 * Float.pi / 2) - gap, radius: radius, capRadius: capRadius)
        
        // Arc 4 (Bottom-Right)
        addCircularCap(at: (3 * Float.pi / 2) + gap, radius: radius, capRadius: capRadius)
        addCircularCap(at: (2 * Float.pi) - gap, radius: radius, capRadius: capRadius)
    }
    
    private func addCircularCap(at angle: Float, radius: Float, capRadius: Float) {
        // This function is also generic and needs no changes.
        
        // Create a small circular cap using a flattened sphere
        let sphereMesh = MeshResource.generateSphere(radius: capRadius)
        
        var material = UnlitMaterial()
        material.color = .init(tint: accentColor)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.9))
        
        let capEntity = ModelEntity(mesh: sphereMesh, materials: [material])
        
        // Position the cap at the end of the arc
        let x = cos(angle) * radius
        let z = sin(angle) * radius
        capEntity.position = SIMD3<Float>(x, 0, z)
        
        // Flatten the sphere to make it look like a rounded end
        capEntity.scale = SIMD3<Float>(1.0, 0.1, 1.0)
        
        self.addChild(capEntity)
    }
    
    // this function create circle
    private func addCirclarOuterPlane() {
        // Try to use cylinder for a perfect circle (iOS 18+), fallback to rounded box
        let planeSize: Float = 0.06
        let dotHeight: Float = 0.001
        
        if #available(iOS 18.0, *) {
            // Use cylinder for perfect circle
            let dotMesh = MeshResource.generateCylinder(height: dotHeight, radius: planeSize)
            
            var dotMaterial = UnlitMaterial()
            dotMaterial.color = .init(tint: UIColor.white)
            dotMaterial.blending = .transparent(opacity: 0.4)
            
            let dotEntity = ModelEntity(mesh: dotMesh, materials: [dotMaterial])
            dotEntity.position = SIMD3<Float>(0, 0.002, 0)
            
            self.addChild(dotEntity)
        } else {
            // Fallback for iOS 16: use sphere flattened by scale
            let sphereMesh = MeshResource.generateSphere(radius: planeSize)
            
            var dotMaterial = UnlitMaterial()
            dotMaterial.color = .init(tint: UIColor.white)
            dotMaterial.blending = .transparent(opacity: 0.4)
            
            let dotEntity = ModelEntity(mesh: sphereMesh, materials: [dotMaterial])
            
            // Flatten the sphere to make it look like a flat circle
            dotEntity.scale = SIMD3<Float>(1.0, 0.01, 1.0)
            dotEntity.position = SIMD3<Float>(0, 0.002, 0)
            
            self.addChild(dotEntity)
        }
    }
    
    private func addCirclarInnerPlane() {
        // Try to use cylinder for a perfect circle (iOS 18+), fallback to rounded box
        let planeSize: Float = 0.015
        let dotHeight: Float = 0.002
        
        if #available(iOS 18.0, *) {
            // Use cylinder for perfect circle
            let dotMesh = MeshResource.generateCylinder(height: dotHeight, radius: planeSize)
            
            var dotMaterial = UnlitMaterial()
            dotMaterial.color = .init(tint: UIColor.white)
            dotMaterial.blending = .opaque
            
            let dotEntity = ModelEntity(mesh: dotMesh, materials: [dotMaterial])
            dotEntity.position = SIMD3<Float>(0, 0.002, 0)
            
            self.addChild(dotEntity)
        } else {
            // Fallback for iOS 16: use sphere flattened by scale
            let sphereMesh = MeshResource.generateSphere(radius: planeSize)
            
            var dotMaterial = UnlitMaterial()
            dotMaterial.color = .init(tint: UIColor.white)
            dotMaterial.blending = .opaque
            
            let dotEntity = ModelEntity(mesh: sphereMesh, materials: [dotMaterial])
            
            // Flatten the sphere to make it look like a flat circle
            dotEntity.scale = SIMD3<Float>(1.0, 0.01, 1.0)
            dotEntity.position = SIMD3<Float>(0, 0.002, 0)
            
            self.addChild(dotEntity)
        }
    }
    
    private func addCenterDot() {
        // Try to use cylinder for a perfect circle (iOS 18+), fallback to rounded box
        let planeSize: Float = 0.01
        let dotHeight: Float = 0.002
        
        let sphereMesh = MeshResource.generateSphere(radius: planeSize)
        
        var dotMaterial = UnlitMaterial()
        dotMaterial.color = .init(tint: accentColor)
        dotMaterial.blending = .opaque
        
        let dotEntity = ModelEntity(mesh: sphereMesh, materials: [dotMaterial])
        
        self.addChild(dotEntity)
    }
        
}

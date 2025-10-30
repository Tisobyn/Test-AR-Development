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
    
    /// Size of the center dot (radius). Set to 0 to disable the dot.
    var centerDotSize: Float = 0.015
    
    /// Gap between the two half-circles in radians. Default is π/6 (30 degrees)
    var ringGap: Float = Float.pi / 6
    
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
        
        // Create circular ring
        createCircularRing()
    }
    
    private func createCircularRing() {
        // Create two half-circles with rounded ends and a configurable gap
        let outerRadius: Float = 0.08
        let innerRadius: Float = 0.07
        let ringThickness = outerRadius - innerRadius
        
        // Create the two half-circle arcs
        createHalfCircleArc(outerRadius: outerRadius, innerRadius: innerRadius, startAngle: ringGap/2, endAngle: Float.pi - ringGap/2)
        createHalfCircleArc(outerRadius: outerRadius, innerRadius: innerRadius, startAngle: Float.pi + ringGap/2, endAngle: 2*Float.pi - ringGap/2)
        
        // Add rounded ends (caps) at the arc endpoints
        addRoundedCaps(radius: (outerRadius + innerRadius) / 2, thickness: ringThickness)
        
        // Add center dot if configured
        if centerDotSize > 0 {
            addCenterDot()
        }
        
        print("CircularFocusEntity: Created split ring with gap \(ringGap) radians")
    }
    
    private func createHalfCircleArc(outerRadius: Float, innerRadius: Float, startAngle: Float, endAngle: Float) {
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
            material.color = .init(tint: UIColor.systemYellow)
            material.blending = .transparent(opacity: .init(floatLiteral: 0.9))
            
            // Create entity for this arc
            let arcEntity = ModelEntity(mesh: mesh, materials: [material])
            self.addChild(arcEntity)
            
        } catch {
            print("Failed to create arc: \(error)")
        }
    }
    
    private func addRoundedCaps(radius: Float, thickness: Float) {
        // Add small circular caps at the ends of each arc for rounded appearance
        let capRadius = thickness / 2
        
        // First arc end caps
        let firstArcStart = ringGap/2
        let firstArcEnd = Float.pi - ringGap/2
        
        addCircularCap(at: firstArcStart, radius: radius, capRadius: capRadius)
        addCircularCap(at: firstArcEnd, radius: radius, capRadius: capRadius)
        
        // Second arc end caps
        let secondArcStart = Float.pi + ringGap/2
        let secondArcEnd = 2*Float.pi - ringGap/2
        
        addCircularCap(at: secondArcStart, radius: radius, capRadius: capRadius)
        addCircularCap(at: secondArcEnd, radius: radius, capRadius: capRadius)
    }
    
    private func addCircularCap(at angle: Float, radius: Float, capRadius: Float) {
        // Create a small circular cap using a flattened sphere
        let sphereMesh = MeshResource.generateSphere(radius: capRadius)
        
        var material = UnlitMaterial()
        material.color = .init(tint: UIColor.systemYellow)
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
    
    private func createFallbackCircle() {
        // Simple fallback: create a circular plane
        let radius: Float = 0.075
        let plane = MeshResource.generatePlane(width: radius * 2, depth: radius * 2)
        
        var material = UnlitMaterial()
        material.color = .init(tint: UIColor.systemYellow.withAlphaComponent(0.8))
        material.blending = .transparent(opacity: .init(floatLiteral: 0.8))
        
        let circleEntity = ModelEntity(mesh: plane, materials: [material])
        
        self.addChild(circleEntity)
        
        // Add center dot if configured
        if centerDotSize > 0 {
            addCenterDot()
        }
        
        print("CircularFocusEntity: Using fallback circle")
    }
    
    private func addCenterDot() {
        // Try to use cylinder for a perfect circle (iOS 18+), fallback to rounded box
        let dotHeight: Float = 0.001
        
        if #available(iOS 18.0, *) {
            // Use cylinder for perfect circle
            let dotMesh = MeshResource.generateCylinder(height: dotHeight, radius: centerDotSize)
            
            var dotMaterial = UnlitMaterial()
            dotMaterial.color = .init(tint: UIColor.systemYellow)
            dotMaterial.blending = .opaque
            
            let dotEntity = ModelEntity(mesh: dotMesh, materials: [dotMaterial])
            dotEntity.position = SIMD3<Float>(0, 0.002, 0)
            
            self.addChild(dotEntity)
            print("CircularFocusEntity: Added cylinder center dot with radius \(centerDotSize)")
        } else {
            // Fallback for iOS 16: use sphere flattened by scale
            let sphereMesh = MeshResource.generateSphere(radius: centerDotSize)
            
            var dotMaterial = UnlitMaterial()
            dotMaterial.color = .init(tint: UIColor.systemYellow)
            dotMaterial.blending = .opaque
            
            let dotEntity = ModelEntity(mesh: sphereMesh, materials: [dotMaterial])
            
            // Flatten the sphere to make it look like a flat circle
            dotEntity.scale = SIMD3<Float>(1.0, 0.01, 1.0)
            dotEntity.position = SIMD3<Float>(0, 0.002, 0)
            
            self.addChild(dotEntity)
            print("CircularFocusEntity: Added flattened sphere center dot with radius \(centerDotSize)")
        }
    }
}

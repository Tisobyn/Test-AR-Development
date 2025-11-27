//
//  MeasuringLineNode.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 27.11.2025.
//


import Foundation
import ARKit

class MeasuringLineNode: SCNNode {
    
    let fontScale: Float = 0.004
    let textFlatness: CGFloat = 0.001
    var lineCylinderRadius: CGFloat = 0.0020
    let textExtrusionDepth: CGFloat = 0.03
    let textPlaneWidth: CGFloat = 0.020
    let textPlaneHeight: CGFloat = 0.010
    var font: UIFont = UIFont.systemFont(ofSize: 3)
    var planeNode = SCNNode()
    var nodeLine = SCNNode()
    var textNode = SCNNode()
    var scntext = SCNText()
    var nodeZAlign = SCNNode()
    var metricValue: Float = 0.0
    
    var vectorA: GLKVector3?
    var vectorB: GLKVector3?
    
    var text: String = ""
    var autoClosed: Bool = false
    var isHeight: Bool = false
    var lengthValue:CGFloat = 0.0
    
    init(startingVector vectorA: GLKVector3, endingVector vectorB: GLKVector3, text: String, isVertical: Bool, isOpening: Bool) {
        super.init()
        #warning("Remove it")
    }
    
    init(from: SCNNode, to: SCNNode, pov: SCNNode? = nil, isHeight: Bool = false, isTemp: Bool = false){
        super.init()
        
        let distance = from.position.distanceTo(to.position)
        self.text = distance.stringValue
        self.lengthValue = distance.floatValue
        self.isHeight = isHeight
        
        self.position = from.position
        
        nodeZAlign.eulerAngles.x = Float.pi/2
        
        let box = SCNCylinder(radius: 0.0010, height: distance.floatValue)
        let material = SCNMaterial()
        
        if isTemp {
            material.diffuse.contents = UIImage(named: "dash_img")!
            material.diffuse.wrapS = .repeat
            material.diffuse.wrapT = .repeat
            material.isDoubleSided = true
            material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(distance.floatValue) * 50 , 0.0010 * 50, 1)
            material.lightingModel = .constant//added
            
            let rotation = SCNMatrix4MakeRotation(.pi / 2, 0, 0, 1)
            material.diffuse.contentsTransform = SCNMatrix4Mult(rotation, material.diffuse.contentsTransform)
        }else{
            material.diffuse.contents = UIColor.white
        }
        
        box.materials = [material]
        
        nodeLine.geometry = box
        nodeLine.position.y = Float(-distance.floatValue/2)
        
        nodeLine.name = "CylinderLn"
        nodeZAlign.addChildNode(nodeLine)
        
        scntext.string = text
        scntext.extrusionDepth = textExtrusionDepth
        
        scntext.font = UIFont.systemFont(ofSize: 1.5)
        
        scntext.flatness = textFlatness
        
        textNode.geometry = scntext
        textNode.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        
        textNode.scale = SCNVector3(0.006, 0.006, 0.006)
        
        let (min, max) = (scntext.boundingBox.min, scntext.boundingBox.max)
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
        
        let plane = SCNPlane(width: textPlaneWidth, height: textPlaneHeight)
        plane.width = 0.040
        plane.height = 0.020
        plane.cornerRadius = 0.010
        
        planeNode.geometry = plane
        planeNode.name = "Capsule"
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        planeNode.geometry?.firstMaterial?.isDoubleSided = true
        
        textNode.name = "DistanceText_\(distance.floatValue)"
        
        planeNode.addChildNode(textNode)
        
        planeNode.position.y = Float(-distance.floatValue/2)
        
        nodeZAlign.categoryBitMask = 99//??
        
        var alignment: ARPlaneAnchor.Alignment?
        
        if let marker = to as? MarkerNode {
            alignment = marker.currentAlignment ?? .horizontal
        }
        if let focus = to as? FocusCursor {
            alignment = focus.currentAlignment
        }
        
        if to.position.x > from.position.x {
            //from first marker to right
            planeNode.eulerAngles.x = Float.pi
            planeNode.eulerAngles.z = -Float.pi/2
            planeNode.position.z = -0.001//-0.006
        }else{
            //from first marker to left
            planeNode.eulerAngles.x = -Float.pi
            planeNode.eulerAngles.z = Float.pi/2
            planeNode.position.z = -0.001//-0.006
        }
                
        if isHeight {
            let bill = SCNBillboardConstraint()
            bill.freeAxes = [.Y]
            planeNode.position.x = 0.003
            planeNode.constraints = [bill]
        }
        
        nodeZAlign.addChildNode(planeNode)
        self.addChildNode(nodeZAlign)
        
        let parametersNode = SCNNode()
        parametersNode.name = "MetricValue_\(distance.floatValue)"
        self.addChildNode(parametersNode)
        
        let constraint = SCNLookAtConstraint(target: to)
        constraint.isGimbalLockEnabled = true
        if alignment == .vertical {
            constraint.worldUp = SCNVector3Make(0, 0, 1)
        }
        self.constraints = [constraint]
    }
    
    override init() {
        super.init()
    }
    
    override public static var supportsSecureCoding: Bool{
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

//
//  MeasurementTool.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 30.10.2025.
//

import Foundation
import ARKit


enum MeasurementTool: Equatable {
    case length
    case ruler
    case lidarScanning
    case levelTool
    case horizontal
    case vertical
    case roomPlans(RoomPlanSubTool)
    
    static var supportsLidar: Bool {
        return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
    
    var planeDetectionMode: ARWorldTrackingConfiguration.PlaneDetection {
        switch self {
        case .horizontal:
            return [.horizontal]
        case .roomPlans, .lidarScanning, .length:
            return [.horizontal, .vertical]
        case .vertical:
            return [.vertical]
        case .levelTool, .ruler:
            return []
        }
    }
    
}

extension MeasurementTool {
    var id: String {
        switch self {
        case .length: return "LengthTool"
        case .ruler: return "Ruler"
        case .lidarScanning: return "Lidar"
        case .levelTool: return "LevelTool"
        case .horizontal: return "Horizontal"
        case .vertical: return "Vertical"
        case .roomPlans: return "RoomPlans"
        }
    }
    
    static var allCases: [MeasurementTool] {
        [.length, .vertical, .horizontal, .roomPlans(.none)]
    }
    
//    static var allCases: [MeasurementTool] {
//        let all: [MeasurementTool]
//
//        if RemoteConfigs.measurement_length.boolValue {
//            all =  [.ruler, .lidarScanning, .levelTool, .length, .roomPlans]
//        } else {
//            all =  [.ruler, .lidarScanning, .levelTool, .horizontal, .vertical, .roomPlans]
//        }
//
//        return all.filter {
//            ($0 != .lidarScanning || supportsLidar)
//        }
//    }
//
//    var icon: String {
//        "Measurement.Tool.\(id)"
//    }
//
//    var title: String {
//        "Home.\(id)".localized
//    }
//
//    var hasSubtools: Bool {
//        self == .roomPlans
//    }
    
//    var isLocked: Bool {
//        if AppState.shared.isSubscribed {
//            switch self {
//            default: return false
//            }
//        } else {
//            switch self {
//            case .lidarScanning:
//                return !UserDefaults.standard.isLidarFeaturePurchased
//            case .levelTool:
//                return !UserDefaults.standard.levelToolPurchased
//            case .horizontal, .vertical, .length: return false
//            default:
//                return true
//            }
//        }
//    }
    
}


enum RoomPlanSubTool: String, CaseIterable {
    case height = "Height"
    case door = "Door"
    case window = "Window"
    case none = ""
    
    static var viewableCases: [RoomPlanSubTool] = [.height, .door, .window]
    
//    var title: String {
//        switch self {
//        case .height: return "height".localized
//        case .door: return "Door".localized
//        case .window: return "Window".localized
//        case .none: return "None".localized
//        }
//    }
//    
//    var icon: String {
//        return "Measurement.Subtool.RoomPlans.\(self.rawValue)"
//    }
    
//    static var currentSubTool: RoomPlanSubTool = .none
    
}

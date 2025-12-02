//
//  StableMiniMap.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 02.12.2025.
//

import SwiftUI

struct StableMiniMap: View {
    @ObservedObject var lengthManager: LengthMeasureManager
    @State private var mapMode: MiniMapMode = .horizontal
    private let miniMapSize: CGFloat = 150
    
    var body: some View {
        VStack(spacing: 8) {
            // A. The Map
            MeasurementMiniMap(points: lengthManager.previewData, mode: $mapMode)
                .frame(width: miniMapSize, height: miniMapSize)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(radius: 5)
            
            Picker("View Mode", selection: $mapMode) {
                Image(systemName: "square.grid.2x2").tag(MiniMapMode.horizontal)
                Image(systemName: "rectangle.split.3x1").tag(MiniMapMode.vertical)
                Image(systemName: "cube").tag(MiniMapMode.threeD)
            }
            .pickerStyle(.segmented)
            .frame(width: miniMapSize)
            .background(.thinMaterial)
            .clipShape(Capsule()) // <--- Makes it a round "Clip" / Pill shape
            .shadow(radius: 3)
        }
    }
}


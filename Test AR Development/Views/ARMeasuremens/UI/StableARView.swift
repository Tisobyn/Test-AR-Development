//
//  StableARView.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 02.12.2025.
//

import SwiftUI

struct StableARView: View {
    let manager: LengthMeasureManager
    
    var body: some View {
        ARMeasurementView(manager: manager)
            .edgesIgnoringSafeArea(.all)
    }
}

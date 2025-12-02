// Файл: MeasurementView.swift (удаляем overlay с плюсом)

import SwiftUI
import RealityKit

struct MeasurementView: View {
    @StateObject private var lengthManager = LengthMeasureManager()
    
    var body: some View {
        ZStack {
            ARMeasurementView(manager: lengthManager)
                .ignoresSafeArea(.all)
            
            VStack {
                Text(lengthManager.message)
                    .foregroundStyle(.red)
                Text(lengthManager.status)
                    .foregroundStyle(.yellow)
                Spacer()
            }
            
            MeasurementActions(lengthManager: lengthManager)
        
        }
       
    }
}

// Файл: MeasurementView.swift (удаляем overlay с плюсом)

import SwiftUI
import RealityKit

struct MeasurementView: View {
    @StateObject private var lengthManager = LengthMeasureManager()
    
    var body: some View {
        ZStack {
            StableARView(manager: lengthManager)

            
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(lengthManager.message)
                            .font(.caption)
                            .padding(8)
                            .background(.thinMaterial)
                            .cornerRadius(8)
                        Text(lengthManager.status)
                            .font(.caption)
                            .padding(8)
                            .background(.thinMaterial)
                            .cornerRadius(8)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    StableMiniMap(lengthManager: lengthManager)
                }
                
                Spacer()
            }
            
            MeasurementActions(lengthManager: lengthManager)
        
        }
       
    }
}

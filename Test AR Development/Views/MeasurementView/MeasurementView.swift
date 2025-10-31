// Файл: MeasurementView.swift (удаляем overlay с плюсом)

import SwiftUI
import RealityKit

struct MeasurementView: View {
    @StateObject private var viewModel = MeasurementViewModel()
    @StateObject private var lengthManager = LengthMeasureManager()
    
    var body: some View {
        ZStack {
            ARMeasurementView(manager: lengthManager)
                .ignoresSafeArea(.all)
            
            VStack {
                Text("State")
                    .foregroundStyle(.red)
                
                Spacer()
            }
            
            
            VStack {
                Spacer()
                Button {
                    lengthManager.addPoint()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
                .padding(.bottom, 30)

            }
        }
       
    }
}

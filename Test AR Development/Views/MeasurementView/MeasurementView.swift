// Файл: MeasurementView.swift (удаляем overlay с плюсом)

import SwiftUI
import RealityKit

struct MeasurementView: View {
    @StateObject private var viewModel = MeasurementViewModel()
    @StateObject private var lengthManager = LengthMeasureManager()
    
    var body: some View {
        ZStack {
            VStack {
                Text("Is Loading")
                    .foregroundStyle(.red)
            }
            
            ARMeasurementView(manager: lengthManager)
                .ignoresSafeArea(.all)
            
            VStack {
                Spacer()
                Button {
                    
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

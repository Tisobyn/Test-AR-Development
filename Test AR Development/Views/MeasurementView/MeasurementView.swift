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
                Text(lengthManager.message)
                    .foregroundStyle(.red)
                Text(lengthManager.status)
                    .foregroundStyle(.yellow)
                Spacer()
            }
            
            
            VStack {
                Spacer()
                
                
                Button {
                    lengthManager.addPointTapped()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
                
                HStack(alignment: .center) {
                    
                    Spacer()
                    Button {
                        lengthManager.cutMeasurement()
                    } label: {
                        Image(systemName: "scissors")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    
                    
//                    Menu {
//                        ForEach(MeasurementTool.allCases, id: \.self) { tool in
//                            Button {
//                                lengthManager.changeSelectedTool(tool)
//                            } label: {
//                                Label(tool.rawValue, systemImage: "checkmark")
//                            }
//                        }
//                    } label: {
//                        Image(systemName: "wrench.and.screwdriver")
//                            .font(.system(size: 24, weight: .bold))
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(Color.blue)
//                            .clipShape(Circle())
//                            .shadow(radius: 10)
//                    }
                    Spacer()
                    
                    Button {
                        lengthManager.undoLastPointAndLine()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 30)

            }
        }
       
    }
}

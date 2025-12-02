//
//  MeasurementActions.swift
//  Test AR Development
//
//  Created by Yermek Sabyrzhan on 02.12.2025.
//

import SwiftUI

struct MeasurementActions: View {
    @ObservedObject var lengthManager: LengthMeasureManager
    
    @State private var showToolsPopover = false
    
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    lengthManager.cutMeasurement()
                } label: {
                    Image(systemName: "scissors")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.35)) // transparent black/gray
                        .clipShape(Circle())
                        .shadow(radius: 6)
                }
                
                Button {
                    lengthManager.reset()
                } label: {
                    Image(systemName: "gobackward") // reset icon
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.35)) // transparent black/gray
                        .clipShape(Circle())
                        .shadow(radius: 6)
                }
                
                Button {
                    lengthManager.undoLastPointAndLine()
                } label: {
                    Image(systemName: "arrow.uturn.left") // undo icon
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.35)) // transparent black/gray
                        .clipShape(Circle())
                        .shadow(radius: 6)
                }

                Button {
                    showToolsPopover.toggle()
                } label: {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.35)) // transparent black/gray
                        .clipShape(Circle())
                        .shadow(radius: 6)
                }
                .popover(isPresented: $showToolsPopover) {
                    VStack(spacing: 8) {
                        ForEach(MeasurementTool.allCases, id: \.id) { tool in
                            Button {
                                lengthManager.changeSelectedTool(tool)
                                showToolsPopover = false
                            } label: {
                                HStack {
                                    Text(tool.id)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(lengthManager.selectedTool == tool ? .white : .primary)
                                    Spacer()
                                    if lengthManager.selectedTool == tool {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    lengthManager.selectedTool == tool
                                    ? Color.blue
                                    : Color.gray.opacity(0.2)
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(16)
                }
            }
            
            Button {
                lengthManager.addPointTapped()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 52, height: 52)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                }
                .shadow(radius: 10)
            }
            
        }
        .padding(.bottom, 24)
    }
}

//
//  CircularButton.swift
//  NailGuard
//
//  Created by Rick Cheng on 2/3/26.
//
import SwiftUI

struct CircularButton: View {
    let action: () -> Void
    let backgroundColor: Color
    let centerColor: Color
    
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: {
            action()
        }) {
            Circle()
                .stroke(
                    backgroundColor,
                    lineWidth: 12
                )
                .frame(width: 180, height: 180)
                .overlay(
                    Circle()
                        .fill(centerColor)
                        .frame(width: 150, height: 150)
                        .overlay(
                            Text("+1")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                        )
                )
                .shadow(color: .pink.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
    }
}
#Preview {
    CircularButton(action: {print("Tapped button")}, backgroundColor: .blue, centerColor: .red)
}

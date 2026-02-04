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
    let frameSize: Float
    
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: {
            action()
        }) {
            Circle()
                .stroke(
                    backgroundColor,
                    lineWidth: 20
                )
                .overlay(
                    Circle()
                        .fill(centerColor)
                        .overlay(
                            Text("+1")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                        )
                )
        }
        .frame(maxWidth:CGFloat(frameSize))
        .padding()
        .scaledToFill()
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
    }
}
#Preview {
    CircularButton(action: {print("Tapped button")}, backgroundColor: .blue, centerColor: .red, frameSize: 200)
}

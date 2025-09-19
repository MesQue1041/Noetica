//
//  DynamicTypeSupport.swift
//  Noetica
//
//  Created by Abdul Rahuman on 2025-09-19.
//

import SwiftUI

extension View {
    func dynamicTypeSize(_ size: DynamicTypeSize) -> some View {
        self.font(.system(size: dynamicFontSize(for: size)))
    }
    
    private func dynamicFontSize(for size: DynamicTypeSize) -> CGFloat {
        switch size {
        case .xSmall: return 12
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .xLarge: return 20
        case .xxLarge: return 24
        case .xxxLarge: return 28
        case .accessibility1: return 32
        case .accessibility2: return 36
        case .accessibility3: return 40
        case .accessibility4: return 44
        case .accessibility5: return 48
        @unknown default: return 16
        }
    }
}

struct AccessibleButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .frame(minWidth: 44, minHeight: 44)
    }
}

//
//  TextFieldStyle.swift
//  EmergencyChat
//
//  Created by Bintang Pradana on 16/01/24.
//

import SwiftUI

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(.primary)
    }
}

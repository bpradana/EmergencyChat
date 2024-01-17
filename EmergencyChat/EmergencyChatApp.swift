//
//  EmergencyChatApp.swift
//  EmergencyChat
//
//  Created by Bintang Pradana on 15/01/24.
//

import SwiftUI

@main
struct EmergencyChatApp: App {
    @ObservedObject private var model = Model()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}

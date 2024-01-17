//
//  ContentView.swift
//  EmergencyChat
//
//  Created by Bintang Pradana on 15/01/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: Model
    
    var body: some View {
        NavigationView {
            List {
                Section("Chats") {
                    if model.chats.isEmpty {
                        Text("No Chats")
                    } else {
                        ForEach(Array(model.chats), id:\.value.id) { id, chat in
                            NavigationLink {
                                ChatView(person: id)
                                    .navigationTitle(chat.person.name)
                            } label: {
                                Text(chat.peer.displayName)
                            }
                        }
                    }
                }
                Section("Peers") {
                    if model.connectedPeers.isEmpty {
                        Text("No Peers")
                    } else {
                        ForEach(model.connectedPeers, id:\.hash) { peer in
                            Text(peer.displayName)
                        }
                    }
                }
            }
        }
    }
}


//
//  ChatView.swift
//  EmergencyChat
//
//  Created by Bintang Pradana on 16/01/24.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var model: Model
    @State private var newMessage: String = ""
    
    let person: Person
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollView in
                VStack {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(model.chats[person]!.messages, id:\.id){ message in
                                ChatRow(message: message,geo:geometry)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .onChange(of: model.chats[person]!.messages) {
                        DispatchQueue.main.async {
                            if let last = model.chats[person]!.messages.last{
                                withAnimation(.spring()){
                                    scrollView.scrollTo(last.id)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Enter a message", text: $newMessage,axis: .vertical)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .animation(.spring())
                            .padding(.horizontal)
                        
                        if !newMessage.isEmpty {
                            Button {
                                if !newMessage.isEmpty {
                                    DispatchQueue.main.async {
                                        model.send(newMessage, chat: model.chats[person]!)
                                        newMessage = ""
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        if let last = model.chats[person]!.messages.last {
                                            print("Scrolling to last!")
                                            withAnimation(.spring()) {
                                                scrollView.scrollTo(last.id)
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .animation(.spring())
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

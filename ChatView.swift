//
//  SaraChatView.swift
//  iosApp
//
//  Created by Vamsi on 29/01/25.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI

//struct ChatView: View {
//    @StateObject private var viewModel = ChatViewModel()
//    @State private var userInput: String = ""
//
//    var body: some View {
//        VStack {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 10) {
//                    ForEach(viewModel.messages, id: \.id) { message in
//                        ChatBubble(text: message.text, isUser: message.isUser)
//                    }
//                }
//                .padding()
//            }
//
//            if !viewModel.suggestions.isEmpty {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack {
//                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
//                            Button(action: {
//                                viewModel.sendMessageToDialogflow(message: suggestion, completion: { response in
//                                    print(response)
//                                    
//                                })
//                            }) {
//                                Text(suggestion)
//                                    .padding()
//                                    .background(Color.blue)
//                                    .foregroundColor(.white)
//                                    .cornerRadius(10)
//                            }
//                        }
//                    }
//                    .padding()
//                }
//            }
//
//            HStack {
//                TextField("Type a message...", text: $userInput)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .frame(minHeight: 40)
//
//                Button(action: {
//                    let message = ChatMessage(text: userInput, isUser: true)
//                    viewModel.messages.append(message)
//                    viewModel.sendMessageToDialogflow(message: userInput, completion: {
//                        response in
//                            print(response)
//                    })
//                    userInput = ""
//                }) {
//                    Text("Send")
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//            }
//            .padding()
//        }
//    }
//}

struct ChatBubble: View {
    var text: String
    var isUser: Bool

    var body: some View {
        HStack {
            if isUser { Spacer() }
            Text(text)
                .padding()
                .background(isUser ? Color.green : Color.gray.opacity(0.2))
                .foregroundColor(isUser ? .white : .black)
                .cornerRadius(10)
                .frame(maxWidth: 250, alignment: isUser ? .trailing : .leading)
            if !isUser { Spacer() }
        }
    }
}

//struct ChatMessage: Identifiable {
//    let id = UUID()
//    let text: String
//    let isUser: Bool
//}
//

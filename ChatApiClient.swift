//
//  ChatApiClient.swift
//  iosApp
//
//  Created by Srushti Choudhari on 18/12/25.
//  Copyright © 2025 orgName. All rights reserved.
//

import Foundation

class ChatApiClient {
    static let shared = ChatApiClient()
    private init() {}
    
    private let endpoint = /*"https://cornerhop-adk-chatbot-377427581409.asia-south1.run.app/chat"*/ AppEnvironment.chatbotURL
    
    func sendMessage(
        message: String,
        sessionId: String,
        userId: String,
        cookie: String?,
        completion: @escaping (ChatbotResponseWrapper?) -> Void
    ) {
        let messageAndCookie = "\(message) \(cookie ?? "")"
        
        guard let url  = URL(string: endpoint) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "message": messageAndCookie,
            "session_id": sessionId,
            "user_id": userId,
            "cookie": cookie ?? ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("Sending request: ", body)
        } catch {
            print("JSON Error: ", error)
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Error: ", error)
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            print("Raw api response: ")
            print(String(decoding: data, as: UTF8.self))
            do {
                // 1) Parse top-level JSON
                let top = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                // 2) Extract `response` flexibly
                if let responseString = top?["response"] as? String {
                    let cleaned = responseString
                        .replacingOccurrences(of: "```json", with: "")
                        .replacingOccurrences(of: "```", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let innerData = cleaned.data(using: .utf8) {
                        let decoder = JSONDecoder()
                        let decoded = try decoder.decode(ChatbotResponseWrapper.self, from: innerData)
                        completion(decoded)
                        return
                    }
                }
             
            } catch {
                print("Decoding error:", error)
                print("RAW top-level:", String(decoding: data, as: UTF8.self))
            }
        }
        .resume()
    }
}

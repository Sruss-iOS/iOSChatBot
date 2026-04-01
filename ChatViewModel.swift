//
//  ChatViewModel.swift
//  iosApp
//
//  Created by Vamsi on 04/02/25.
//  Copyright © 2025 orgName. All rights reserved.
//

import Foundation
import Combine
import GoogleSignIn
import shared
import SwiftUI

//class ChatViewModel: ObservableObject {
//    @Published var messages: [ChatMessage] = []
//    @Published var suggestions: [String] = []
//    @Published var lastDetectedProductId: String?
//    @ObservedObject var viewmodel =  CSApiViewModel()
//    var sessionID: String = {
//        if let saved = UserDefaults.standard.string(forKey: "sessionID") {
//            return saved
//        }
//        let newID = "sessionID=\(UUID().uuidString)"
//        UserDefaults.standard.set(newID, forKey: "sessionID")
//        return newID
//    }()
//    
//    var currentSessionID: String = ""
//    var customerSessionID: String = {
//        if let saved = UserDefaults.standard.string(forKey: "customerSessionID") {
//            return saved
//        }
//        let new = "SESSION=\(UUID().uuidString)"
//        UserDefaults.standard.set(new, forKey: "customerSessionID")
//        return new
//    }()
//    let projectID = "cornershop-india"
//    let location = "us-central1"
//    let agentID = "d4ca83a0-7fab-4730-9bab-13fcaae31790"
//    
//    let customerName = UserDefaults.standard.string(forKey: "googlUsername") ?? "Guest"
//    let cookieForBot = CookieManager.shared.cookieValue
//    
//    func sendMessageToDialogflow(message: String, completion: @escaping ([[String: AnyObject]]) -> Void){
//        
//        DialogflowTokenManager.shared.getAccessToken { accessToken in
//            guard let accessToken = accessToken else {
//                print("❌ No valid Google access token found")
//                return
//            }
//            
//            let urlString = "https://\(self.location)-dialogflow.googleapis.com/v3/projects/\(self.projectID)/locations/\(self.location)/agents/\(self.agentID)/sessions/\(self.sessionID):detectIntent"
//            guard let url = URL(string: urlString) else {
//                print("❌ Invalid URL")
//                return
//            }
//
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//            
//            // Define session parameters
//            let sessionParameters: [String: Any] = [
//                "inStore": false,
//                "customerName": self.customerName,
//                "customerSessionId": self.customerSessionID
//            ]
//
//            let requestBody: [String: Any] = [
//                "queryInput": [
//                    "text": ["text": message],
//                    "languageCode": "en",
//                ],
//                "queryParams": [
//                    "timeZone": "America/Los_Angeles",
//                    "parameters": sessionParameters, // Pass session parameters
//                    "returnPartialResponses": false,
//                    "disableWebhook": false,
//                    "payload": [
//                        "source": "iOS",
//                        "platform": "MOBILE",
//                        "customerSessionId": self.customerSessionID
//                    ]
//                ]
//            ]
//
//            do {
//                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//            } catch {
//                print("❌ Error encoding JSON: \(error)")
//                return
//            }
//
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    print("❌ Error: \(error.localizedDescription)")
//                    return
//                }
//
//                guard let data = data else {
//                    print("❌ No response data")
//                    return
//                }
//
//                do {
//                    
//                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//            
//                    print("✅ Dialogflow Response: \(jsonResponse ?? [:])")
//                    
//                    if let queryResult = jsonResponse?["queryResult"] as? [String: AnyObject] {
//                        if let diagnosticInfo = queryResult["diagnosticInfo"] as? [String:AnyObject] {
//                            if let sessionIDNew = diagnosticInfo["Session Id"] as? String {
//                                self.currentSessionID = sessionIDNew
//                                
//                                if let responseMessages = queryResult["responseMessages"] as? [[String:AnyObject]] {
//                                    
//                                    var parsedResponses: [String] = []
//                                    
//                                    for response in responseMessages {
//                                        if let textObject = response["text"] as? [String:AnyObject],
//                                           let texts = textObject["text"] as? [String],
//                                           let firstText = texts.first {
//                                            parsedResponses.append(firstText)
//                                            for t in texts {
//                                                if t.lowercased().contains("Added your items to cart successfully, do you need something else?") {
//                                                    print("Bot confirmed cart addition")
//                                                    if let id = self.lastDetectedProductId {
//                                                        self.callAddToCartAPI(productId: id)
//                                                    }
//                                                }
//                                            }
//                                        }
//                                        
//                                        if let payload = response["payload"] as? [String:AnyObject],
//                                           let richContent = payload["richContent"] as? [[Any]] {
//                                            for itemArray in richContent {
//                                                for item in itemArray {
//                                                    if let itemDict = item as? [String: Any],
//                                                       let title = itemDict["title"] as? String {
//                                                        parsedResponses.append(title)
//                                                    }
//                                                }
//                                            }
//                                        }
//                                    }
//                                    print("Parsed Responses: \(parsedResponses)")
//                                    completion(responseMessages)
//                                }
//                                
//                            }
//                        }
//                    }
//            
//                    DispatchQueue.main.async {
//                        let botMessage = self.parseDialogflowResponse(jsonResponse)
//                        self.messages.append(botMessage)
//                    }
//                } catch {
//                    print("❌ Error parsing response: \(error)")
//                }
//            }
//            task.resume()
//        }
//
//    }
//    
//    func pollForResponse(message : String,sessionID: String, retryCount: Int = 0, maxRetries: Int = 5, completion: @escaping ([[String: AnyObject]]) -> Void){
//        
//        DialogflowTokenManager.shared.getAccessToken { accessToken in
//            guard let accessToken = accessToken else {
//                print("❌ No valid Google access token found")
//                return
//            }
//            
//            guard retryCount < maxRetries else {
//                print("❌ Maximum retry attempts reached. Stopping polling.")
//                return
//            }
//            
//            let urlString = "https://\(self.location)-dialogflow.googleapis.com/v3/projects/\(self.projectID)/locations/\(self.location)/agents/\(self.agentID)/sessions/\(self.currentSessionID):detectIntent"
//        
//
//            guard let url = URL(string: urlString) else { return }
//
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//            
//            // Define session parameters
//            let sessionParameters: [String: Any] = [
//                "inStore": false,
//                "customerName": "Mayur"
//            ]
//
//            let requestBody: [String: Any] = [
//                "queryInput": [
//                    "text": ["text": message],
//                    "languageCode": "en",
//                ],
//                "queryParams": [
//                    "timeZone": "America/Los_Angeles",
//                    "parameters": sessionParameters, // Pass session parameters
//                    "returnPartialResponses": false,
//                    "disableWebhook": false,
//                    "payload": [
//                        "source": "iOS",
//                        "platform": "MOBILE"
//                    ]
//                ]
//            ]
//            
//            do {
//                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//            } catch {
//                print("❌ Error encoding JSON: \(error)")
//                return
//            }
//            
//
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    print("❌ Polling error: \(error.localizedDescription)")
//                    self.retryPolling(message: message, sessionID: sessionID, retryCount: retryCount + 1, maxRetries: maxRetries, completion: {
//                        response in
//                        completion(response)
//                    })
//                    return
//                }
//
//                guard let data = data else {
//                    print("❌ No response data, retrying...")
//                    self.retryPolling(message: message, sessionID: sessionID, retryCount: retryCount + 1, maxRetries: maxRetries, completion: {
//                        response in
//                        completion(response)
//                    })
//                    return
//                }
//
//                do {
//                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//                    print("✅ Polled Response: \(jsonResponse ?? [:])")
//
//                    if let queryResult = jsonResponse?["queryResult"] as? [String: AnyObject] {
//                        if let diagnosticInfo = queryResult["diagnosticInfo"] as? [String:AnyObject] {
//                            if let sessionIDNew = diagnosticInfo["Session Id"] as? String {
//                                self.currentSessionID = sessionIDNew
//                                
//                                if let responseMessages = queryResult["responseMessages"] as? [[String:AnyObject]] {
//                                    if responseMessages.count > 0 {
//                                        if let responcetext = responseMessages[0]["text"] as? [String:AnyObject] {
//                                            if let responceFinalArray = responcetext["text"] as? [String] {
//                                                if responceFinalArray.count > 0 {
//                                                    if responceFinalArray[0] == "How can I help you today?" {
//                                                    }
//                                                    else
//                                                    {
//                                                        completion(responseMessages)
//                                                        return
//                                                    }
//                                                }
//                                                
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//
//                } catch {
//                    print("❌ Error parsing response: \(error), retrying...")
//                    self.retryPolling(message: message, sessionID: sessionID, retryCount: retryCount + 1, maxRetries: maxRetries, completion:{
//                        response in
//                        completion(response)
//                    })
//                }
//            }
//            task.resume()
//        }
//    }
//
//    private func retryPolling(message: String, sessionID: String, retryCount: Int, maxRetries: Int, completion: @escaping ([[String: AnyObject]]) -> Void) {
//        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) { // ⏳ Wait 5 seconds before retrying
//            self.pollForResponse(message: message, sessionID: sessionID, retryCount: retryCount, maxRetries: maxRetries, completion: { response in
//                completion(response)
//                
//            })
//        }
//    }
//
//
//    
//    
//
//    private func parseDialogflowResponse(_ response: [String: Any]?) -> ChatMessage {
//        guard let queryResult = response?["queryResult"] as? [String: Any] else {
//            return ChatMessage(text: "Error: No response from Dialogflow", isUser: false)
//        }
//
//        let textResponse = queryResult["fulfillmentText"] as? String ?? "No response"
//
//        var suggestedReplies: [String] = []
//        if let responseMessages = queryResult["fulfillmentMessages"] as? [[String: Any]] {
//            for message in responseMessages {
//                if let quickReplies = message["quickReplies"] as? [String: Any],
//                   let suggestions = quickReplies["quickReplies"] as? [String] {
//                    suggestedReplies.append(contentsOf: suggestions)
//                }
//            }
//        }
//
//        DispatchQueue.main.async {
//            self.suggestions = suggestedReplies // Update UI with suggestions
//        }
//
//        return ChatMessage(text: textResponse, isUser: false)
//    }
//    
//    func callAddToCartAPI(productId: String) {
//        print("Calling Add to Cart API:", productId)
//        let cartList = ProductsToCartRequest(quantity: KotlinInt(int: Int32(1)), productId: productId, variantId: 1, offerPrice: viewmodel.productDetails?.discountedPrice ?? 0)
//        viewmodel.requestViewCart(addtocartrequest: [cartList]) { result in
//            print("Added to Cart \(productId)")
//        }
//    }
//    
//    
//    //ADK
//    func sendMessageToADK(message: String, completion: @escaping (ChatbotResponseWrapper) -> Void) {
//        let urlString = "https://cornerhop-adk-chatbot-377427581409.asia-south1.run.app/chat"
//        guard let url = URL(string: urlString) else { return }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let body: [String: Any] = [
//            "message": message,
//            "session_id": sessionID,
//            "user_id": customerName,
//            "cookie": cookieForBot!
//        ]
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
//        } catch {
//            print("JSON Error: ", error)
//            return
//        }
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            
//            if let error = error {
//                print("Error: ", error)
//                return
//            }
//            guard let data = data else { return }
//            
//            do {
//                let decoded = try JSONDecoder().decode(ChatbotResponseWrapper.self, from: data)
//                DispatchQueue.main.async {
//                    completion(decoded)
//                }
//            } catch {
//                print("Decoding error: ",error)
//                print(String(decoding: data, as: UTF8.self))
//            }
//        }
//        .resume()
//    }
//}
//
struct ChatbotResponseWrapper: Codable {
    let message: String
    let productList: [ChatbotProduct]?
    let status: String?
    let followUp: String?
    let gifUrl: String?
    let route: RouteResponse?
    
    enum CodingKeys: String, CodingKey {
        case message
        case productList
        case status
        case followUp = "follow_up"
        case gifUrl = "gif_url"
        case route
    }
}

struct ChatbotProduct: Codable, Identifiable {
    let name: String
    let id: String
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case id
        case imageUrl = "image_url"
    }
}


//Srushti in ADK way
class ChatViewModel: ObservableObject {
    @Published var chatHistory: [ChatMessage] = []
    var hasSentInitialMessage = false
    
    let sessionId = UUID().uuidString
    let userId = SessionManager.shared.getUserId() ?? "Guest"
    let cookie = CookieManager.shared.cookieValue
    
    func sendMessage(_ text: String) {
        //User Message
        chatHistory.append(
            ChatMessage(message: text,
                        isUser: true,
                        sentTime: currentTime(),
                        productList: nil,
                        followUp: nil,
                        gifUrl: nil,
                        route: nil
                       )
        )
        
        ChatApiClient.shared.sendMessage(message: text,
                                         sessionId: sessionId,
                                         userId: userId,
                                         cookie: cookie) { [weak self] response in
            guard let self, let response else { return }
            
            //bot message
            self.chatHistory.append(
                ChatMessage(message: response.message,
                            isUser: false,
                            sentTime: currentTime(),
                            productList: response.productList,
                            followUp: response.followUp,
                            gifUrl: response.gifUrl,
                            route: response.route
                           )
            )
            
            //success -> cart refresh
            if response.status?.lowercased() == "success" {
                print("Cart should refresh now")
            }
        }
    }
    
    private func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: Date()).uppercased()
    }
}

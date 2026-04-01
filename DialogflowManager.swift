//
//  Untitled.swift
//  iosApp
//
//  Created by Vamsi on 04/02/25.
//  Copyright © 2025 orgName. All rights reserved.
//
import Foundation
import GoogleAPIClientForREST
import SwiftJWT


class DialogflowManager {
    static let shared = DialogflowManager()
    private var accessToken: String?
    private var tokenExpiration: Date?
    
    private init() {}
    
    func sendMessage(message: String) {
        ensureAccessToken { token in
            guard let token = token else {
                print("❌ Failed to get a valid access token")
                return
            }
            self.sendRequest(message: message, accessToken: token)
        }
    }
    
    private func ensureAccessToken(completion: @escaping (String?) -> Void) {
        if let token = accessToken, let expiration = tokenExpiration, expiration > Date() {
            completion(token)
            return
        }
        generateAccessToken(completion: completion)
    }
    
    private func generateAccessToken(completion: @escaping (String?) -> Void) {
        guard let filePath = Bundle.main.path(forResource: "service_account", ofType: "json") else {
            print("❌ Service account JSON file not found.")
            completion(nil)
            return
        }
        
        do {
            let credentialsData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let credentials = try JSONSerialization.jsonObject(with: credentialsData, options: []) as? [String: Any]
            
            guard let privateKey = credentials?["private_key"] as? String,
                  let clientEmail = credentials?["client_email"] as? String else {
                print("❌ Invalid JSON format")
                completion(nil)
                return
            }
            
            let jwt = JWTGenerator.generateJWT(clientEmail: clientEmail, privateKey: privateKey)
            JWTGenerator.exchangeJWTForAccessToken(jwt: jwt) { token, expiration in
                self.accessToken = token
                self.tokenExpiration = expiration
                completion(token)
            }
        } catch {
            print("❌ Error reading service account JSON: \(error)")
            completion(nil)
        }
    }
    
    private func sendRequest(message: String, accessToken: String) {
        let sessionID = UserDefaults.standard.string(forKey: "sessionID") // user id
        let projectID = "cornershop-india"
        let location = "us-central1"
        let agentID = "d4ca83a0-7fab-4730-9bab-13fcaae31790"
        
        let urlString = "https://\(location)-dialogflow.googleapis.com/v3/projects/\(projectID)/locations/\(location)/agents/\(agentID)/sessions/\(sessionID):detectIntent"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("inStore", forHTTPHeaderField: "true")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "queryInput": [
                "text": ["text": message],
                "languageCode": "en"
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("❌ Error encoding JSON: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("❌ No response data")
                return
            }
            
            do {
                
                print("✅ Dialogflow Response: \(data)")
                
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
               // print("✅ Dialogflow Response: \(jsonResponse)")
            } catch {
                print("❌ Error parsing response: \(error)")
            }
        }
        task.resume()
    }
}

class JWTGenerator {
    static func generateJWT(clientEmail: String, privateKey: String) -> String {
        let now = Date()
        let expiration = now.addingTimeInterval(3600) // Token valid for 1 hour
        
        let claims = GoogleJWTClaims(
            iss: clientEmail,
            scope: "https://www.googleapis.com/auth/cloud-platform",
            aud: "https://oauth2.googleapis.com/token",
            exp: expiration,
            iat: now
        )
        
        var jwt = JWT(claims: claims)
        let privateKeyData = Data(privateKey.utf8)
        
        do {
            let jwtSigner = JWTSigner.rs256(privateKey: privateKeyData)
            return try jwt.sign(using: jwtSigner)
        } catch {
            print("❌ JWT Signing Failed: \(error)")
            return ""
        }
    }
    
    static func exchangeJWTForAccessToken(jwt: String, completion: @escaping (String?, Date?) -> Void) {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let requestBody = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"
        request.httpBody = requestBody.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Token Request Error: \(error.localizedDescription)")
                completion(nil, nil)
                return
            }
            
            guard let data = data else {
                print("❌ No response data")
                completion(nil, nil)
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = jsonResponse["access_token"] as? String,
                   let expiresIn = jsonResponse["expires_in"] as? Double {
                    completion(token, Date().addingTimeInterval(expiresIn))
                } else {
                    print("❌ Invalid response format")
                    completion(nil, nil)
                }
            } catch {
                print("❌ Error parsing JSON response: \(error)")
                completion(nil, nil)
            }
        }
        task.resume()
    }
}

struct GoogleJWTClaims: Claims {
    let iss: String // Issuer (Service Account Email)
    let scope: String
    let aud: String // Audience (Google Token URL)
    let exp: Date // Expiration Time
    let iat: Date // Issued At
}


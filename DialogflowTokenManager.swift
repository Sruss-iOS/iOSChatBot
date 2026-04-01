//
//  DialogflowTokenManager.swift
//  iosApp
//
//  Created by Vamsi on 04/02/25.
//  Copyright © 2025 orgName. All rights reserved.
//
import Foundation

class DialogflowTokenManager {
    static let shared = DialogflowTokenManager()
    private var accessToken: String?
    private var tokenExpiration: Date?

    private init() {}

    func getAccessToken(completion: @escaping (String?) -> Void) {
        // Check if the cached token is still valid
        if let token = accessToken, let expiration = tokenExpiration, expiration > Date() {
            completion(token)
            return
        }

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

            // Use a completion handler to fetch the token asynchronously
            JWTGenerator.exchangeJWTForAccessToken(jwt: jwt) { newToken,expiration  in
                DispatchQueue.main.async {
                    if let newToken = newToken {
                        self.accessToken = newToken
                        self.tokenExpiration = expiration
                        // Token valid for 1 hour
                        completion(newToken)
                    } else {
                        print("❌ Failed to retrieve access token.")
                        completion(nil)
                    }
                }
            }
        } catch {
            print("❌ Error reading service account JSON: \(error)")
            completion(nil)
        }
    }
}


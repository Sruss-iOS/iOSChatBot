//
//  ChatMessage.swift
//  iosApp
//
//  Created by Srushti Choudhari on 18/12/25.
//  Copyright © 2025 orgName. All rights reserved.
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let message: String
    let isUser: Bool
    let sentTime: String
    let productList: [ChatbotProduct]?
    let followUp: String?
    let gifUrl: String?
    let route: RouteResponse?
}

struct RouteResponse: Codable {
    let order: [String]
    let legs: [RouteLeg]
}

struct RouteLeg: Codable {
    let to: String
    let steps: [String]
}

struct UiRoute {
    let title: String
    let orderedDestinations: [String]
    let items: [UiRouteItem]
    let gifUrl: String?
}

struct UiRouteItem: Identifiable {
    let id = UUID()
    let index: Int
    let to: String
    let steps: [String]
    let isError: Bool
}

extension UiRoute {
    init(message: String, route: RouteResponse, gifUrl: String?) {
        self.title = message.isEmpty ? "Directions" : message
        self.orderedDestinations = route.order
        self.gifUrl = gifUrl
        
        self.items = route.legs.enumerated().map { index, leg in
            UiRouteItem(index: index + 1, to: leg.to, steps: leg.steps, isError: leg.steps.contains {
                $0.lowercased().contains("couldn't find the path")
            })
        }
    }
}

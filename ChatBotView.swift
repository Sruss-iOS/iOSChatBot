//
//  ChatBotView.swift
//  iosApp
//
//  Created by pratidnya on 11/02/25.
//  Copyright © 2025 orgName. All rights reserved.
//

import SwiftUI
import GoogleSignIn
import NukeUI
import UIKit
import ImageIO

struct ChatBotView: View {
    
    @State private var userInput: String = ""
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var messages: [(Bool, MessageType, Date)] = []
    @ObservedObject var viewmodel = CSApiViewModel()
    var currentFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, hh:mm a" // Example: "13 May, 09:25 AM"
        return formatter.string(from: Date())
    }
    
    @State private var isTyping: Bool = false
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isListening: Bool = false
    @State private var lastMessageID = UUID()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: SelectedProduct?
    @State var isShowDetailPage: Bool = false
    @FocusState private var isInputFocused: Bool
    
    init() {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()  // ✅ Ensures the bar has a visible background
            appearance.shadowColor = .gray  // ✅ Ensures the bottom separator (line) is visible

            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance  // ✅ Keeps the line even at scroll start
        }
    
    var body: some View {
        NavigationStack {
            
            if #available(iOS 17.0, *) {
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(messages.indices, id: \.self) { index in
                                    let (isUser, messageType, timestamp) = messages[index]
                                    let showAvatar = !isUser
                                    switch messageType {
                                    case .text(let text):
                                        Chatbubble(text: text, isUser: isUser, isTyping: isTyping, timestamp: timestamp, showAvatar: showAvatar)
                                            .id(index)
                                    case .button(let items):
                                        QuickReplyButton(texts: items, sendMessage: sendMessage)
                                    case .deal(let title, let imageName, let productId):
                                        DealCard(title: title, imageName: imageName)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                refreshCart()
                                                selectedProduct = SelectedProduct(id: productId)
                                            }
                                    case .route(let uiRoute):
                                        RouteWithGifView(ui: uiRoute)
                                            .padding(.top, 6)
                                    }
                                }
                                
                                if isTyping {
                                    TypingIndicator()
                                        .id(lastMessageID) // Ensure smooth scrolling when bot is typing
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) { _ in
                            withAnimation {
                                proxy.scrollTo(messages.count - 1, anchor: .bottom)
                            }
                        }
                    }
                    
                    // Input Bar
                    BottomButtonsView(messages: $messages, isInputFocused: $isInputFocused, sendUserMessage: sendUserMessage)
                    
                }
                .onAppear {
//                    if messages.isEmpty {
//                        //                    let name = UserDefaults.standard.string(forKey: "googlUsername") ?? "Guest"
//                        isTyping = true
//                        let initialMessage = "Hi"
//                        sendUserMessage(userMessage: initialMessage)
//                    }
                    if !chatViewModel.hasSentInitialMessage {
                        chatViewModel.hasSentInitialMessage = true
                        sendInitialBotMessage()
                        
                    }
                    refreshCart()
                }
                .navigationTitle("") // Keep nav bar visible
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(item: $selectedProduct) { product in
                    ProductDetailView(viewmodel: viewmodel, isLoading: true, productId: product.id, initialFavorite: false)
                    
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 2) {
                            Text("Sara")
                                .font(.custom("Ubuntu-Bold", size: 22))
                                .foregroundColor(.black)
                            
                            Text(currentFormattedDate)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
//    func sendUserMessage(userMessage: String) {
//        isTyping = true
//        lastMessageID = UUID()
//        
//        // Append user's message
//        messages.append((true, .text(userMessage), Date()))
//        
//        chatViewModel.sendMessageToDialogflow(message: userMessage) { response in
//            DispatchQueue.main.async {
//                for item in response {
//                    
//                    // ✅ Handle plain text responses
//                    if let textDict = item["text"] as? [String: Any],
//                       let texts = textDict["text"] as? [String] {
//                        for t in texts {
//                            self.messages.append((false, .text(t), Date()))
//                        }
//                    }
//                    
//                    // ✅ Handle rich content payload
//                    if let payload = item["payload"] as? [String: Any],
//                       let richContent = payload["richContent"] as? [[Any]] {
//                        for group in richContent {
//                            for entry in group {
//                                if let dict = entry as? [String: Any],
//                                   let type = dict["type"] as? String {
//                                    
//                                    switch type {
//                                    case "sentiment":
//                                        // Skip sentiment titles completely
//                                        break
//
//                                    case "chips", "button", "quick_replies":
//                                        if let options = dict["options"] as? [[String: Any]] {
//                                            let names = options.compactMap { $0["text"] as? String }
//                                            if !names.isEmpty {
//                                                self.messages.append((false, .button(names), Date()))
//                                            }
//                                        }
//
//                                    case "list", "card":
//                                        if let options = dict["options"] as? [[String: Any]] {
//                                            for opt in options {
//                                                
//                                                
//                                                var imageURL = ""
//                                                if let img = opt["imgUrl"] as? String {
//                                                    imageURL = img
//                                                    print(imageURL)
//                                                }
//                                                if let raw = (opt["image"] as? [String: Any])?["rawUrl"] as? String {
//                                                    imageURL = raw
//                                                    print(imageURL)
//                                                }
//                                                let title = opt["title"] as? String ?? ""
//                                                print(title)
//                                                let productId = opt["productID"] as? String ?? ""
//                                                print(productId)
//                                                chatViewModel.lastDetectedProductId = productId
//                                                if !title.isEmpty {
//                                                    self.messages.append((false, .deal(title: title, imageName: imageURL, productId: productId), Date()))
//                                                }
//                                            }
//                                        }
//
//                                    default:
//                                        break
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//                self.isTyping = false
//            }
//        }
//        
//        userInput = ""
//    }
    
    func sendUserMessage(userMessage: String) {
        isTyping = true
        lastMessageID = UUID()
        
        //append user messsage
        messages.append((true, .text(userMessage),Date()))
        
        //Call adk
        ChatApiClient.shared.sendMessage(message: userMessage,
                                         sessionId: chatViewModel.sessionId,
                                         userId: chatViewModel.userId,
                                         cookie: chatViewModel.cookie) { adkResponse in
            DispatchQueue.main.async {
                guard let adkResponse else {
                    self.messages.append((false, .text("Something went wrong."), Date()))
                    self.isTyping = false
                    return
                }
                
                // BOT text
                if !adkResponse.message.isEmpty {
                    self.messages.append((false, .text(adkResponse.message), Date()))
                }
                
                //Product list
                if let products = adkResponse.productList {
                    for product in products {
                        self.messages.append((
                            false,
                            .deal(
                                title: product.name,
                                imageName: product.imageUrl ?? "",
                                productId: product.id
                            ),
                            Date()
                        ))
                        
                    }
                }
                
                //GIF
                if let route = adkResponse.route {
                    let uiRoute = UiRoute(message: adkResponse.message, route: route, gifUrl: adkResponse.gifUrl)
                    self.messages.append((
                        false,
                        .route(uiRoute),
                        Date()
                    ))
                }
                
                if let followUpText = adkResponse.followUp, !followUpText.isEmpty {
                    self.messages.append((
                        false,
                        .text(followUpText),
                        Date()
                    ))
                }
                //status == success
                if adkResponse.status?.lowercased() == "success" {
                    print("success response received")
                    refreshCart()
                }
                
                self.isTyping = false
            }
        }
        userInput = ""
    }
    
    func sendInitialBotMessage() {
        isTyping = true
        lastMessageID = UUID()
        ChatApiClient.shared.sendMessage(message: "Hello", sessionId: chatViewModel.sessionId, userId: chatViewModel.userId, cookie: nil) { adkResponse in
            DispatchQueue.main.async {
                self.isTyping = false
                
                guard let adkResponse else {
                    self.messages.append((false, .text("Hello"), Date()))
                    return
                }
                
                self.messages.append((
                    false,
                    .text(adkResponse.message),
                    Date()
                ))
            }
        }
    }
    func sendMessage(_ text: String) {
        messages.append((true, .text(text), Date()))
        isTyping = true
        lastMessageID = UUID()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            lastMessageID = UUID()
            messages.append((false, .text("Looking for \(text)?"), Date()))
            isTyping = false
        }
    }
    
    func toggleListening() {
        if isListening {
            speechRecognizer.stopListening()
            userInput = speechRecognizer.recognizedText
        } else {
            speechRecognizer.startListening()
            userInput = ""
        }
        isListening.toggle()
    }
    
    func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo(lastMessageID, anchor: .bottom)
        }
    }
    
    func decodeDialogflow(_ data: Data) -> [DFMessage] {
        do {
            let decoded = try JSONDecoder().decode(DFResponse.self, from: data)
            return decoded.queryResult?.responseMessages ?? []
        } catch {
            print("JSON Decode Error:", error)
            return []
        }
    }
    
    func refreshCart() {
        viewmodel.getCart { success in
//                refreshTrigger.toggle()
            print("Cart loaded: \(success), count: \(viewmodel.cartProductList?.count ?? 0)")
        }
    }
}


//MARK: Enum for different message types
enum MessageType {
    case text(String)
    case button([String]) // Dictionary of options
//    case buttonWithImages([(String, String?)]) // new
    case deal(title: String, imageName: String, productId: String)
    case route(UiRoute)
}

// MARK: - Custom Rounded Corners
struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

//MARK: Chat Bubble View
struct Chatbubble: View {
    let text: String
    let isUser: Bool
    let isTyping: Bool
    let timestamp: Date
    let showAvatar: Bool
    
    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            HStack(alignment: .top) {
                if isUser { Spacer() } // Push user message to the right
                
                if !isUser { // Bot messages
                    if showAvatar { // ✅ Show only for first bot message in a sequence
                        Image("CS - Sara") // Bot avatar
                            .resizable()
                            .frame(width: 27, height: 27)
                    } else {
                        Spacer().frame(width: 35) // Keeps alignment even when avatar is hidden
                    }
                }
                
                Text(text)
                    .padding(10)
                    .font(.custom("Ubuntu-Regular", size: 14))
                    .background(isUser ? Color(red: 0/255, green: 87/255, blue: 171/255) : Color(hex: 0xf3f3f3))
                    .foregroundColor(isUser ? .white : .black)
                    .clipShape(RoundedCorners(
                        radius: 5,
                        corners: isUser ? [.topLeft, .topRight, .bottomLeft] : [.bottomLeft, .bottomRight, .topRight]
                    ))
                    .shadow(color: Color.gray.opacity(0.5), radius: 3, x: 2, y: 2)
                
                if !isUser { Spacer() } // Push bot message to the left
            }
            
            // ✅ Correct timestamp alignment
            HStack {
                if isUser { Spacer() } // Align timestamp to the right for user
                
                Text(formatTimestamp(timestamp))
                    .font(.custom("Ubuntu-Regular", size: 10))
                    .foregroundColor(.gray)
                
                if !isUser { Spacer() } // Align timestamp to the left for bot
            }
        }
        .padding(.horizontal, 5)
    }
    
    // MARK: - Date Formatting Function
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a" // Example: "10:45 AM"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, \(date.formatted(date: .omitted, time: .shortened))"
        } else {
            formatter.dateFormat = "MMM d, yyyy h:mm a" // Example: "Feb 10, 2025, 9:30 PM"
        }
        
        return formatter.string(from: date)
    }
}

//MARK: Quick Reply Button View
struct QuickReplyButton: View {
    let texts: [String]
    let sendMessage: (String) -> Void
    
    var body: some View {
        FlowLayout{
            ForEach(texts, id: \.self) { item in
                HStack{
                    Button(action: {
                        sendMessage(item)
                    }, label: {
                        Text(item)
                            .font(.custom("Ubuntu-Regular", size: 14))
                            .padding(.horizontal, 16) // Adds spacing inside the button
                            .padding(.vertical, 10)
                            .background(Color(red: 0/255, green: 87/255, blue: 171/255))
                            .foregroundColor(.black)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: 0x00BCAB).opacity(0.5), lineWidth: 1)
                            )
                            .fixedSize(horizontal: true, vertical: false)
                    })
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
            }
        }
    }
}

//MARK: Deal Card View

struct DealCard: View {
    let title: String
    let imageName: String
    
    var body: some View {
        HStack {
            if let url = URL(string: imageName), imageName.lowercased().hasPrefix("http") {
                
                AsyncImage(url: URL(string: imageName)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView() // Loading indicator
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "photo") // Fallback image
                            .frame(width: 50, height: 50)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.custom("Ubuntu-Medium", size: 14))
                    .bold()
            }
            
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .frame(width: 200)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.25)
                        .stroke(Color(red: 0/255, green: 87/255, blue: 171/255) , lineWidth: 0.8)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 2, y: 2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
        )
    }
}


//MARK: Typing Indicator Animation
struct TypingIndicator: View {
    @State private var showDot1 = false
    @State private var showDot2 = false
    @State private var showDot3 = false
    
    var body: some View {
        HStack {
            Image("CS - Sara") // Bot avatar
                .resizable()
                .frame(width: 27, height: 27)
            
            Circle()
                .frame(width: 4, height: 4)
                .foregroundColor(.gray)
                .opacity(showDot1 ? 1 : 0.3)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever(), value: showDot1)
            
            Circle()
                .frame(width: 4, height: 4)
                .foregroundColor(.gray)
                .opacity(showDot2 ? 1 : 0.3)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.2), value: showDot2)
            
            Circle()
                .frame(width: 4, height: 4)
                .foregroundColor(.gray)
                .opacity(showDot3 ? 1 : 0.3)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.4), value: showDot3)
        }
        .onAppear {
            showDot1 = true
            showDot2 = true
            showDot3 = true
        }
    }
}

//MARK: flowlayout

struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        let maxWidth = proposal.width ?? .infinity

        for size in sizes {
            if lineWidth + size.width > maxWidth { // Wrap to next line
                totalHeight += lineHeight + verticalSpacing
                totalWidth = max(totalWidth, lineWidth)
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width + horizontalSpacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        
        totalHeight += lineHeight
        totalWidth = max(totalWidth, lineWidth)
        
        return CGSize(width: totalWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0
        
        let maxWidth = proposal.width ?? .infinity

        for index in subviews.indices {
            if lineX + sizes[index].width > maxWidth { // Move to next line
                lineY += lineHeight + verticalSpacing
                lineX = bounds.minX
                lineHeight = 0
            }
            
            subviews[index].place(
                at: CGPoint(x: lineX, y: lineY),
                anchor: .topLeading,
                proposal: ProposedViewSize(sizes[index])
            )
            
            lineHeight = max(lineHeight, sizes[index].height)
            lineX += sizes[index].width + horizontalSpacing
        }
    }
}


struct ChatBotView_Previews: PreviewProvider {
    static var previews: some View {
        ChatBotView()
    }
}

//Chat model
struct DFResponse: Codable {
    let queryResult: DFQueryResult?
}

struct DFQueryResult: Codable {
    let responseMessages: [DFMessage]?
}

struct DFMessage: Codable {
    let text: TextContent?
    let payload: PayloadContent?
}

struct ResponseItem1: Codable {
    let text: TextContent?
    let responseType: String?
    let payload: PayloadContent?
}

struct TextContent: Codable {
    let text: [String]?
}

struct PayloadContent: Codable {
    let richContent: [[RichContentItem]]?
}

struct RichContentItem: Codable {
    let title: String?
    let type: String?
    let options: [OptionItem]?
}

struct ImageItem: Codable {
    let rawUrl: String?
}

struct OptionItem: Codable {
    
    let image: ImageItem?
    let text: String?
    let title: String?
    let imgUrl: String?
    let price: Double?
    let productID: String?


    enum CodingKeys: String, CodingKey {
        case image, text, title, price, productID, imgUrl
    }
    
////    init(from decoder: Decoder) throws {
////        let container = try decoder.container(keyedBy: CodingKeys.self)
////        text = try container.decode(String.self, forKey: .text)
////        image = try? container.decode(ImageItem.self, forKey: .image)  // <-- Use `try?` to ignore missing keys
////        title = try? container.decode(String.self, forKey: .title)
////        price = try? container.decode(Double.self, forKey: .price)
////        productID = try? container.decode(String.self, forKey: .productID)
////        imgUrl = try? container.decode(String.self, forKey: .imgUrl)
////    }
}


struct IconButtonView: View {
    let systemName: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName)
//                .font(.system(size: 24))
//                .foregroundColor(.white)
//                .frame(width: 44, height: 44)
//                .background(Color(hex: 0x0070ad)) // Custom Blue Color, changed from Teal to Blue by Sudipa
//                .clipShape(Circle())
//                .shadow(radius: 2)
        }
    }
}

struct BottomButtonsView: View {
    @State private var isListening = false
    @State private var scaleEffect: CGFloat = 1.0
    @State private var text = "Tap to Speak"
    @State private var recognizedSpeech: String = ""
    @State private var isChatVisible = false
    @Binding var messages: [(Bool, MessageType, Date)]
    @StateObject var speechRecognizer = SpeechRecognizer()
    @FocusState.Binding var isInputFocused: Bool
    
    var sendUserMessage: (String) -> Void
    
    var body: some View {
        VStack {
            if !isChatVisible {
                if isListening {
                    Text("Speak: \"\(speechRecognizer.recognizedText)\"")
                        .font(.system(size: 14, weight: .medium))
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 3)
                        .transition(.opacity)
                }
                
                HStack(spacing: 30) {
                    IconButtonView(systemName: "iPhone 11 Pro Max - 3") {
                        print("Attachment tapped")
                    }
                    
                    ZStack {
                        if isListening {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .stroke(Color.teal.opacity(Double(1 - index) * 0.3), lineWidth: 20)
                                    .scaleEffect(0.5 + CGFloat(index) * 0.15)
                                    .animation(
                                        Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false),
                                        value: 0.5
                                    )
                            }
                        }
                        
                        IconButtonView(systemName: "iPhone 11 Pro Max - 1") {
                            withAnimation {
                                isListening.toggle()
                                if isListening {
                                    text = "Listening..."
                                    isInputFocused = false
                                    try? speechRecognizer.startListening()
                                    startAnimation()
                                    
                                } else {
                                    text = "Tap to Speak"
                                    speechRecognizer.stopListening()
                                }
                            }
                        }
                    }
                    
                    IconButtonView(systemName: "iPhone 11 Pro Max - 2") {
                        withAnimation {
                            isChatVisible.toggle()
                            
                            if !isChatVisible {
                                        isInputFocused = false             // ✅ hide keyboard when collapsing chat input
                                    }

                        }
                    }
                    
                }
                .padding()
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(), value: isChatVisible)
            }
            
            ChatInputView(isChatVisible: $isChatVisible, messages: $messages, sendUserMessage:
                            { text in
                                            sendUserMessage(text)
                                            isInputFocused = false          // ✅ dismiss after send
                                        },
                                        isInputFocused: $isInputFocused
)
        }
    }
    
    func startAnimation() {
        scaleEffect = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            scaleEffect = 1.0
        }
    }
}
//
struct ChatInputView: View {
    @Binding var isChatVisible: Bool
    @State private var message: String = ""
    @Binding var messages: [(Bool, MessageType, Date)]
    
    var sendUserMessage: (String) -> Void
    @FocusState.Binding var isInputFocused: Bool
    var body: some View {
        if isChatVisible {
            HStack {
                // Attachment Button
                IconButtonView(systemName: "iPhone 11 Pro Max - 3") {
                    print("Attachment tapped")
                }

                HStack(spacing: 0) {
                    // Chat Input Field
                    TextField("Type a message...", text: $message)
                        .padding(.horizontal, 12)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(25)
                        .padding(.leading, 10)
                        .focused($isInputFocused)
                    
                    // Send Button
                    Button(action: {
                        print("Message Sent: \(message)")
                        let trimmedText = message.trimmingCharacters(in: .whitespaces)
                        guard !trimmedText.isEmpty else { return }
//                        messages.append((true, .text(trimmedText), Date()))
                        sendUserMessage(trimmedText)
                        message = "" // Clear input after sending
                        isInputFocused = false
                    }) {
                        Image("CS - Send")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding(13)
                    }
                    .padding(.trailing, 10)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(radius: 2)

                // Microphone Button
                IconButtonView(systemName: "iPhone 11 Pro Max - 1") {
                    withAnimation {
                        isChatVisible.toggle()
                    }
                }
            }
            .padding(.horizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: isChatVisible)
        }
    }
}

struct SelectedProduct: Identifiable, Hashable {
    let id: String
}

//Srushti in ADK way
//struct ChatBotView: View {
//    @StateObject private var chatViewModel = ChatViewModel()
//    @State private var inputText: String = ""
//    @State private var isLoading = false
//    
//    var body: some View {
//        ZStack {
//            VStack {
//                
//                //MARK: -Chat List
//                ScrollViewReader { proxy in
//                    ScrollView {
//                        LazyVStack(alignment: .leading, spacing: 12) {
//                            ForEach($chatViewModel.chatHistory) { msg in
//                                VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 6) {
//                                    //Text Bubble
//                                    Text(msg.message)
//                                        .padding(12)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//}

struct GIFView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.loadGIF(from: url)
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

extension UIImageView {
    func loadGIF(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: url) else { return }
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }
            
            var images: [UIImage] = []
            var duration: Double = 0
            
            let count = CGImageSourceGetCount(source)
            
            for i in 0..<count {
                guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
                let frameDuration = UIImage.frameDuration(from: source, index: i)
                duration += frameDuration
                
                images.append(UIImage(cgImage: cgImage))
            }
            
            DispatchQueue.main.async {
                self.animationImages = images
                self.animationDuration = duration
                self.animationRepeatCount = 0
                self.startAnimating()
            }
        }
    }
    
}

extension UIImage {
    static func frameDuration(from source: CGImageSource, index: Int) -> Double {
        let defaultFrameDuration = 0.1
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] ,
              let gifInfo = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return defaultFrameDuration
        }
        
        if let delay = gifInfo[kCGImagePropertyGIFUnclampedDelayTime] as? Double {
            return delay
        }
        
        if let delay = gifInfo[kCGImagePropertyGIFDelayTime] as? Double {
            return delay
        }
        
        return defaultFrameDuration
    }
}

struct GifBubble: View {
    let gifUrl: String
    var body: some View {
        if let url = URL(string: gifUrl) {
            GIFView(url: url)
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct RouteBubbleView: View {
    let ui: UiRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            //route order
            if !ui.orderedDestinations.isEmpty {
                Text("Route order:")
                    .font(.headline)
                ForEach(ui.orderedDestinations.indices, id: \.self) { index in
                    Text("\(index + 1). \(ui.orderedDestinations[index])")
                        .font(.subheadline)
                }
            }
            
            Divider()
            
            //route steps
            if !ui.items.isEmpty {
                Text("Route steps:")
                    .font(.headline)
                
                ForEach(ui.items) { item in
                    RouteLegItemView(item: item)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: 260, alignment: .leading)
    }
}

struct RouteLegItemView: View {
    let item: UiRouteItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(item.index). \(item.to)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(item.isError ? .red: .primary)
                
                if item.isError {
                    Text("⚠️")
                }
            }
            
            ForEach(item.steps, id: \.self) { step in
                HStack(alignment: .top) {
                    Text(".")
                    Text(step)
                        .font(.footnote)
                }
            }
        }
    }
}

struct RouteWithGifView: View {
    let ui: UiRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RouteBubbleView(ui: ui)
            
            if let gifUrl = ui.gifUrl {
                GifBubble(gifUrl: gifUrl)
            }
        }
    }
}

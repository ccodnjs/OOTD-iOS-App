import SwiftUI

// [데이터 모델] 메시지 구조체
struct ChatMessage: Codable, Identifiable, Equatable {
    let message_id: Int
    let chat_id: Int
    let sender_id: Int
    let content: String
    let sent_at: String
    
    var id: Int { message_id }
}

struct ChatMessageView: View {
    // [외부에서 받는 데이터]
    let chatId: Int      // 채팅방 번호
    let myId: Int        // 내 아이디
    let otherId: Int     // 상대방 아이디 (화면 표시에 필요하면 사용)
    let itemTitle: String // 상단에 띄울 상품명
    
    // [상태 변수]
    @State private var messages: [ChatMessage] = [] // 대화 목록
    @State private var newMessageText: String = ""  // 입력창 텍스트
    @State private var timer: Timer? = nil          // 실시간 업데이트용 타이머
    
    // 키보드에 가려지지 않게 하기 위해 사용
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 메시지 리스트 영역
            ScrollViewReader { proxy in // 스크롤 위치 제어를 위해 Reader 사용
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(messages) { msg in
                            // 내가 보낸 건 오른쪽(파란색), 남이 보낸 건 왼쪽(회색)
                            MessageBubble(message: msg, isMine: msg.sender_id == myId)
                        }
                    }
                    .padding()
                }
                // 메시지가 추가되면(onChange) 자동으로 맨 아래로 스크롤
                .onChange(of: messages) { _ in
                    if let lastId = messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            .onTapGesture { isFocused = false } // 배경 누르면 키보드 내림
            
            // 2. 입력창 영역
            HStack {
                TextField("메세지 보내기...", text: $newMessageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                
                Button(action: { sendMessage() }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(newMessageText.isEmpty ? .gray : .blue)
                }
                .disabled(newMessageText.isEmpty)
            }
            .padding()
            .background(Color(uiColor: .systemGray6))
        }
        .navigationTitle(itemTitle) // 상단 타이틀에 상품명 표시
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 화면 들어오면 메시지 불러오기 시작 & 1초마다 갱신
            fetchMessages()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                fetchMessages()
            }
        }
        .onDisappear {
            // 화면 나가면 타이머 종료 (배터리 절약)
            timer?.invalidate()
            timer = nil
        }
    }
    
    // [메시지 말풍선 뷰]
    func MessageBubble(message: ChatMessage, isMine: Bool) -> some View {
        HStack {
            if isMine { Spacer() } // 내꺼면 왼쪽에 여백 -> 오른쪽 정렬
            
            VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .padding(12)
                    .background(isMine ? Color.blue : Color(uiColor: .systemGray5))
                    .foregroundColor(isMine ? .white : .black)
                    .cornerRadius(16)
                
                Text(getTimeShort(dateString: message.sent_at)) // 시간 표시 (예: 14:30)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isMine { Spacer() } // 남의 꺼면 오른쪽에 여백 -> 왼쪽 정렬
        }
    }
    
    // [API] 메시지 목록 가져오기
    func fetchMessages() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/get_chat_messages.php?chat_id=\(chatId)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
                    DispatchQueue.main.async {
                        // 기존 개수랑 다를 때만 업데이트 (깜빡임 방지용 간단 로직)
                        if self.messages.count != decoded.count {
                            self.messages = decoded
                        }
                    }
                }
            }
        }.resume()
    }
    
    // [API] 메시지 전송
    func sendMessage() {
        let content = newMessageText
        newMessageText = "" // 입력창 즉시 비우기
        
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/send_chat_message.php") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"
        let body = "chat_id=\(chatId)&sender_id=\(myId)&content=\(content)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            // 전송 성공 시 즉시 목록 갱신
            fetchMessages()
        }.resume()
    }
    
    // 시간 파싱 헬퍼 (2025-12-01 14:30:00 -> 14:30)
    func getTimeShort(dateString: String) -> String {
        let parts = dateString.components(separatedBy: " ")
        if parts.count > 1 {
            let timeParts = parts[1].components(separatedBy: ":") // 14:30:00
            if timeParts.count >= 2 {
                return "\(timeParts[0]):\(timeParts[1])"
            }
        }
        return ""
    }
}

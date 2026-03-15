import SwiftUI

// [데이터 모델] 채팅방 요약 정보
struct ChatRoom: Codable, Identifiable {
    let chat_id: Int
    let market_id: Int
    let item_title: String
    let image_url: String?
    let seller_id: Int
    let buyer_id: Int
    let last_message: String?
    let last_sent_at: String?
    
    var id: Int { chat_id }
}

struct ChattingView: View {
    // 내 아이디 가져오기
    @AppStorage("userID") private var userIdString: String = ""
    private var currentUserId: Int { Int(userIdString) ?? 0 }
    
    @State private var chatRooms: [ChatRoom] = []
    
    var body: some View {
        NavigationView {
            List(chatRooms) { room in
                // 목록 클릭 시 해당 채팅방(ChatMessageView)으로 이동
                NavigationLink(destination: ChatMessageView(
                    chatId: room.chat_id,
                    myId: currentUserId,
                    otherId: (currentUserId == room.seller_id) ? room.buyer_id : room.seller_id, // 상대방 ID 계산
                    itemTitle: room.item_title
                )) {
                    ChatRoomRow(room: room)
                }
            }
            .listStyle(.plain)
            .navigationTitle("채팅")
            .onAppear {
                fetchChatRooms()
            }
            .refreshable { // 당겨서 새로고침
                fetchChatRooms()
            }
        }
    }
    
    // [채팅방 목록 셀 디자인]
    func ChatRoomRow(room: ChatRoom) -> some View {
        HStack(spacing: 12) {
            // 상품 이미지 (작게)
            AsyncImage(url: URL(string: room.image_url ?? "")) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                // 상품명
                Text(room.item_title)
                    .font(.headline)
                    .lineLimit(1)
                
                // 마지막 메시지 내용
                Text(room.last_message ?? "대화 내용이 없습니다.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 마지막 메시지 시간 (날짜만 표시하거나 시간만 표시)
            Text(formatDate(room.last_sent_at))
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
    
    // [API] 내 채팅방 목록 가져오기
    func fetchChatRooms() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/get_my_chat_rooms.php?user_id=\(currentUserId)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([ChatRoom].self, from: data) {
                    DispatchQueue.main.async {
                        self.chatRooms = decoded
                    }
                }
            }
        }.resume()
    }
    
    // 날짜 포맷 헬퍼
    func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "" }
        // 간단하게 날짜 부분만 자르거나, 오늘이면 시간만 보여주는 로직 추가 가능
        return String(dateString.prefix(10)) // 2025-12-01만 표시
    }
}

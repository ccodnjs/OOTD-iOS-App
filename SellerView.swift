import SwiftUI

// MARK: - 내 상점 화면
struct SellerView: View {
    // [사용자 정보]
    @AppStorage("userID") private var userIdString: String = ""
    private var userId: Int { Int(userIdString) ?? 0 }
    
    // [상태 변수들]
    @State private var myItems: [MarketItem] = []
    @State private var isLoading = true
    @State private var userName: String = ""
    
    // [수정/삭제 관련]
    @State private var itemToEdit: MarketDetail? = nil
    @State private var showEditSheet = false
    @State private var itemToDelete: MarketItem? = nil
    @State private var showDeleteAlert = false
    @State private var alertMessage = ""
    
    // [그리드 레이아웃]
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. 상단 프로필 영역
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(Image(systemName: "person.fill").font(.largeTitle).foregroundColor(.gray))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(userName.isEmpty ? "사용자 \(userId)" : userName)
                            .font(.headline)
                        
                        Text("ID: \(userId)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // [버튼 영역]
                        HStack(spacing: 10) {
                            // (1) 관심 목록 버튼
                            NavigationLink(destination: WishlistView()) {
                                HStack {
                                    Image(systemName: "heart.fill").foregroundColor(.red)
                                    Text("관심 목록").font(.caption).foregroundColor(.black)
                                }
                                .padding(.vertical, 6).padding(.horizontal, 10)
                                .background(Color.gray.opacity(0.1)).cornerRadius(20)
                            }
                            
                            // (2) [추가됨] 구매 내역 버튼 -> PurchaseReviewView로 이동
                            NavigationLink(destination: PurchaseReviewView()) {
                                HStack {
                                    Image(systemName: "bag.fill").foregroundColor(.blue)
                                    Text("구매 내역").font(.caption).foregroundColor(.black)
                                }
                                .padding(.vertical, 6).padding(.horizontal, 10)
                                .background(Color.gray.opacity(0.1)).cornerRadius(20)
                            }
                        }
                    }
                    .padding(.leading, 10)
                    Spacer()
                }
                .padding()
                
                Divider()
                
                // 2. 내 판매 상품 리스트 (기존 로직 유지)
                if isLoading {
                    ProgressView().padding(.top, 50)
                } else if myItems.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "archivebox").font(.largeTitle).foregroundColor(.gray)
                        Text("등록된 상품이 없습니다.").foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 15) {
                        ForEach(myItems) { item in
                            // 상품 카드 + 메뉴 버튼 (기존 코드와 동일)
                            ZStack(alignment: .topTrailing) {
                                NavigationLink(destination: MarketItemDetailView(marketItemId: item.market_id)) {
                                    SellerItemCell(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Menu {
                                    Section("상태 변경") {
                                        Button("판매중으로 변경") { updateStatus(item, 0) }
                                        Button("예약중으로 변경") { updateStatus(item, 1) }
                                        Button("판매완료로 변경") { updateStatus(item, 2) }
                                    }
                                    Section("관리") {
                                        Button(action: { prepareEdit(item: item) }) {
                                            Label("수정", systemImage: "pencil")
                                        }
                                        Button(role: .destructive, action: {
                                            itemToDelete = item
                                            showDeleteAlert = true
                                        }) {
                                            Label("삭제", systemImage: "trash")
                                        }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.black.opacity(0.7))
                                        .background(Color.white.clipShape(Circle()))
                                        .padding(8)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("내 상점")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchMyItems()
            fetchUserName()
        }
        // [수정 시트]
        .sheet(isPresented: $showEditSheet) {
            if let detail = itemToEdit {
                EditPostView(item: detail, isPresented: $showEditSheet, onUpdate: { fetchMyItems() })
            }
        }
        // [삭제 알림]
        .alert("상품 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                if let item = itemToDelete { deletePost(item: item) }
            }
        } message: {
            Text("정말 이 상품을 삭제하시겠습니까?")
        }
    }
    
    // MARK: - Helper Functions (기존 유지)
    
    func fetchUserName() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/get_user_info.php?user_id=\(userId)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String, status == "success",
               let name = json["name"] as? String {
                DispatchQueue.main.async { self.userName = name }
            }
        }.resume()
    }
    
    func prepareEdit(item: MarketItem) {
        self.itemToEdit = MarketDetail(
            market_id: item.market_id,
            seller_id: item.seller_id ?? userId,
            title: item.title,
            description: item.description ?? "",
            price: item.price,
            image_url: item.imageUrl,
            created_at: item.created_at ?? "",
            main_category: item.main_category,
            like_count: 0, is_liked: false, status: item.status ?? 0
        )
        self.showEditSheet = true
    }
    
    func fetchMyItems() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/get_seller_items.php?user_id=\(userId)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let items = try? JSONDecoder().decode([MarketItem].self, from: data) {
                DispatchQueue.main.async { self.myItems = items; self.isLoading = false }
            }
        }.resume()
    }
    
    func updateStatus(_ item: MarketItem, _ newStatus: Int) {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/update_market_status.php") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"
        let body = "market_id=\(item.market_id)&status=\(newStatus)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                if let index = myItems.firstIndex(where: { $0.market_id == item.market_id }) {
                    let old = myItems[index]
                    let new = MarketItem(
                        market_id: old.market_id, title: old.title, brand: old.brand, price: old.price,
                        main_category: old.main_category, imageUrl: old.imageUrl, description: old.description,
                        seller_id: old.seller_id, status: newStatus, created_at: old.created_at
                    )
                    myItems[index] = new
                }
            }
        }.resume()
    }
    
    func deletePost(item: MarketItem) {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/delete_market.php") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"
        let body = "market_id=\(item.market_id)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String, status == "success" {
                DispatchQueue.main.async {
                    myItems.removeAll { $0.market_id == item.market_id }
                }
            }
        }.resume()
    }
}

// [셀 디자인]
struct SellerItemCell: View {
    let item: MarketItem
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(height: 120).clipped().cornerRadius(8)
            .overlay(
                Group {
                    if let status = item.status, status != 0 {
                        Color.black.opacity(0.6).cornerRadius(8)
                            .overlay(Text(status == 1 ? "예약중" : "판매완료").font(.caption).bold().foregroundColor(.white))
                    }
                }
            )
            Text(item.name).font(.caption).lineLimit(1).foregroundColor(.primary)
            Text("\(item.price)원").font(.caption).bold().foregroundColor(.primary)
        }
    }
}

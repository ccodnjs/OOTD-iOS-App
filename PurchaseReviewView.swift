import SwiftUI

// MARK: - 구매 내역 화면 (PurchaseReviewView)
struct PurchaseReviewView: View {
    
    // MARK: - 1. Properties
    
    @AppStorage("userID") private var userIdString: String = ""
    
    private var userId: Int {
        return Int(userIdString) ?? 0
    }
    
    @State private var purchaseList: [PurchaseItem] = []
    @State private var isLoading = true
    
    // [수정됨] 선택된 아이템을 저장하는 변수 (nil이면 모달 닫힘, 값이 있으면 모달 열림)
    // 기존의 showReviewSheet와 selectedTxId를 이것 하나로 대체합니다.
    @State private var selectedItem: PurchaseItem?
    
    // MARK: - 2. Body
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("구매 내역 불러오는 중...")
            } else if purchaseList.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "bag.badge.minus")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("구매한 내역이 없습니다.")
                        .foregroundColor(.gray)
                }
            } else {
                List(purchaseList) { item in
                    HStack(spacing: 15) {
                        // (1) 상품 이미지
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                        
                        // (2) 텍스트 정보
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text("\(item.price)원")
                                .font(.subheadline)
                                .bold()
                            
                            Text("판매자: \(item.seller_name)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(item.created_at.prefix(10))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // (3) 후기 작성 버튼 영역
                        if item.is_reviewed {
                            Text("작성완료")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            Button(action: {
                                // [수정됨] 버튼 클릭 시 선택된 아이템을 변수에 저장 -> 자동으로 모달이 뜸
                                self.selectedItem = item
                            }) {
                                Text("후기작성")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 5)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("구매 내역")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchPurchaseHistory()
        }
        // [수정됨] item 옵션을 사용하여 데이터가 확실할 때만 모달을 띄움
        .sheet(item: $selectedItem) { item in
            // item: 여기서 item은 방금 클릭한 그 상품 정보입니다.
            ReviewWriteView(
                txId: item.tx_id, // 여기서 정확한 ID가 넘어갑니다.
                isPresented: Binding(
                    get: { selectedItem != nil },
                    set: { if !$0 { selectedItem = nil } }
                )
            ) {
                // 완료 시 목록 새로고침 및 창 닫기
                fetchPurchaseHistory()
                selectedItem = nil
            }
        }
    }
    
    // MARK: - 3. Network Logic
    func fetchPurchaseHistory() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/get_purchase_history.php?user_id=\(userId)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([PurchaseItem].self, from: data) {
                    DispatchQueue.main.async {
                        self.purchaseList = decoded
                        self.isLoading = false
                    }
                }
            }
        }.resume()
    }
}

// MARK: - 데이터 모델
struct PurchaseItem: Codable, Identifiable {
    let tx_id: Int
    let market_id: Int
    let price: Int
    let created_at: String
    let title: String
    let seller_name: String
    let is_reviewed: Bool
    
    var id: Int { tx_id }
}

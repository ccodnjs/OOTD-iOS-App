import SwiftUI

// MARK: - 데이터 모델 정의
// 서버에서 받아올 판매자 정보 구조체
struct SellerProfileInfo: Codable {
    var name: String
    var review_count: Int
    var avg_rating: Double
    var selling_items: [MarketDetail] // MarketDetail 구조체 재사용 (필드명이 같아야 함)
}

// 후기 데이터 구조체
struct ReviewData: Codable, Identifiable {
    let review_id: Int
    let rating: Int
    let content: String
    let created_at: String
    let reviewer_name: String
    
    var id: Int { review_id }
}

// MARK: - 판매자 상세 보기 (OtherSellerView)
// 판매자 프로필 화면을 구성하는 메인 뷰입니다.
struct OtherSellerView: View {
    // [외부 전달 데이터] 조회할 판매자 ID
    let sellerId: Int
    
    // [내부 상태]
    // 판매자 정보 (이름, 평점, 판매 물품 등)
    @State private var sellerInfo: SellerProfileInfo? = nil
    // 후기 목록
    @State private var reviews: [ReviewData] = []
    // 현재 선택된 탭 (0: 판매물품, 1: 거래후기)
    @State private var selectedTab: Int = 0
    // 후기 작성창 표시 여부
    @State private var showReviewWriteSheet = false
    
    // 내 아이디 (후기 작성 버튼 표시 여부 판단용)
    @State private var myId: Int = UserDefaults.standard.integer(forKey: "userID")
    
    // 그리드 레이아웃 설정 (2열)
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 프로필 헤더 (상단 정보)
            // 판매자 정보가 로드되었을 때만 표시합니다.
            if let info = sellerInfo {
                VStack(spacing: 10) {
                    // 프로필 이미지 (임시로 회색 원)
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(Image(systemName: "person.fill").font(.largeTitle).foregroundColor(.gray))
                    
                    // 이름
                    Text(info.name)
                        .font(.title2)
                        .bold()
                    
                    // 별점 및 후기 수
                    HStack {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text(String(format: "%.1f", info.avg_rating)) // 소수점 1자리까지 표시
                            .bold()
                        Text("후기 \(info.review_count)개")
                            .foregroundColor(.gray)
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 20)
            } else {
                // 로딩 중일 때 표시할 화면
                ProgressView().padding()
            }
            
            Divider()
            
            // 2. 탭 메뉴 (판매물품 / 거래후기)
            HStack {
                // [판매물품 탭 버튼]
                Button(action: { selectedTab = 0 }) {
                    VStack {
                        Text("판매물품")
                            .font(.headline)
                            .foregroundColor(selectedTab == 0 ? .black : .gray)
                        // 선택된 탭 아래에 검은 줄 표시
                        Rectangle()
                            .fill(selectedTab == 0 ? Color.black : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // [거래후기 탭 버튼]
                Button(action: { selectedTab = 1 }) {
                    VStack {
                        Text("거래후기")
                            .font(.headline)
                            .foregroundColor(selectedTab == 1 ? .black : .gray)
                        Rectangle()
                            .fill(selectedTab == 1 ? Color.black : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 45)
            
            // 3. 탭 내용 (스크롤 영역)
            ScrollView {
                if selectedTab == 0 {
                    // [탭 0: 판매 중인 물품 리스트]
                    if let items = sellerInfo?.selling_items, !items.isEmpty {
                        // 2열 그리드로 보여줌
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(items, id: \.market_id) { item in
                                // 클릭 시 상세 화면(MarketItemDetailView)으로 이동
                                NavigationLink(destination: MarketItemDetailView(marketItemId: item.market_id)) {
                                    // 상품 카드 뷰 (간단하게 구현)
                                    SimpleProductCell(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    } else {
                        // 판매 중인 상품이 없을 때
                        emptyView(text: "판매 중인 상품이 없습니다.")
                    }
                } else {
                    // [탭 1: 후기 리스트]
                    if !reviews.isEmpty {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(reviews) { review in
                                ReviewCell(review: review)
                                Divider()
                            }
                        }
                    } else {
                        // 후기가 없을 때
                        emptyView(text: "등록된 후기가 없습니다.")
                    }
                }
            }
        }
        .navigationTitle("판매자 정보")
        .navigationBarTitleDisplayMode(.inline)
        // [후기 작성 모달 시트]
        .sheet(isPresented: $showReviewWriteSheet) {
            // tx_id를 모르므로 여기서는 0이나 임시 값을 넘길 수밖에 없습니다.
            // 올바른 흐름은 구매 내역 -> 후기 작성입니다.
            ReviewWriteView(txId: 0, isPresented: $showReviewWriteSheet) {
                // 작성이 완료되면 데이터 새로고침
                fetchSellerInfo()
                fetchReviews()
            }
        }
        // 화면이 나타날 때 데이터 불러오기
        .onAppear {
            fetchSellerInfo()
            fetchReviews()
        }
    }
    
    // 빈 화면 안내 뷰 (재사용 가능)
    func emptyView(text: String) -> some View {
        VStack {
            Spacer().frame(height: 50)
            Text(text).foregroundColor(.gray)
            Spacer()
        }
    }
    
    // MARK: - 네트워크 통신
    
    // 판매자 정보 가져오기
    func fetchSellerInfo() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/get_seller_info.php?seller_id=\(sellerId)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode(SellerProfileInfo.self, from: data) {
                    DispatchQueue.main.async { self.sellerInfo = decoded }
                }
            }
        }.resume()
    }
    
    // 후기 목록 가져오기
    func fetchReviews() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/get_seller_reviews.php?seller_id=\(sellerId)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([ReviewData].self, from: data) {
                    DispatchQueue.main.async { self.reviews = decoded }
                }
            }
        }.resume()
    }
}

// [UI 컴포넌트] 간단한 상품 셀 (그리드용)
struct SimpleProductCell: View {
    let item: MarketDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 이미지 영역
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: item.image_url ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        // 이미지 로딩 실패/중일 때 회색 배경
                        Color.gray.opacity(0.2)
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                    }
                }
                .frame(height: 150)
                .clipped()
                .cornerRadius(10)
                
                // 판매 완료 배지
                if item.status == 2 {
                    Color.black.opacity(0.5)
                        .cornerRadius(10)
                        .overlay(
                            Text("판매완료")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.white)
                        )
                }
            }
            
            // 텍스트 영역 (제목, 가격)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text("\(item.price)원")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.primary)
            }
        }
        .padding(5)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2) // 가벼운 그림자
    }
}

// MARK: - 후기 셀 디자인
// 후기 목록의 각 항목을 보여주는 뷰입니다.
struct ReviewCell: View {
    let review: ReviewData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 별점 표시 (1~5점)
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                Spacer()
                // 작성 날짜 (YYYY-MM-DD)
                Text(review.created_at.prefix(10))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 후기 내용
            Text(review.content)
                .font(.body)
            
            // 작성자 이름
            Text("작성자: \(review.reviewer_name)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

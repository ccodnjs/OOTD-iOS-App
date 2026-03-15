import SwiftUI

struct WishlistView: View {
    // [데이터 저장소: AppStorage]
    // 앱 내부에 "userID"라는 키로 저장된 값을 가져옵니다.
    // 앱을 껐다 켜도 로그인 정보가 유지되게 해주는 간편한 저장소입니다.
    @AppStorage("userID") private var userIdString: String = ""
    
    // [연산 프로퍼티 (Computed Property)]
    // 저장된 ID는 문자열(String)인데, 서버 통신엔 정수(Int)가 필요해서 변환합니다.
    // 변환에 실패하면(로그인 안 된 상태 등) 0을 반환합니다 (?? 0).
    private var userId: Int { Int(userIdString) ?? 0 }
    
    // [상태 변수 (@State)]
    // wishlistItems: 서버에서 받아온 찜 목록 데이터를 저장하는 배열
    // isLoading: 데이터를 받아오는 중인지 표시하기 위한 로딩 상태 플래그
    @State private var wishlistItems: [MarketItem] = []
    @State private var isLoading = true
    
    // [그리드 레이아웃 설정]
    // 3열(Column)로 구성된 그리드를 정의합니다.
    // .flexible(): 화면 너비에 맞춰서 자동으로 간격을 조절합니다.
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 12), // 1열
        GridItem(.flexible(), spacing: 12), // 2열
        GridItem(.flexible())               // 3열
    ]
    
    var body: some View {
        ScrollView { // 화면보다 내용이 길어지면 스크롤 가능하게 함
            
            // [조건부 뷰 렌더링]
            if isLoading {
                // 1. 로딩 중일 때: 뱅글뱅글 도는 인디케이터 표시
                ProgressView().padding(.top, 50)
                
            } else if wishlistItems.isEmpty {
                // 2. 로딩은 끝났는데 데이터가 없을 때 (찜한 게 없음)
                VStack(spacing: 10) {
                    Image(systemName: "heart.slash") // 빈 하트 아이콘
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("찜한 상품이 없습니다.")
                        .foregroundColor(.gray)
                }
                .padding(.top, 100)
                
            } else {
                // 3. 데이터가 있을 때: 그리드 형태로 상품 표시
                // LazyVGrid: 화면에 보이는 만큼만 그때그때 그리는 효율적인 그리드
                LazyVGrid(columns: gridColumns, spacing: 15) {
                    
                    // ForEach: 배열(wishlistItems)을 순회하며 뷰를 생성
                    ForEach(wishlistItems) { item in
                        
                        // [네비게이션 링크]
                        // 아이템을 클릭하면 상세 화면(MarketItemDetailView)으로 이동
                        NavigationLink(destination: MarketItemDetailView(marketItemId: item.market_id)) {
                            
                            // 이전에 만들어둔 셀 디자인(MarketItemCell)을 재사용
                            MarketItemCell(item: item)
                        }
                        // [중요 스타일 수정]
                        // NavigationLink는 기본적으로 파란색 텍스트 버튼처럼 보입니다.
                        // PlainButtonStyle을 적용해야 원래 디자인(검정 글씨, 이미지 등)이 유지됩니다.
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding() // 그리드 전체에 여백 추가
            }
        }
        .navigationTitle("관심 목록") // 상단 타이틀 설정
        .onAppear {
            // [생명주기 함수]
            // 이 화면이 나타날 때마다 서버에 최신 목록을 요청합니다.
            fetchWishlist()
        }
    }
    
    // [서버 통신 함수]
    func fetchWishlist() {
        // 1. URL 생성 (유저 ID를 파라미터로 포함)
        // guard let: URL이 잘못되었다면 함수를 종료(return)하여 에러 방지
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/get_wishlist_items.php?user_id=\(userId)") else { return }
        
        // 2. 비동기 네트워크 요청 시작 (URLSession)
        URLSession.shared.dataTask(with: url) { data, _, error in
            // 에러 발생 시 로그 출력 후 종료
            if let error = error {
                print("Error fetching wishlist: \(error)")
                return
            }
            
            // 데이터가 없으면 종료
            guard let data = data else { return }
            
            // 3. JSON 디코딩 (JSON -> Swift 객체 변환)
            do {
                // 서버에서 받은 JSON 데이터를 [MarketItem] 배열 형태로 변환
                let items = try JSONDecoder().decode([MarketItem].self, from: data)
                
                // [UI 업데이트 주의사항]
                // 네트워크 작업은 백그라운드 스레드에서 일어나지만,
                // DispatchQueue.main.async: 화면(UI)을 고치는 건 반드시 '메인 스레드'에서 해야 앱이 안 꺼집니다.
                // 메인 스레드 - 버튼을 누르면 반응, 글자를 바꾸고 화면을 그리는 것
                // 작업을 관리하는 대기열 관리자, 앱의 메인 스레드와 연결된 대기열, 작업을 대기열에 넣어두고 끝날 때까지 기다리지 말고 다음 코드를 계속 실행하라는 뜻
                DispatchQueue.main.async {
                    self.wishlistItems = items // 데이터 채우기
                    self.isLoading = false     // 로딩 상태 해제
                }
            } catch {
                print("Decoding Error in Wishlist: \(error)")
                // 디코딩 실패 시, 서버가 뭐라고 보냈는지 문자열로 찍어보기 (디버깅용)
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Server Response: \(responseString)")
                }
            }
        }.resume() // 작업 시작 명령어
    }
}

#Preview {
    WishlistView()
}

import SwiftUI

// MARK: - 1. 데이터 모델
// [구조체 정의] 서버 DB(market_items 테이블)와 1:1로 매핑되는 데이터 구조
// Identifiable: List나 ForEach에서 각 아이템을 고유하게 구별하기 위해 채택 (id 필수)
// Hashable: NavigationLink 등에서 객체 자체를 비교하거나 전달할 때 필요
// Codable: JSON 데이터를 Swift 객체로 변환(Decoding)하거나 그 반대로 변환(Encoding)하기 위해 채택
struct MarketItem: Identifiable, Hashable, Codable {
    let market_id: Int      // DB의 Primary Key
    let title: String       // 상품명
    let brand: String       // 브랜드명
    let price: Int          // 가격
    let main_category: String // 카테고리 (상의, 하의 등)
    let imageUrl: String?   // 이미지 경로 (옵셔널: 이미지가 없을 수도 있음)
    let description: String? // 상세 설명 (옵셔널)
    let seller_id: Int?     // 판매자 ID
    let status: Int?        // 판매 상태 (판매중, 예약중 등)
    let created_at: String? // 등록일
    
    // [연산 프로퍼티 (Computed Property)]
    // Identifiable 프로토콜을 준수하기 위해 'id'라는 이름의 변수가 필수입니다.
    // DB의 market_id를 그대로 id로 사용하도록 매핑합니다.
    var id: Int { market_id }
    
    // 코드 가독성을 위해 DB 컬럼명(title) 대신 직관적인 이름(name)으로 접근 가능하게 만듭니다.
    var name: String { title }
    var category: String { main_category }
}

// MARK: - 2. 메인 뷰
struct MarketView: View {
    // MARK: - State (상태 변수)
    // @State: SwiftUI에서 뷰의 '상태'를 저장하는 속성 감시자입니다.
    // 이 변수들의 값이 바뀌면, SwiftUI는 자동으로 body를 다시 그려서(Re-render) 화면을 갱신합니다.
    
    @State private var userId: Int? = nil           // 현재 로그인한 사용자 ID 저장
    @State private var showingRegistrationSheet = false // 상품 등록 화면(Sheet)을 띄울지 여부 (true/false)
    
    // 서버 데이터
    @State private var items: [MarketItem] = []     // 서버에서 받아온 상품 리스트를 저장하는 배열
    
    // 필터 상태 (사용자가 선택한 필터 값들)
    @State private var searchText = ""              // 검색창 입력 텍스트
    @State private var selectedCategory: String? = nil // 선택된 카테고리 (nil이면 전체)
    @State private var selectedColor: String? = nil    // 선택된 색상
    @State private var selectedMaterial: String? = nil // 선택된 소재
    @State private var selectedStyle: String? = nil    // 선택된 스타일
    @State private var selectedPriceRange: String? = nil // 선택된 가격 범위 ("min~max" 문자열 형태)
    
    // MARK: - 옵션 데이터 (상수)
    // 필터링 메뉴에 보여줄 항목들 변하지 않으므로 let으로 선언했다
    let categories = ["상의", "아우터", "하의", "원피스/세트", "신발", "악세사리"]
    
    let colorOptions = [
        "빨강", "초록", "파랑", "노랑", "주황", "보라", "분홍",
        "하늘색", "남색", "갈색", "검정", "회색", "흰색"
    ]
    
    let materialOptions = [
        "면", "린넨", "데님", "울/캐시미어/앙고라",
        "폴리에스터/나일론/스판덱스", "레이온", "코듀로이", "기모"
    ]
    
    let styleOptions = [
        "캐주얼", "스트릿", "빈티지", "페미닌", "코스프레",
        "오피스", "꾸안꾸", "발레코어", "청청"
    ]
    
    // [튜플 배열] 사용자에게 보여줄 텍스트(label)와 서버로 보낼 값(value)을 쌍으로 묶음
    // 예: 화면엔 "3만원 이하"라고 뜨지만, 서버엔 "0~30000"을 보냄
    let priceOptions: [(label: String, value: String)] = [
        ("3만원 이하", "0~30000"),
        ("3만원 ~ 5만원", "30000~50000"),
        ("5만원 ~ 10만원", "50000~100000"),
        ("10만원 이상", "100000~0")
    ]
    
    // [Grid 레이아웃 설정]
    // 3열 그리드(Grid)를 만듭니다. .flexible()은 화면 너비에 맞춰 남은 공간을 유동적으로 채웁니다.
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10), // 1열
        GridItem(.flexible(), spacing: 10), // 2열
        GridItem(.flexible())               // 3열
    ]

    // MARK: - Body (메인 화면 구조)
    // SwiftUI의 모든 UI 구성요소는 이 body 안에 들어갑니다.
    var body: some View {
        NavigationStack { // 화면 전환(Navigation)을 관리하는 최상위 컨테이너 (iOS 16+)
            VStack(spacing: 0) { // 수직(Vertical)으로 뷰들을 쌓음
                // 1. 상단 필터 영역 (복잡해서 아래에 별도 변수 filterHeaderView로 분리함)
                filterHeaderView
                
                // 2. 상품 리스트 영역 (복잡해서 아래에 별도 변수 productListView로 분리함)
                productListView
            }
            .navigationTitle("마켓") // 상단 네비게이션 바 타이틀
            .navigationBarTitleDisplayMode(.inline) // 타이틀을 작게(inline) 표시
            // [검색 기능]
            // $searchText: 바인딩($)을 통해 검색어 입력 시 searchText 변수가 실시간으로 업데이트됨
            .searchable(text: $searchText, prompt: "브랜드, 상품명 검색")
            // [검색 완료 시 동작] 키보드의 엔터(Search)를 눌렀을 때 실행
            .onSubmit(of: .search) {
                Task { await fetchMarketItems() } // 비동기 네트워크 요청 실행
            }
            // [상단 툴바 버튼 구성]
            .toolbar {
                // 왼쪽: 마이페이지(판매자 뷰) 이동 버튼
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SellerView()) { // 클릭 시 이동할 화면 지정
                        Image(systemName: "person.circle").font(.title3)
                    }
                }
                // 오른쪽: 상품 등록 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingRegistrationSheet = true } label: { // 클릭 시 sheet 상태값 true 변경
                        Image(systemName: "plus.circle").font(.title3)
                    }
                }
            }
            // [모달 시트] showingRegistrationSheet가 true가 되면 아래 뷰가 팝업처럼 뜸
            .sheet(isPresented: $showingRegistrationSheet) {
                // 시트가 닫힐 때(onDismiss) 실행되는 클로저: 목록 새로고침
                Task { await fetchMarketItems() }
            } content: {
                MarketItemRegistrationView() // 띄울 화면
            }
            
            // [상태 변경 감지 (.onChange)]
            // 필터(@State 변수) 중 하나라도 바뀌면, 즉시 서버에 데이터를 다시 요청함
            // 'newValue'는 바뀐 값이지만, 여기선 필요 없어서 '_'로 처리하고 무조건 fetchMarketItems 호출
            .onChange(of: selectedCategory) { _, _ in Task { await fetchMarketItems() } }
            .onChange(of: selectedColor) { _, _ in Task { await fetchMarketItems() } }
            .onChange(of: selectedMaterial) { _, _ in Task { await fetchMarketItems() } }
            .onChange(of: selectedStyle) { _, _ in Task { await fetchMarketItems() } }
            .onChange(of: selectedPriceRange) { _, _ in Task { await fetchMarketItems() } }
            
            // 검색어가 다 지워졌을 때(empty) 목록을 전체로 초기화
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty { Task { await fetchMarketItems() } }
            }
            
            // [화면 진입 시점 (.onAppear)]
            // 뷰가 처음 나타날 때 실행되는 코드
            .onAppear {
                loadUserID() // 로컬 저장소에서 유저 ID 불러오기
                Task { await fetchMarketItems() } // 초기 데이터 로딩
            }
        }
    }
    
    // MARK: - 분리된 뷰 (컴파일 속도 향상 및 가독성)
    // body 안에 모든 코드를 넣으면 너무 길어지므로, UI 덩어리를 변수로 분리
    
    /// 상단 필터 영역 뷰
    private var filterHeaderView: some View {
        ScrollView(.horizontal, showsIndicators: false) { // 가로 스크롤 가능
            VStack(alignment: .leading, spacing: 10) {
                // 1열: 카테고리 칩(Chip) 버튼들
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        // 커스텀 뷰(CategoryChip) 호출
                        // 클릭 시: 이미 선택된 거면 해제(nil), 아니면 선택(category)
                        CategoryChip(title: category, isSelected: selectedCategory == category) {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    }
                }
                
                // 2열: 상세 조건 (드롭다운 메뉴 형태)
                HStack(spacing: 8) {
                    // 커스텀 뷰(FilterMenu)를 사용하여 색상, 재질, 스타일 필터 구성
                    // $selectedColor 처럼 바인딩($)을 넘겨서 내부에서 값을 바꿀 수 있게 함
                    FilterMenu(title: "색상", selection: $selectedColor, options: colorOptions)
                    FilterMenu(title: "재질", selection: $selectedMaterial, options: materialOptions)
                    FilterMenu(title: "스타일", selection: $selectedStyle, options: styleOptions)
                    
                    // 가격은 범위 데이터(Tuple) 구조가 달라서 별도로 Menu 구성
                    Menu {
                        Button("전체") { selectedPriceRange = nil }
                        ForEach(priceOptions, id: \.value) { option in
                            Button(option.label) { selectedPriceRange = option.value }
                        }
                    } label: {
                        // 버튼의 겉모양 (선택되었으면 파란색, 아니면 회색)
                        FilterLabel(title: "가격", isActive: selectedPriceRange != nil)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2) // 옅은 그림자 효과
    }
    
    /// 상품 리스트 영역 뷰
    private var productListView: some View {
        ScrollView { // 세로 스크롤
            if items.isEmpty {
                // 데이터가 없을 때 보여줄 화면 (Empty View)
                VStack(spacing: 15) {
                    Spacer().frame(height: 50)
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("검색 결과가 없습니다.")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            } else {
                // 데이터가 있을 때 그리드(Grid) 형태로 보여줌
                // LazyVGrid: 화면에 보이는 부분만 렌더링하여 성능 최적화
                LazyVGrid(columns: gridColumns, spacing: 15) {
                    ForEach(items, id: \.market_id) { item in
                        // 각 아이템을 누르면 상세 화면(MarketItemDetailView)으로 이동
                        NavigationLink(destination: MarketItemDetailView(marketItemId: item.market_id)) {
                            MarketItemCell(item: item) // 실제 상품 카드 디자인
                        }
                        .buttonStyle(PlainButtonStyle()) // 링크 기본 스타일(파란 글씨 등) 제거
                    }
                }
                .padding(15)
            }
        }
    }
    
    // MARK: - Helper Components (UI 구성요소 함수들)
    
    // [카테고리 칩 버튼 디자인]
    // isSelected에 따라 배경색(검정/회색)과 글자색(흰색/검정)을 다르게 처리
    // secondarySystemBackground는 라이트 모드, 다크 모드일 때 각각 다른 색상으로 바뀜
    func CategoryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.black : Color(uiColor: .secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(20) // 둥근 모서리 (알약 모양)
                .overlay(
                    // 선택 안 됐을 때만 얇은 테두리 표시
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: isSelected ? 0 : 1)
                )
        }
    }
    
    // [필터 메뉴(드롭다운) 공통 컴포넌트]
    // Binding<String?>을 받아서 선택 값을 직접 수정합니다.
    //Property Wrapper가 실제로 감싸고 있는 알맹이 값이 wrappedValue
    func FilterMenu(title: String, selection: Binding<String?>, options: [String]) -> some View {
        Menu {
            Button("전체 선택 해제") { selection.wrappedValue = nil }
            ForEach(options, id: \.self) { option in
                Button { selection.wrappedValue = option } label: {
                    HStack {
                        Text(option)
                        // 현재 선택된 항목 옆에 체크표시
                        if selection.wrappedValue == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            // 버튼의 겉모양은 FilterLabel 함수로 통일
            // selection.wrappedValue ?? title -> 선택된 값이 있으면 그걸 보여주고, 없으면 기본 타이틀("색상") 표시
            FilterLabel(title: selection.wrappedValue ?? title, isActive: selection.wrappedValue != nil)
        }
    }
    
    // [필터 버튼 겉모양]
    // 활성화(isActive) 여부에 따라 파란색 테두리/글씨 적용
    // cornerRadius(8)는 둥근 버튼을 만드는 것
    func FilterLabel(title: String, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Text(title).lineLimit(1)
            Image(systemName: "chevron.down").font(.caption2) // 아래 화살표 아이콘
        }
        .font(.system(size: 13))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? Color.blue.opacity(0.1) : Color.white)
        .foregroundColor(isActive ? .blue : .gray)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.blue : Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
    
    // MARK: - Server Networking (비즈니스 로직)
    
    // [상품 목록 가져오기 (비동기 함수 async)]
    func fetchMarketItems() async {
        // 1. URL 구성 (Query String 생성을 위해 URLComponents 사용)
        var components = URLComponents(string: "http://124.56.5.77/projectOOTD/get_market_items.php")
        var queryItems: [URLQueryItem] = []
        
        // 2. 현재 선택된 필터(@State 값들)가 있다면 쿼리 파라미터에 추가
        // 예: ?mainCategory=상의&brand=나이키&priceRange=0~30000
        if let cat = selectedCategory { queryItems.append(URLQueryItem(name: "mainCategory", value: cat)) }
        if !searchText.isEmpty { queryItems.append(URLQueryItem(name: "brand", value: searchText)) } // 검색어를 브랜드로 가정
        if let col = selectedColor { queryItems.append(URLQueryItem(name: "color", value: col)) }
        if let mat = selectedMaterial { queryItems.append(URLQueryItem(name: "material", value: mat)) }
        if let style = selectedStyle { queryItems.append(URLQueryItem(name: "style", value: style)) }
        if let price = selectedPriceRange { queryItems.append(URLQueryItem(name: "priceRange", value: price)) }
        
        components?.queryItems = queryItems
        guard let url = components?.url else { return }
        
        print("Requesting: \(url)") // 디버깅용 로그
        
        do {
            // 3. 네트워크 요청 (URLSession) - 데이터가 올 때까지 기다림(await)
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // 4. 응답 상태 확인 (HTTP 200 OK인지)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            // 5. JSON 데이터를 Swift 객체(items 배열)로 디코딩
            let decodedItems = try JSONDecoder().decode([MarketItem].self, from: data)
            
            // 6. UI 업데이트 (MainActor)
            // 네트워크 처리는 백그라운드 스레드에서 돌지만, @State 변수 업데이트(화면 갱신)는 메인 스레드에서 해야 안전함
            await MainActor.run { self.items = decodedItems }
        } catch {
            print("Error: \(error)")
            // 에러 발생 시 목록 비우기
            await MainActor.run { self.items = [] }
        }
    }
    
    // [UserDefaults에서 저장된 유저 정보 불러오기]
    func loadUserID() {
        self.userId = Int(UserDefaults.standard.string(forKey: "userID") ?? "")
    }
}

// MARK: - Cell View
// 리스트의 각 아이템을 보여주는 카드형 UI입니다.
struct MarketItemCell: View {
    let item: MarketItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // [비동기 이미지 로딩]
            // 웹상의 URL 이미지를 로드합니다. 로딩 상태(phase)에 따라 다른 UI를 보여줍니다.
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    // 로딩 성공 시: 이미지 표시
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    // 로딩 중이거나 실패 시: 회색 박스에 사진 아이콘 표시 (Placeholder)
                    Color.gray.opacity(0.1).overlay(Image(systemName: "photo").foregroundColor(.gray))
                }
            }
            .frame(height: 150) // 이미지 높이 고정
            .clipped() // 영역 밖으로 나간 이미지 자르기
            .cornerRadius(12) // 둥근 모서리
            
            // 상품 정보 텍스트 영역
            VStack(alignment: .leading, spacing: 2) {
                Text(item.brand).font(.caption2).fontWeight(.bold).foregroundColor(.gray)
                Text(item.name).font(.system(size: 14)).lineLimit(2).foregroundColor(.primary) // 최대 2줄
                Text("\(item.price)원").font(.system(size: 16, weight: .bold)).foregroundColor(.black).padding(.top, 2)
            }
        }
        .background(Color.white) // 셀 배경색 흰색
    }
}

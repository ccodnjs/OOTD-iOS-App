import SwiftUI

// MARK: - 메인 상세 화면
// 상품 목록에서 특정 아이템을 클릭했을 때 넘어오는 상세 페이지입니다.
// 이 뷰는 상품의 이미지, 정보, 판매자 정보 등을 보여주고 구매/채팅/수정/삭제 기능을 제공합니다.
struct MarketItemDetailView: View {
    
    // MARK: - 1. Properties (데이터 & 상태 관리)
    
    // [외부 주입 데이터]
    // 이전 화면(리스트)에서 클릭된 상품의 고유 ID입니다.
    // 이 ID를 키값으로 사용하여 서버에 상세 정보를 요청합니다. (예: get_market_item_detail.php?market_id=1)
    let marketItemId: Int
    
    // [사용자 정보]
    // 앱 내부에 저장된 "userID" 값을 가져옵니다. (로그인 유지 기능)
    // @AppStorage를 사용하여 값이 변경되면 뷰도 자동으로 업데이트됩니다.
    // 로그인하지 않은 경우 빈 문자열("")일 수 있습니다.
    @AppStorage("userID") private var userIdString: String = ""
    
    // 저장된 ID는 문자열(String)이므로, 계산과 비교를 위해 정수(Int)로 변환합니다.
    // 변환에 실패할 경우(로그인 안 된 상태 등) 0을 반환하여 앱 충돌을 방지합니다.
    private var currentUserId: Int {
        return Int(userIdString) ?? 0
    }
    
    // [서버 데이터]
    // 서버에서 받아온 상세 정보를 저장할 변수입니다.
    // MarketDetail 구조체 형태로 저장되며, 아직 데이터를 받아오기 전이므로 초기값은 nil(옵셔널)입니다.
    @State private var itemDetail: MarketDetail? = nil
    
    // [UI 상태 플래그]
    // 데이터 로딩 중인지 여부를 표시합니다. true면 로딩 인디케이터(뱅글뱅글)가 돕니다.
    // 데이터 로딩이 완료되면 false로 바뀝니다.
    @State private var isLoading = true
    
    // [채팅 관련 상태]
    // 채팅방으로 화면을 이동시킬지 결정하는 트리거 변수입니다. true가 되면 navigationDestination이 동작합니다.
    @State private var navigateToChat = false
    // 서버에서 받아온(혹은 생성된) 채팅방의 고유 ID를 저장합니다.
    // 이 ID를 가지고 채팅방 화면(ChatMessageView)으로 이동합니다.
    @State private var createdChatId: Int? = nil
    
    // [구매자 선택 시트 상태]
    // 판매 완료 버튼을 눌렀을 때, 구매자를 선택하는 시트(SelectBuyerSheet)를 띄울지 결정합니다.
    @State private var showBuyerSelectionSheet = false
    
    // [기타 화면 이동 트리거]
    @State private var showEditSheet = false  // 수정 모달창(EditPostView) 표시 여부
    
    // [알림창(Alert) 상태]
    @State private var showDeleteAlert = false // 삭제 확인 팝업 표시 여부
    @State private var alertMessage = ""       // 팝업에 띄울 메시지 내용 (성공/실패 메시지)
    @State private var shouldDismiss = false   // 작업(삭제 등) 완료 후 화면을 닫을지 여부
    
    // [환경 변수]
    // 현재 화면을 닫고 이전 화면(목록)으로 돌아가는 기능(dismiss)을 시스템에서 빌려옵니다.
    @Environment(\.dismiss) var dismiss
    
    // MARK: - 2. Body (화면 구성)
    var body: some View {
        // ZStack: 뷰를 겹쳐서 배치합니다.
        // 스크롤 뷰 위에 '하단 고정 바'를 띄우기 위해 사용합니다.
        // alignment: .bottom -> 자식 뷰들을 아래쪽 기준으로 정렬합니다.
        ZStack(alignment: .bottom) {
            
            // (1) 메인 콘텐츠 영역 (스크롤 가능)
            // 이미지와 텍스트 정보가 들어갑니다.
            mainScrollView
            
            // (2) 하단 고정 액션 바 (구매/채팅/수정 버튼)
            // 데이터(itemDetail)가 로딩 완료된 후에만 보여줍니다. (nil이 아닐 때)
            if let item = itemDetail {
                bottomActionBar(item: item)
            }
        }
        // 키보드가 올라왔을 때 하단 바가 밀려 올라가는 등 레이아웃이 깨지는 것을 방지합니다.
        .ignoresSafeArea(.keyboard)
        .navigationTitle("상품 상세")      // 상단 네비게이션 타이틀
        .navigationBarTitleDisplayMode(.inline) // 타이틀을 작게 표시
        
        // --- 화면 전환 및 팝업 로직 (Modifiers) ---
        
        // [채팅방 이동 로직]
        // navigateToChat이 true가 되면 실행됩니다.
        .navigationDestination(isPresented: $navigateToChat) {
            // 채팅방 ID와 상품 정보가 모두 준비되었는지 확인합니다.
            if let chatId = createdChatId, let item = itemDetail {
                // 1:1 채팅방 뷰(ChatMessageView)로 이동하며 필요한 정보를 넘겨줍니다.
                ChatMessageView(
                    chatId: chatId,           // 방 번호
                    myId: currentUserId,      // 내 아이디
                    otherId: item.seller_id,  // 판매자 아이디 (상대방)
                    itemTitle: item.title     // 상단에 띄울 상품명
                )
            }
        }
        
        // [수정 화면 시트]
        // showEditSheet가 true가 되면 아래에서 위로 모달창이 올라옵니다.
        .sheet(isPresented: $showEditSheet) {
            if let item = itemDetail {
                // 수정 화면(EditPostView)을 띄웁니다.
                // onUpdate 클로저를 통해 수정이 완료되면 상세 정보를 새로고침(fetchItemDetail)합니다.
                EditPostView(item: item, isPresented: $showEditSheet, onUpdate: {
                    fetchItemDetail()
                })
            }
        }
        
        // [구매자 선택 시트]
        // showBuyerSelectionSheet가 true가 되면 구매자 선택 모달창이 뜹니다. (판매 완료 처리용)
        .sheet(isPresented: $showBuyerSelectionSheet) {
            if let item = itemDetail {
                SelectBuyerSheet(marketItem: item, isPresented: $showBuyerSelectionSheet) {
                    // 거래 완료 처리가 끝나면(onComplete) 화면을 새로고침합니다.
                    fetchItemDetail()
                }
            }
        }
        
        // [삭제 확인 알림창]
        // 사용자가 실수로 삭제하지 않도록 한 번 더 물어봅니다.
        .alert("게시물 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {} // 취소 버튼 (아무 동작 없음)
            Button("삭제", role: .destructive) { deletePost() } // 실제 삭제 함수 실행 (빨간색 버튼)
        } message: {
            Text("정말로 이 게시물을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.")
        }
        
        // [결과 알림창]
        // 삭제 성공/실패 등의 메시지를 보여주고 확인을 누르면 화면을 닫습니다.
        .alert("알림", isPresented: $shouldDismiss) {
            Button("확인") { dismiss() } // 확인 버튼 누르면 뒤로가기 실행 (화면 닫기)
        } message: {
            Text(alertMessage)
        }
        
        // [화면 진입 시점]
        // 화면이 사용자에게 보이면(onAppear) 즉시 서버에서 데이터를 가져옵니다.
        .onAppear {
            fetchItemDetail()
        }
    }
    
    // MARK: - 3. Subviews (하위 뷰 분리)
    // body 코드가 너무 길어지는 것을 막기 위해 UI 구성 요소를 별도 변수/함수로 분리했습니다.
    
    // 스크롤 가능한 메인 영역
    private var mainScrollView: some View {
        ScrollView {
            // 데이터가 로드되었을 때만 내용을 그립니다.
            if let item = itemDetail {
                VStack(alignment: .leading, spacing: 0) {
                    imageSection(item: item) // 상단 이미지 섹션
                    infoSection(item: item)  // 하단 텍스트 정보 섹션
                }
            } else if isLoading {
                // 데이터 로딩 중일 때는 뱅글뱅글 도는 인디케이터 표시
                ProgressView("정보를 불러오는 중...")
                    .frame(maxWidth: .infinity, minHeight: 300)
            }
            // 하단 고정 바가 내용을 가리지 않도록 투명한 여백(Padding)을 추가합니다.
            Color.clear.frame(height: 80)
        }
    }
    
    // 상품 이미지 섹션 (상단)
    private func imageSection(item: MarketDetail) -> some View {
        ZStack(alignment: .topLeading) {
            // 웹 URL 이미지를 비동기로 불러옵니다.
            AsyncImage(url: URL(string: item.image_url ?? "")) { phase in
                switch phase {
                case .success(let image):
                    // 로딩 성공 시 이미지를 꽉 차게 표시 (비율 유지하면서 채움)
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    // 로딩 중이거나 실패 시 회색 배경에 사진 아이콘 표시 (Placeholder)
                    Color.gray.opacity(0.3)
                        .overlay(Image(systemName: "photo").scaleEffect(2).foregroundColor(.white))
                }
            }
            .frame(height: 350) // 이미지 높이 고정
            .clipped() // 영역을 벗어난 이미지는 잘라냅니다.
            
            // [상태 뱃지] 판매중(0)이 아닐 경우(예약중/판매완료) 좌측 상단에 라벨 표시
            if item.status != 0 {
                Text(item.status == 1 ? "예약중" : "판매완료")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.black.opacity(0.7)) // 반투명 검정 배경
                    .cornerRadius(20)
                    .padding([.leading, .top], 20)
            }
        }
    }
    
    // 상세 정보 섹션 (판매자, 제목, 설명 등)
    private func infoSection(item: MarketDetail) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // [판매자 프로필 영역]
            // 판매자 프로필을 클릭하면 판매자 상세 정보(OtherSellerView)로 이동할 수 있게 합니다.
            NavigationLink(destination: OtherSellerView(sellerId: item.seller_id)) {
                HStack {
                    // 프로필 이미지 (임시로 회색 원)
                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 40)
                        .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                    
                    VStack(alignment: .leading) {
                        Text("판매자 ID: \(item.seller_id)")
                            .font(.headline)
                            .foregroundColor(.black) // 링크 기본색(파랑) 방지
                        // 내가 쓴 글이면 파란색으로 '나의 판매글' 표시, 아니면 '프로필 보기' 안내
                        Text(item.seller_id == currentUserId ? "나의 판매글" : "프로필 보기 >")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer() // 왼쪽 정렬을 위해 빈 공간 채움
                    
                    // [상태 변경 메뉴] 판매자 본인에게만 보임
                    if item.seller_id == currentUserId {
                        Menu {
                            Button("판매중으로 변경") { updateStatus(0) }
                            Button("예약중으로 변경") { updateStatus(1) }
                            // [수정된 부분] 판매완료 클릭 시 -> 바로 변경하지 않고 구매자 선택창 띄우기
                            Button("판매완료로 변경") {
                                showBuyerSelectionSheet = true
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("상태변경")
                            }
                            .font(.caption)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle()) // 버튼 스타일 제거하여 깔끔하게
            
            Divider() // 구분선
            
            // [상품 텍스트 정보]
            Text(item.title)
                .font(.title2)
                .fontWeight(.bold)
            
            // 카테고리와 등록 시간 표시 (getTimeAgo 함수 사용)
            Text("\(item.main_category ?? "카테고리 없음") · \(getTimeAgo(dateString: item.created_at))")
                .font(.caption)
                .foregroundColor(.gray)
            
            // 가격 표시
            Text("\(item.price)원")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 5)
            
            // 상세 설명 본문
            Text(item.description)
                .font(.body)
                .padding(.top, 10)
                .lineSpacing(5) // 줄 간격 조정
            
            // [관심 수 표시] (단순 표시용)
            HStack(spacing: 15) {
                Image(systemName: "heart.fill").foregroundColor(.gray).scaleEffect(0.8)
                Text("관심 \(item.like_count)")
            }
            .font(.caption).foregroundColor(.gray).padding(.top, 30)
        }
        .padding(20) // 전체 여백
    }
    
    // 하단 고정 액션 바 (구매자 vs 판매자 분기 처리)
    private func bottomActionBar(item: MarketDetail) -> some View {
        VStack(spacing: 0) {
            Divider() // 상단 구분선
            HStack {
                // 현재 로그인한 사람이 판매자인지 확인
                if item.seller_id == currentUserId {
                    // [CASE 1: 내가 판매자일 때] -> 수정 / 삭제 버튼 표시
                    Button(action: { showEditSheet = true }) {
                        Text("게시물 수정")
                            .font(.headline)
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    Button(action: { showDeleteAlert = true }) {
                        Text("삭제")
                            .font(.headline)
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                } else {
                    // [CASE 2: 내가 구매자일 때] -> 찜하기 / 채팅하기 버튼 표시
                    
                    // 찜하기 버튼 (왼쪽 작은 하트 버튼)
                    Button(action: { toggleLike() }) {
                        VStack(spacing: 4) {
                            // 내가 찜했는지(is_liked)에 따라 하트 색상 변경 (빨강/회색)
                            Image(systemName: item.is_liked ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(item.is_liked ? .red : .gray)
                            Text("\(item.like_count)").font(.caption2).foregroundColor(.gray)
                        }
                        .frame(width: 60)
                    }
                    
                    Divider().frame(height: 30).padding(.horizontal, 5)
                    
                    // 채팅하기 버튼 (오른쪽 큰 버튼)
                    Button(action: {
                        // 버튼 클릭 시 서버에 채팅방 생성/조회 요청
                        createOrGetChatRoom()
                    }) {
                        Text(getButtonTitle(status: item.status)) // 상태에 따라 버튼 텍스트 변경
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            // 판매중일 때만 주황색, 나머지는 회색 처리
                            .background(item.status == 0 ? Color.orange : Color.gray)
                            .cornerRadius(12)
                    }
                    // 판매중(0)이 아니면 버튼을 누를 수 없게 비활성화 (채팅 불가)
                    .disabled(item.status != 0)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 30) // 아이폰 하단 홈 바 영역 확보
            .background(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -5) // 위쪽으로 옅은 그림자
        }
    }
    
    // MARK: - 4. Logic & API (서버 통신)
    
    // 상품 상태(0,1,2)에 따라 버튼에 표시할 텍스트를 반환하는 함수
    func getButtonTitle(status: Int) -> String {
        switch status {
        case 0: return "채팅하기"
        case 1: return "예약중인 상품입니다"
        default: return "판매가 완료되었습니다"
        }
    }
    
    // [GET] 상품 상세 정보 불러오기
    func fetchItemDetail() {
        // GET 요청 URL 생성 (파라미터 포함)
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/get_market_item_detail.php?market_id=\(marketItemId)&user_id=\(currentUserId)") else { return }
        
        // 비동기 데이터 요청
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                // 받아온 JSON 데이터를 MarketDetail 구조체로 변환 (Decoding)
                if let decoded = try? JSONDecoder().decode(MarketDetail.self, from: data) {
                    // UI 업데이트는 반드시 메인 스레드에서 실행해야 함
                    DispatchQueue.main.async {
                        self.itemDetail = decoded
                        self.isLoading = false // 로딩 완료
                    }
                }
            }
        }.resume() // 작업 시작
    }
    
    // [POST] 채팅방 생성 또는 기존 방 조회 요청
    func createOrGetChatRoom() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/create_chat_room.php") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"
        
        // 내 아이디(구매자)와 상품 ID를 서버로 보냅니다.
        let body = "market_id=\(marketItemId)&buyer_id=\(currentUserId)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            // 응답 처리
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let chatId = json["chat_id"] as? Int {
                
                // 성공하면 채팅방 ID를 저장하고 화면 이동 트리거를 켭니다.
                DispatchQueue.main.async {
                    self.createdChatId = chatId
                    self.navigateToChat = true
                }
            }
        }.resume()
    }
    
    // [POST] 찜(좋아요) 토글 기능
    func toggleLike() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/toggle_wishlist.php") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"
        request.httpBody = "user_id=\(currentUserId)&market_id=\(marketItemId)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String, status == "success",
               let newCount = json["new_count"] as? Int {
                
                // 성공 시 화면의 하트 상태와 숫자를 즉시 갱신
                DispatchQueue.main.async {
                    self.itemDetail?.is_liked.toggle()
                    self.itemDetail?.like_count = newCount
                }
            }
        }.resume()
    }
    
    // [POST] 판매 상태 변경 (판매중/예약중/판매완료)
    // 단순히 상태만 바꿀 때 사용합니다 (판매중 <-> 예약중)
    func updateStatus(_ newStatus: Int) {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/update_market_status.php") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"
        request.httpBody = "market_id=\(marketItemId)&status=\(newStatus)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            // 서버 반영 후 로컬 UI 상태값도 변경하여 즉시 반영
            DispatchQueue.main.async { self.itemDetail?.status = newStatus }
        }.resume()
    }
    
    // [POST] 게시물 삭제
    func deletePost() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/delete_market.php") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"
        request.httpBody = "market_id=\(marketItemId)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                DispatchQueue.main.async {
                    // 삭제 성공 여부에 따라 알림 메시지 설정
                    self.alertMessage = (json["status"] as? String == "success") ? "게시물이 삭제되었습니다." : "삭제 실패"
                    self.shouldDismiss = true // 알림창 띄우기 -> 확인 누르면 화면 닫힘
                }
            }
        }.resume()
    }
    
    // 날짜 문자열에서 날짜 부분만 잘라내는 유틸리티 함수 (예: "2024-12-01 14:00" -> "2024-12-01")
    func getTimeAgo(dateString: String) -> String {
        return dateString.components(separatedBy: " ").first ?? dateString
    }
}

// MARK: - 구매자 선택 화면 (SelectBuyerSheet)
// 판매자가 '판매완료'를 눌렀을 때, 누구에게 팔았는지 선택하는 화면입니다.
struct SelectBuyerSheet: View {
    let marketItem: MarketDetail
    @Binding var isPresented: Bool // 부모 뷰의 시트 제어 변수
    var onComplete: () -> Void     // 거래 완료 후 호출할 콜백 함수
    
    @State private var buyers: [ChatBuyer] = [] // 채팅한 사람들 목록
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("구매자 목록 불러오는 중...")
                } else if buyers.isEmpty {
                    // 채팅한 사람이 없으면 안내 문구 표시
                    Text("채팅을 나눈 사용자가 없습니다.\n거래 상대를 선택할 수 없습니다.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // 채팅한 사람들 목록 표시
                    List(buyers) { buyer in
                        Button(action: {
                            // 구매자 선택 시 거래 확정 함수 호출
                            confirmTransaction(buyerId: buyer.buyer_id)
                        }) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                Text(buyer.buyer_name)
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Spacer()
                                Text("선택")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("구매자 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { isPresented = false }
                }
            }
            .onAppear {
                fetchChatBuyers() // 화면이 뜨면 채팅한 사람 목록 불러오기
            }
        }
    }
    
    // [GET] 채팅한 사람들 목록 가져오기 API
    func fetchChatBuyers() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/get_chat_buyers.php?market_id=\(marketItem.market_id)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([ChatBuyer].self, from: data) {
                    DispatchQueue.main.async {
                        self.buyers = decoded
                        self.isLoading = false
                    }
                }
            }
        }.resume()
    }
    
    // [POST] 거래 확정 API (판매완료 처리 + 내역 저장)
    func confirmTransaction(buyerId: Int) {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/complete_transaction.php") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"
        
        let body = "market_id=\(marketItem.market_id)&seller_id=\(marketItem.seller_id)&buyer_id=\(buyerId)&price=\(marketItem.price)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                onComplete()        // 부모 뷰 새로고침 요청
                isPresented = false // 창 닫기
            }
        }.resume()
    }
}

// MARK: - Models (데이터 구조체)
// 서버 JSON 응답과 키 이름이 일치해야 합니다.
struct MarketDetail: Codable {
    let market_id: Int
    let seller_id: Int
    let title: String
    let description: String
    let price: Int
    let image_url: String?
    let created_at: String
    let main_category: String?
    // 값이 변할 수 있는 속성은 var로 선언
    var like_count: Int
    var is_liked: Bool
    var status: Int
}

// 채팅한 구매자 정보 구조체
struct ChatBuyer: Codable, Identifiable {
    let buyer_id: Int
    let buyer_name: String
    
    var id: Int { buyer_id }
}

// MARK: - EditPostView (게시물 수정 화면)
// 모달 시트로 띄워지는 수정 뷰입니다.
struct EditPostView: View {
    let item: MarketDetail
    @Binding var isPresented: Bool // 부모 뷰의 시트 표시 여부를 제어
    var onUpdate: () -> Void       // 수정 완료 시 호출할 콜백 함수
    
    @State private var title: String = ""
    @State private var price: String = ""
    @State private var description: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("상품 정보") {
                    TextField("제목", text: $title)
                    TextField("가격", text: $price).keyboardType(.numberPad)
                }
                Section("상세 설명") {
                    TextEditor(text: $description).frame(height: 200)
                }
            }
            .navigationTitle("게시물 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { isPresented = false } }
                ToolbarItem(placement: .confirmationAction) { Button("완료") { updatePost() } }
            }
            .onAppear {
                // 화면 진입 시 기존 데이터 채워넣기
                title = item.title; price = String(item.price); description = item.description
            }
        }
    }
    
    // 수정 요청 API 호출
    func updatePost() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/update_market_content.php") else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"
        let body = "market_id=\(item.market_id)&title=\(title)&price=\(price)&description=\(description)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                onUpdate() // 부모 뷰에게 새로고침 요청
                isPresented = false // 창 닫기
            }
        }.resume()
    }
}

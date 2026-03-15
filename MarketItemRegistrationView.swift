import SwiftUI

// MARK: - 1. 데이터 모델 (Enums & Constants)

// [Enum 정의]
// String: 원시값(RawValue)을 문자열로 가짐 (예: .outer -> "아우터")
// CaseIterable: allCases를 통해 모든 케이스를 배열처럼 순회 가능하게 함 (Picker에서 사용)
// Identifiable: ForEach 등에서 고유성을 보장하기 위해 id 프로퍼티 요구
enum MainCategory: String, CaseIterable, Identifiable {
    case outer = "아우터"
    case top = "상의"
    case bottom = "하의"
    case dressSet = "원피스/세트"
    case shoes = "신발"
    case accessory = "악세사리"

    // Identifiable 준수를 위한 id. 원시값(한글 이름) 자체를 id로 사용
    var id: String { self.rawValue }

    // [연산 프로퍼티 (Computed Property)]
    // 대분류(self)가 무엇이냐에 따라 관련된 소분류 배열을 반환하는 로직
    // 뷰에서 대분류를 선택하면, 이 프로퍼티를 호출해 소분류 Picker의 내용을 갱신함
    var subCategories: [String] {
        switch self {
        case .outer:
            return ["가디건", "자켓", "집업/점퍼", "바람막이", "코트", "패딩", "플리스", "야상"]
        case .top:
            return ["후드", "맨투맨", "니트", "셔츠", "긴소매", "민소매", "반팔", "블라우스", "조끼"]
        case .bottom:
            return ["롱팬츠", "슬랙스", "데님", "숏팬츠", "미디스커트", "롱스커트", "미니스커트"]
        case .dressSet:
            return ["롱원피스", "투피스", "점프수트", "미니원피스"]
        case .shoes:
            return ["스니커즈", "샌들", "슬리퍼/쪼리", "플랫", "뮬", "워커", "부츠", "힐"]
        case .accessory:
            return ["귀걸이", "목걸이", "반지", "팔찌", "발찌", "시계", "패션안경", "선글라스", "벨트", "양말", "모자", "목도리"]
        }
    }
}

// DB의 color 테이블 'name' 컬럼과 일치
let allColors = [
    "빨강", "초록", "파랑", "노랑", "주황", "보라", "분홍", "하늘색",
    "남색", "갈색", "검정", "회색", "흰색"
]

// DB의 materials 테이블 'name' 컬럼과 일치
let allMaterials = [
    "면", "린넨", "데님", "울/캐시미어/앙고라",
    "폴리에스터/나일론/스판덱스", "레이온", "코듀로이", "기모"
]

let allBodyTypes = ["웨이브", "내추럴", "스트레이트"] // (DB 'body_shape' 테이블과 일치)

// (★★★수정★★★) 방금 올려주신 'style' 테이블의 'name' 컬럼과 일치시킵니다.
let allStyles = [
    "캐주얼", "스트릿", "빈티지", "페미닌", "코스프레", "오피스", "꾸안꾸", "발레코어", "청청"
]


// MARK: - 2. 다중 선택 모달 뷰 (Helper)
// (이 뷰는 수정 사항이 없습니다)
struct MultiSelectionView: View {
    let title: String
    let options: [String]
    
    // [Binding]
    // 부모 뷰(MarketItemRegistrationView)가 가진 데이터를 '참조'합니다.
    // 여기서 값을 바꾸면 부모 뷰의 데이터도 실제로 바뀝니다.
    @Binding var selectedItems: [String]
    
    // [Environment]
    // 현재 화면의 상태를 제어하는 환경 변수. 여기서는 화면 닫기(dismiss) 기능을 가져옴
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(options, id: \.self) { item in
                Button(action: {
                    // [선택/해제 로직]
                    // 이미 선택된 항목이면 배열에서 제거, 아니면 추가
                    if selectedItems.contains(item) {
                        selectedItems.removeAll { $0 == item }
                    } else {
                        selectedItems.append(item)
                    }
                }) {
                    HStack {
                        Text(item)
                        Spacer()
                        // 선택된 항목이면 파란색 체크 표시
                        if selectedItems.contains(item) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary) // 버튼 글자색 검정(기본) 유지
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss() // 화면 닫기
                    }
                }
            }
        }
    }
}

// MARK: - 3. 마켓 아이템 등록 뷰 (Main View)

struct MarketItemRegistrationView: View {
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State Variables
    // @State: 뷰 내부에서 관리하는 데이터. 값이 바뀌면 뷰가 다시 그려짐(Re-render).
    
    @State private var userId: Int? = nil

    // 2. 카테고리
    @State private var mainCategory: MainCategory = .top // 초기값: 상의
    @State private var subCategory: String = ""
    
    // 3. 직접 입력 (title, description 추가됨)
    @State private var title: String = ""
    @State private var brand: String = ""
    @State private var price: String = ""
    @State private var description: String = ""

    // 4. 모달 선택 (배열로 여러 개 저장)
    @State private var selectedColors: [String] = []
    @State private var selectedMaterials: [String] = []
    @State private var selectedBodyTypes: [String] = []
    @State private var selectedStyles: [String] = []

    // 5. 모달(Sheet) 표시 여부 (true면 화면이 뜸)
    @State private var showingColorPicker = false
    @State private var showingMaterialPicker = false
    @State private var showingBodyTypePicker = false
    @State private var showingStylePicker = false

    // --- 네트워킹 및 UI 상태 ---
    @State private var isRegistering = false // 로딩 중인지 여부
    @State private var showingAlert = false  // 알림창 표시 여부
    @State private var alertMessage = ""     // 알림창 내용
    @State private var registrationSuccess = false // 등록 성공 여부
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form { // 입력 양식에 최적화된 리스트 UI
                // --- 1. 사진 첨부 --- (제거됨)

                // --- 2. 카테고리 선택 ---
                Section(header: Text("카테고리 선택")) {
                    // [Picker: 대분류]
                    // selection: $mainCategory 바인딩을 통해 선택 시 변수값 자동 변경
                    Picker("대분류", selection: $mainCategory) {
                        ForEach(MainCategory.allCases) { category in
                            // .tag(): 선택되었을 때 변수에 저장될 실제 값
                            Text(category.rawValue).tag(category)
                        }
                    }
                       
                    // [Picker: 소분류]
                    Picker("소분류", selection: $subCategory) {
                        Text("소분류 없음").tag("")
                        // mainCategory가 바뀔 때마다 .subCategories가 달라져서 목록이 갱신됨
                        ForEach(mainCategory.subCategories, id: \.self) { sub in
                            Text(sub).tag(sub)
                        }
                    }
                    // [.onChange]
                    // 대분류(mainCategory)가 바뀌면 소분류 선택값(subCategory)을 초기화
                    .onChange(of: mainCategory) { _, _ in
                        subCategory = ""
                    }
                }
              
                // --- 3. 직접 입력 항목 ---
                Section(header: Text("상품 정보 (필수 입력)")) {
                    TextField("제목", text: $title)
                    TextField("브랜드", text: $brand)
                    // 숫자 키패드 표시
                    TextField("가격 (숫자만 입력)", text: $price)
                        .keyboardType(.numberPad)
                   
                    // [여러 줄 입력창]
                    VStack(alignment: .leading, spacing: 5) {
                        ZStack(alignment: .topLeading) {
                            // placeholder 구현 (내용이 없을 때만 회색 글씨 표시)
                            if description.isEmpty {
                                Text("상품 설명을 입력하세요...")
                                    .foregroundColor(Color(UIColor.placeholderText))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                            
                            TextEditor(text: $description)
                                .frame(minHeight: 120) // 최소 높이 지정
                        }
                    }
                    .padding(.vertical, 5)
                }

                // --- 4. 모달 선택 항목 ---
                Section(header: Text("상세 정보 (선택)")) {
                    // 아래에 정의한 헬퍼 함수(modalButton)를 사용하여 코드 중복 감소
                    modalButton(title: "색상", selection: $selectedColors, isPresented: $showingColorPicker)
                    modalButton(title: "재질", selection: $selectedMaterials, isPresented: $showingMaterialPicker)
                    modalButton(title: "어울리는 체형", selection: $selectedBodyTypes, isPresented: $showingBodyTypePicker)
                    modalButton(title: "스타일", selection: $selectedStyles, isPresented: $showingStylePicker)
                }
            }
            .navigationTitle("마켓 아이템 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isRegistering {
                        ProgressView() // 등록 중이면 뱅글뱅글 로딩 표시
                    } else {
                        Button("등록") {
                            // [Task]: 비동기 작업(await)을 실행하기 위한 블록
                            // 버튼 클릭은 동기적이지만, 네트워크 통신은 비동기라 Task로 감싸야 함
                            Task {
                                await registerItem()
                            }
                        }
                        // 필수 입력값이 없거나 로딩 중이면 버튼 비활성화
                        .disabled(userId == nil || title.isEmpty || price.isEmpty || isRegistering)
                    }
                }
            }
            .onAppear {
                // 화면이 뜰 때 UserDefaults에서 유저 ID 불러오기
                self.userId = Int(UserDefaults.standard.string(forKey: "userID") ?? "")
            }
            // --- 5. Sheet(모달) 정의 ---
            // $showing... 변수가 true가 되면 해당 sheet가 화면 위로 올라옴
            .sheet(isPresented: $showingColorPicker) {
                MultiSelectionView(title: "색상 선택", options: allColors, selectedItems: $selectedColors)
            }
            .sheet(isPresented: $showingMaterialPicker) {
                MultiSelectionView(title: "재질 선택", options: allMaterials, selectedItems: $selectedMaterials)
            }
            .sheet(isPresented: $showingBodyTypePicker) {
                MultiSelectionView(title: "체형 선택", options: allBodyTypes, selectedItems: $selectedBodyTypes)
            }
            .sheet(isPresented: $showingStylePicker) {
                // (★수정) 새로 업데이트된 allStyles 배열을 사용
                MultiSelectionView(title: "스타일 선택", options: allStyles, selectedItems: $selectedStyles)
            }
            // 알림창 (성공 또는 실패 메시지)
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(registrationSuccess ? "성공" : "오류"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인")) {
                        if registrationSuccess {
                            dismiss() // 성공 시 뷰 닫기
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Functions

    // [모달 버튼 UI 생성 함수]
    // selection: 선택된 배열을 보여주기 위해 Binding으로 받음
    // isPresented: 버튼 클릭 시 어떤 모달을 띄울지 제어하기 위한 Bool Binding
    private func modalButton(title: String, selection: Binding<[String]>, isPresented: Binding<Bool>) -> some View {
        Button(action: { isPresented.wrappedValue = true }) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                // 선택된 게 없으면 "선택", 있으면 콤마(,)로 연결해서 보여줌
                Text(selection.wrappedValue.isEmpty ? "선택" : selection.wrappedValue.joined(separator: ", "))
                    .foregroundColor(.gray)
            }
        }
    }

    
    // [서버 통신 함수 (async)]
    private func registerItem() async {
        isRegistering = true
        registrationSuccess = false

        // 1. 입력값 검증 (가격이 숫자인지, 0보다 큰지)
        // guard let: 조건이 맞지 않으면(else) 함수를 즉시 종료(return)
        guard let priceInt = Int(price), priceInt > 0 else {
            self.alertMessage = "가격이 유효하지 않습니다. 숫자만 입력해주세요."
            self.showingAlert = true
            self.isRegistering = false
            return
        }
       
        // 제목 검증
        guard !title.isEmpty else {
            self.alertMessage = "제목을 입력해주세요."
            self.showingAlert = true
            self.isRegistering = false
            return
        }
       
        // 2. UserID 확인
        guard let id = userId else {
            self.alertMessage = "사용자 ID가 유효하지 않습니다. 앱을 다시 시작해주세요."
            self.showingAlert = true
            self.isRegistering = false
            return
        }
       
        // URL 생성 (Localhost)
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/register_market_item.php") else {
            self.alertMessage = "API URL이 잘못되었습니다. (IP주소를 확인하세요)"
            self.showingAlert = true
            self.isRegistering = false
            return
        }
       
        // 4. x-www-form-urlencoded 요청 생성
        // JSON 바디가 아닌, 일반적인 HTML Form 전송 방식입니다.
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
       
        // 5. HTTP Body 생성 (Query String 형식으로 데이터 조립)
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "userId", value: String(id)),
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "description", value: description),
            URLQueryItem(name: "mainCategory", value: mainCategory.rawValue),
            URLQueryItem(name: "subCategory", value: subCategory),
            URLQueryItem(name: "brand", value: brand),
            URLQueryItem(name: "price", value: String(priceInt)),
            
            // 배열 데이터는 그대로 보낼 수 없으므로 JSON 문자열로 변환해서 보냄
            // 예: ["Red", "Blue"] -> "[\"Red\", \"Blue\"]" (String)
            URLQueryItem(name: "colors", value: jsonString(from: selectedColors)),
            URLQueryItem(name: "materials", value: jsonString(from: selectedMaterials)),
            URLQueryItem(name: "bodyTypes", value: jsonString(from: selectedBodyTypes)),
            // (★수정) 새로 업데이트된 DB 기반의 스타일 전송
            URLQueryItem(name: "styles", value: jsonString(from: selectedStyles))
        ]
       
        // 조립된 쿼리 아이템을 데이터(Data) 형태로 변환
        guard let httpBody = components.query?.data(using: .utf8) else {
            self.alertMessage = "요청 데이터 생성에 실패했습니다. (특수문자 등 확인)"
            self.showingAlert = true
            self.isRegistering = false
            return
        }
       
        request.httpBody = httpBody

        // 6. URLSession으로 데이터 전송 (네트워크 통신 시작)
        do {
            // try await: 데이터가 올 때까지 여기서 코드 실행을 일시 정지(대기)함
            let (data, response) = try await URLSession.shared.data(for: request)
           
            // HTTP 응답 코드 확인
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "서버 응답이 없습니다."])
            }
           
            // 200 OK가 아니면 에러 처리
            guard httpResponse.statusCode == 200 else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("--- 서버 응답 오류 ---")
                print("Status Code: \(httpResponse.statusCode)")
                print("Response Body: \(responseString)")
                print("---------------------")
                throw NSError(domain: "NetworkError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "서버 응답 오류 (Code: \(httpResponse.statusCode)). 응답: \(responseString.prefix(100))..."])
            }

            // 7. 서버 응답 (JSON) 파싱
            // 서버에서 {"status": "success", "message": "..."} 형태로 준다고 가정
            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
              
                if let status = jsonResponse["status"] as? String, status == "success" {
                    self.alertMessage = jsonResponse["message"] as? String ?? "등록에 성공했습니다."
                    self.registrationSuccess = true
                } else {
                    let phpMessage = jsonResponse["message"] as? String ?? "알 수 없는 서버 오류"
                    let phpError = jsonResponse["php_error"] as? String ?? ""
                   
                    self.alertMessage = "등록 실패: \(phpMessage)\n\(phpError)"
                }
            } else {
                let rawResponse = String(data: data, encoding: .utf8) ?? "파싱할 수 없는 응답"
                self.alertMessage = "서버 응답 형식 오류. \(rawResponse.prefix(100))..."
            }
           
        } catch {
            self.alertMessage = "네트워크 오류: \(error.localizedDescription)"
            print("네트워크 오류 상세: \(error)")
        }
       
        // 8. 로딩 종료 및 알림 표시
        // @State 변수가 바뀌므로 UI(Alert)가 갱신됨
        self.isRegistering = false
        self.showingAlert = true
    }

    
    /// [String] 배열을 JSON 문자열로 변환하는 헬퍼 함수
    /// PHP 서버가 배열을 직접 받을 수 없으므로 문자열로 포장해서 보냄
    private func jsonString(from array: [String]) -> String {
        guard !array.isEmpty,
              let data = try? JSONEncoder().encode(array),
              let string = String(data: data, encoding: .utf8) else {
            return "[]" // 비어있거나 실패 시 빈 JSON 배열("[]") 반환
        }
        return string
    }
}

// MARK: - Preview
#Preview {
    MarketItemRegistrationView()
}

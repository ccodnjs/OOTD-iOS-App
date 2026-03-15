//
//  ClosetView.swift
//  projectOOTD
//
//  Created by mac19 on 10/27/25.
//

import Foundation
import SwiftUI

// MARK: - 1. 데이터 모델

struct ClothingItem: Identifiable, Codable {
    let id = UUID()
    var pkey: Int?
    var name: String
    var category: String
    var subcategory: String
    var bodytype: String
    var brand: String
    var style: String
    var color: String
    var material: String
    var season: String
    var imageURL: String?

    private enum CodingKeys: String, CodingKey {
        case pkey, name, category, subcategory, bodytype, brand, style, color, material, season, imageURL
    }
}

struct ClothingItemsResponse: Codable {
    var items: [ClothingItem]
}

// OOTD 추천 결과 모델
struct Outfit: Identifiable {
    let id = UUID()
    let name: String
    let items: [ClothingItem]
}

// MARK: - 상수 정의
struct Category: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subcategories: [String]
}

let categories = [
    Category(name: "모자", subcategories: ["비니", "볼캡","베레모","귀도리","스냅백"]),
    Category(name: "상의", subcategories: ["후드", "맨투맨", "니트", "셔츠", "긴소매", "민소매", "반팔", "블라우스", "조끼"]),
    Category(name: "아우터", subcategories: ["가디건", "자켓", "집업", "바람막이", "코트", "패딩", "폴리스", "야상"]),
    Category(name: "하의", subcategories: ["롱팬츠", "슬랙스", "데님", "숏팬츠", "미디스커트", "롱스커트", "미니스커트"]),
    Category(name: "원피스", subcategories: ["롱원피스", "투피스", "점프수트", "미니원피스"]),
    Category(name: "신발", subcategories: ["스니커즈", "샌들", "슬리퍼", "쪼리", "플랫", "뮬", "워커", "부츠", "힐"]),
    Category(name: "악세사리", subcategories: ["귀걸이", "목걸이", "반지", "시계", "패션안경", "선글라스", "벨트","머플러", "양말", "스타킹"])
]

struct BodyTypeOption: Identifiable, Hashable { let id = UUID(); let name: String }
let bodytypes = [BodyTypeOption(name: "내추럴"), BodyTypeOption(name: "웨이브"), BodyTypeOption(name: "스트레이트")]

struct StyleOption: Identifiable, Hashable { let id = UUID(); let name: String }
let styles = [
    StyleOption(name: "캐주얼"), StyleOption(name: "스트릿"), StyleOption(name: "빈티지"),
    StyleOption(name: "페미닌"), StyleOption(name: "코스프레"), StyleOption(name: "오피스"),
    StyleOption(name: "꾸안꾸"), StyleOption(name: "발레코어"), StyleOption(name: "청청")
]

struct ColorOption: Identifiable, Hashable { let id = UUID(); let name: String }
let colors = [
    ColorOption(name: "빨강"), ColorOption(name: "주황"), ColorOption(name: "노랑"),
    ColorOption(name: "초록"), ColorOption(name: "파랑"), ColorOption(name: "보라"),
    ColorOption(name: "분홍"), ColorOption(name: "갈색"), ColorOption(name: "검정"),
    ColorOption(name: "회색"), ColorOption(name: "흰색"), ColorOption(name: "하늘색"),
    ColorOption(name: "남색")
]

struct MaterialOption: Identifiable, Hashable { let id = UUID(); let name: String }
let basicMaterials = [
    MaterialOption(name: "면"),
    MaterialOption(name: "린넨"),
    MaterialOption(name: "데님"),
    MaterialOption(name: "울/캐시미어/앙고라"),
    MaterialOption(name: "폴리에스터/나일론/스판덱스"),
    MaterialOption(name: "레이온"),
    MaterialOption(name: "코듀로이"),
    MaterialOption(name: "기모")
]

let accessoryMaterialOptions: [String: [String]] = [
    "귀걸이": ["금", "은", "보석", "기타"],
    "목걸이": ["금", "은", "보석", "기타"],
    "반지": ["금", "은", "보석", "기타"],
    "시계": ["스테인리스 스틸", "가죽 밴드", "나일론/러버/실리콘 밴드", "로즈골드/골드/블랙 도금 메탈", "세라믹/레진/플라스틱"],
    "패션안경": ["라운드형", "스퀘어형", "보스턴형", "웨이퍼러형", "캣아이형", "하프림/무테형", "오버사이즈형"],
    "선글라스": ["라운드형", "스퀘어형", "보스턴형", "웨이퍼러형", "캣아이형", "하프림/무테형", "오버사이즈형"],
    "벨트": ["가죽", "패브릭", "메탈/체인"],
    "양말": ["면", "기능성 합성 섬유", "울", "실크", "폴리스/극세사"],
    "스타킹": ["나일론/스판덱스(기본)", "망사/레이스", "기모"]
]

let seasons = ["봄", "여름", "가을", "겨울", "사계절"]

// MARK: - 추천 관리자 (수정됨: 공백 제거 및 셔플)
struct OOTDManager {
    func generateBasicOutfits(from items: [ClothingItem], count: Int = 3) -> [Outfit] {
        // ✅ 안전장치: 카테고리 이름의 앞뒤 공백을 제거하고 비교
        let tops = items.filter { $0.category.trimmingCharacters(in: .whitespaces) == "상의" }
        let bottoms = items.filter { $0.category.trimmingCharacters(in: .whitespaces) == "하의" }
        let outers = items.filter { $0.category.trimmingCharacters(in: .whitespaces) == "아우터" }

        var generatedOutfits: [Outfit] = []
        
        // 1. 상의 + 하의 조합 (랜덤 섞기)
        for top in tops.shuffled() {
            for bottom in bottoms.shuffled() {
                if generatedOutfits.count >= count { break }

                let outfitItems = [top, bottom]
                let name = "\(top.style) 룩 (\(top.color) & \(bottom.color))"

                generatedOutfits.append(Outfit(name: name, items: outfitItems))
            }
        }

        // 2. 아우터 추가 조합
        if generatedOutfits.count < count,
           let outer = outers.randomElement(),
           let top = tops.randomElement(),
           let bottom = bottoms.randomElement() {

            let outfitItems = [top, bottom, outer]
            generatedOutfits.append(Outfit(name: "아우터 매칭 (\(outer.name))", items: outfitItems))
        }

        return generatedOutfits
    }
}

// MARK: - 추천 뷰 (수정됨)
struct RecommendationView: View {
    let allItems: [ClothingItem]
    @State private var recommendedOutfits: [Outfit] = []
    @State private var isCalculating = true

    private let manager = OOTDManager()

    // ✅ 뷰 내부에서도 쓸 수 있게 헬퍼 함수 추가
    private func hasItem(for categoryName: String) -> Bool {
        // 1. 카테고리 이름이 직접 일치하거나
        // 2. 세부 카테고리(예: 맨투맨, 슬랙스)가 해당 카테고리 리스트에 포함되어 있거나
        let targetSubcategories = categories.first(where: { $0.name == categoryName })?.subcategories ?? []
        
        return allItems.contains { item in
            item.category == categoryName || targetSubcategories.contains(item.subcategory)
        }
    }

    var body: some View {
        VStack {
            if isCalculating {
                ProgressView("추천 생성 중...")
                    .padding()
            }
            // ✅ 수정됨: hasItem 함수를 사용해 더 정확하게 검사
            else if !hasItem(for: "상의") || !hasItem(for: "하의") {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("상의와 하의가 최소 1개씩 필요합니다.")
                        .foregroundColor(.gray)
                    
                    // 디버깅용 힌트 (어떤게 부족한지 보여줌)
                    Text("현재 인식된 옷: 상의 \(hasItem(for: "상의") ? "O" : "X"), 하의 \(hasItem(for: "하의") ? "O" : "X")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            else if recommendedOutfits.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("조건에 맞는 코디 조합을 찾지 못했어요.")
                        .foregroundColor(.gray)
                }
                .padding()
            }
            else {
                List(recommendedOutfits) { outfit in
                    VStack(alignment: .leading) {
                        Text("✨ \(outfit.name)")
                            .font(.headline)
                            .padding(.bottom, 2)
                        Divider()
                        ForEach(outfit.items) { item in
                            HStack {
                                if let urlString = item.imageURL, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color.gray.opacity(0.3)
                                    }
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(5)
                                    .clipped()
                                }
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .bold))
                                    // 디버깅을 위해 카테고리 정보를 함께 표시
                                    Text("\(item.subcategory) (\(item.category))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("데일리 OOTD")
        .onAppear {
            calculateOutfits()
        }
    }
    
    private func calculateOutfits() {
        isCalculating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.recommendedOutfits = manager.generateBasicOutfits(from: allItems)
            self.isCalculating = false
        }
    }
}

// MARK: - 아이템 추가 뷰 (로그인 연동)
struct AddItemView: View {
    @Binding var items: [ClothingItem]
    
    // ✅ 유저 ID 상태
    @State private var userId: Int? = nil

    @State private var name = ""
    @State private var selectedCategory: Category = categories[0]
    @State private var selectedSubCategory: String = categories[0].subcategories[0]
    @State private var selectedBodyType: BodyTypeOption = bodytypes[0]
    @State private var selectedStyle: StyleOption = styles[0]
    @State private var selectedColor: ColorOption = colors[0]
    @State private var selectedMaterial: MaterialOption = basicMaterials[0]
    @State private var selectedSeason: String = "사계절"
    @State private var brand = ""

    @State private var showAlert = false
    @Environment(\.dismiss) private var dismiss

    var currentMaterials: [MaterialOption] {
        if selectedCategory.name == "악세사리",
           let options = accessoryMaterialOptions[selectedSubCategory] {
            return options.map { MaterialOption(name: $0) }
        }
        return basicMaterials
    }

    var body: some View {
        Form {
            Section("기본 정보") {
                TextField("옷 이름", text: $name)
                TextField("브랜드", text: $brand)
            }

            Section("카테고리") {
                Picker("카테고리", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { Text($0.name).tag($0) }
                }
                Picker("세부", selection: $selectedSubCategory) {
                    ForEach(selectedCategory.subcategories, id: \.self) { Text($0) }
                }
            }

            Section("세부 정보") {
                Picker("체형", selection: $selectedBodyType) {
                    ForEach(bodytypes, id: \.self) { Text($0.name) }
                }
                Picker("스타일", selection: $selectedStyle) {
                    ForEach(styles, id: \.self) { Text($0.name) }
                }
                Picker("컬러", selection: $selectedColor) {
                    ForEach(colors, id: \.self) { Text($0.name) }
                }
                Picker("재질", selection: $selectedMaterial) {
                    ForEach(currentMaterials, id: \.self) { Text($0.name) }
                }
                Picker("계절", selection: $selectedSeason) {
                    ForEach(seasons, id: \.self) { Text($0) }
                }
            }

            Button("등록하기", action: registerItem)
                .frame(maxWidth: .infinity)
        }
        .navigationTitle("아이템 추가")
        .alert("아이템 등록 완료!", isPresented: $showAlert) {
            Button("확인") { dismiss() }
        }
        .onAppear {
            loadUserID() // ✅ 화면 켜질 때 유저 ID 로드
        }
        .onDisappear {
            if !currentMaterials.map({ $0.name }).contains(selectedMaterial.name) {
                selectedMaterial = currentMaterials[0]
            }
        }
    }
    
    // ✅ 유저 ID 로드 함수
    func loadUserID() {
        self.userId = Int(UserDefaults.standard.string(forKey: "userID") ?? "")
        print("AddItemView - 로드된 UserID: \(String(describing: userId))")
    }

    // 서버 등록
    private func registerItemToServer() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/add_item.php") else { return }
        
        // ✅ 로그인 안 되어 있으면 등록 막기
        guard let uid = userId else {
            print("로그인이 필요합니다.")
            return
        }

        var comp = URLComponents()
        comp.queryItems = [
            URLQueryItem(name: "user_id", value: String(uid)), // ✅ 실제 유저 ID 전송
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "category", value: selectedCategory.name),
            URLQueryItem(name: "subcategory", value: selectedSubCategory),
            URLQueryItem(name: "bodytype", value: selectedBodyType.name),
            URLQueryItem(name: "brand", value: brand),
            URLQueryItem(name: "style", value: selectedStyle.name),
            URLQueryItem(name: "color", value: selectedColor.name),
            URLQueryItem(name: "material", value: selectedMaterial.name),
            URLQueryItem(name: "season", value: selectedSeason),
            URLQueryItem(name: "image_url", value: "temp/path/\(name).jpg")
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        req.httpBody = (comp.query ?? "").data(using: .utf8)
        
        print("전송 데이터: \(comp.query ?? "")")

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                print("❌ 등록 통신 에러:", error.localizedDescription)
                return
            }
            guard let data = data else { return }

            if let resp = String(data: data, encoding: .utf8) {
                print("📡 서버 응답(등록): \(resp)")
                
                if resp.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: "SUCCESS") {
                    let pkeyString = resp.replacingOccurrences(of: "SUCCESS:", with: "")
                    let pkey = Int(pkeyString.trimmingCharacters(in: .whitespacesAndNewlines))

                    DispatchQueue.main.async {
                        items.append(ClothingItem(
                            pkey: pkey,
                            name: name,
                            category: selectedCategory.name,
                            subcategory: selectedSubCategory,
                            bodytype: selectedBodyType.name,
                            brand: brand,
                            style: selectedStyle.name,
                            color: selectedColor.name,
                            material: selectedMaterial.name,
                            season: selectedSeason,
                            imageURL: "temp/path/\(name).jpg"
                        ))
                        showAlert = true
                    }
                } else {
                    print("⚠️ 등록 실패: \(resp)")
                }
            }
        }.resume()
    }

    private func registerItem() {
        guard !name.isEmpty else { return }
        registerItemToServer()
    }
}

// MARK: - 메인 옷장 뷰 (로그인 연동)
struct ClosetView: View {
    @State private var items: [ClothingItem] = []
    @State private var isLoading = false
    @State private var isAddingItem = false
    @State private var isShowingRecommendation = false
    
    // ✅ 유저 ID 상태 관리
    @State private var userId: Int? = nil

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button("아이템 추가") { isAddingItem = true }
                    Spacer()
                    Button("OOTD 추천") { isShowingRecommendation = true }
                }
                .padding()

                NavigationLink("", destination: AddItemView(items: $items),
                               isActive: $isAddingItem)
                NavigationLink("", destination: RecommendationView(allItems: items),
                               isActive: $isShowingRecommendation)

                if isLoading {
                    ProgressView("로딩 중...")
                } else if items.isEmpty {
                    Text("등록된 아이템이 없습니다.\n(로그인 상태: \(userId != nil ? "O" : "X"))")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(items) { item in
                        VStack(alignment: .leading) {
                            Text(item.name).font(.headline)
                            Text("\(item.category) > \(item.subcategory) / \(item.season)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("디지털 옷장")
            .onAppear {
                loadUserID() // ✅ 유저 ID 불러오기
                fetchItems() // 아이템 불러오기
            }
        }
    }
    
    // ✅ UserDefaults에서 유저 ID 불러오기
    func loadUserID() {
        self.userId = Int(UserDefaults.standard.string(forKey: "userID") ?? "")
        print("ClosetView - 현재 로그인된 UserID: \(String(describing: userId))")
    }

    private func fetchItems() {
        // ✅ 유저 ID를 URL 파라미터로 추가 (GET 방식)
        guard let uid = userId else {
            print("로그인된 정보가 없어 아이템을 불러올 수 없습니다.")
            return
        }
        
        // URLComponents를 사용해 ?user_id=... 파라미터 추가
        var components = URLComponents(string: "http://124.56.5.77/projectOOTD/get_items.php")
        components?.queryItems = [
            URLQueryItem(name: "user_id", value: String(uid))
        ]
        
        guard let url = components?.url else { return }
        
        isLoading = true
        print("아이템 로드 요청 URL: \(url)")

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ 통신 에러:", error.localizedDescription)
                    return
                }
                
                guard let data = data else { return }

                do {
                    let decoded = try JSONDecoder().decode(ClothingItemsResponse.self, from: data)
                    self.items = decoded.items
                    print("✅ 아이템 \(decoded.items.count)개 로드 성공")
                } catch {
                    print("❌ JSON 디코딩 오류:", error)
                    if let rawString = String(data: data, encoding: .utf8) {
                        print("📡 서버 원본 응답: \(rawString)")
                    }
                }
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ClosetView()
    }
}

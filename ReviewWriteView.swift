import SwiftUI

// MARK: - 후기 작성 화면 (공용)
struct ReviewWriteView: View {
    let txId: Int
    @Binding var isPresented: Bool
    var onComplete: () -> Void
    
    @State private var rating: Int = 5
    @State private var content: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                // 별점 입력 섹션
                Section(header: Text("별점")) {
                    HStack {
                        Spacer()
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .font(.largeTitle)
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    rating = index
                                }
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
                // 후기 내용 입력 섹션
                Section(header: Text("후기 내용")) {
                    TextEditor(text: $content)
                        .frame(height: 150)
                        .overlay(
                            Group {
                                if content.isEmpty {
                                    Text("솔직한 거래 후기를 남겨주세요.")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 5)
                                        .padding(.top, 8)
                                }
                            }, alignment: .topLeading
                        )
                }
            }
            .navigationTitle("후기 작성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { submitReview() }
                        .disabled(content.isEmpty)
                }
            }
        }
    }
    
    // [수정됨] POST 전송 로직 개선
    func submitReview() {
        print("🚀 전송 시작 - ID: \(txId), 별점: \(rating)") // 디버깅 로그
        
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/write_review.php") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 1. 헤더 설정 (PHP가 $_POST로 인식하기 위해 필수)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // 2. 한글/특수문자 인코딩
        let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // 3. 바디 데이터 생성
        let body = "tx_id=\(txId)&rating=\(rating)&content=\(encodedContent)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 에러 발생: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("📩 서버 응답: \(responseString)")
                
                // 성공 여부 확인 (JSON 파싱 없이 간단히 문자열로 체크)
                if responseString.contains("success") {
                    DispatchQueue.main.async {
                        onComplete() // 부모 뷰 갱신
                        isPresented = false // 창 닫기
                    }
                } else {
                    print("⚠️ 서버 저장 실패. 응답을 확인하세요.")
                }
            }
        }.resume()
    }
}

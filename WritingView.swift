//
//  WritingView.swift
//  projectOOTD
//
//  Created by mac19 on 10/27/25.
//

import SwiftUI

struct WritingView: View {
    // MARK: - State Variables
    @State private var postContent = ""
    // UserDefaults에서 자동으로 가져오기 (매개변수 필요 없음)
    @AppStorage("userID") private var userId: Int = 0
    
    @State public var styleId: Int = 1
    @State private var openPhoto = false
    @State private var image = UIImage() // 실제 이미지가 들어갈 곳
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var registrationSuccessful = false
    
    // 스타일 데이터 (ID, 이름)
    let styles = [
        (1, "캐주얼"), (2, "스트릿"), (3, "빈티지"),
        (4, "페미닌"), (5, "코스프레"), (6, "오피스"),
        (7, "꾸안꾸"), (8, "발레코어"), (9, "청청")
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // 배경색 (살짝 회색빛)
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    
                    // 성공 시 이동할 링크 (보이지 않게 처리)
                    NavigationLink(
                        destination: Text("등록이 완료되었습니다.")
                            .font(.title)
                            .fontWeight(.bold),
                        isActive: $registrationSuccessful,
                        label: { EmptyView() }
                    )
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // 1. 사진 첨부 영역
                            Button(action: {
                                // TODO: 이미지 피커 연동 필요
                                openPhoto = true
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .frame(height: 250)
                                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    
                                    VStack(spacing: 10) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        Text("사진을 추가하려면 터치하세요")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 2. 텍스트 입력 영역
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                
                                if postContent.isEmpty {
                                    Text("오늘의 코디에 대해 설명해주세요...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                }
                                
                                TextEditor(text: $postContent)
                                    .scrollContentBackground(.hidden) // 기본 배경 제거
                                    .padding(12)
                                    .frame(minHeight: 150)
                            }
                            .frame(height: 150)
                            
                            // 3. 스타일 선택 영역 (가로 스크롤)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("스타일 태그")
                                    .font(.headline)
                                    .padding(.leading, 5)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(styles, id: \.0) { id, name in
                                            Button(action: {
                                                withAnimation {
                                                    styleId = id
                                                }
                                            }) {
                                                Text(name)
                                                    .font(.subheadline)
                                                    .fontWeight(styleId == id ? .bold : .regular)
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal, 16)
                                                    .background(styleId == id ? Color.black : Color.white)
                                                    .foregroundColor(styleId == id ? .white : .black)
                                                    .cornerRadius(20)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: styleId == id ? 0 : 1)
                                                    )
                                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 5)
                                    .padding(.bottom, 10) // 그림자 잘림 방지
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // 4. 하단 등록 버튼
                    Button(action: {
                        if postContent.isEmpty {
                            self.alertMessage = "게시물 내용을 입력해주세요."
                            self.registrationSuccessful = false
                            self.showAlert = true
                        } else {
                            registerPost()
                        }
                    }) {
                        Text("게시물 등록")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(postContent.isEmpty ? Color.gray : Color.black) // 내용 없으면 회색
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                    .disabled(postContent.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
            .navigationTitle("글쓰기")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("알림"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인"))
                )
            }
        }
    }
    
    // MARK: - Network Function
    func registerPost() {
        // 실제 IP 주소로 변경하세요
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/register_post.php") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 데이터 전송
        let body = "userid=\(userId)&postcontent=\(postContent)&styleid=\(styleId)"
        print("서버로 보내는 데이터: \(body)")
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print(error)
                DispatchQueue.main.async {
                    self.alertMessage = "네트워크 오류: \(error.localizedDescription)"
                    self.showAlert = true
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.alertMessage = "서버 응답 없음"
                    self.showAlert = true
                }
                return
            }
            
            let responseString = String(decoding: data, as: UTF8.self)
            print("서버로부터 받은 원본 응답: \(responseString)")
            
            DispatchQueue.main.async {
                if !responseString.isEmpty {
                    // 성공 시 처리 (필요하다면 JSON 파싱으로 더 정교하게 확인)
                    self.registrationSuccessful = true
                } else {
                    self.alertMessage = "등록 실패 (서버 응답 없음)"
                    self.registrationSuccessful = false
                    self.showAlert = true
                }
            }
            
        }.resume()
    }
}

#Preview {
    WritingView()
}

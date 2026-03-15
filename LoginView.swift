import SwiftUI

struct LoginView: View {
    
    @State var email:String = ""
    @State var pwd:String = ""
    @State var isSucceedLogin: Bool = false
    @State var showSignUp: Bool = false
    
    var body: some View {
        
        NavigationView {
            VStack(spacing: 20) {
                
                Text("로그인")
                    .font(.title)
                    .bold()
                
                HStack {
                    Text("Email")
                    TextField("user@example.com", text: $email)
                        .textInputAutocapitalization(.never)
                }
                
                HStack {
                    Text("PWD")
                    SecureField("비밀번호 입력", text: $pwd)
                }
                
                // -----------------------------
                // 로그인 버튼
                // -----------------------------
                Button("로그인") {
                    
                    print("로그인 시도: \(email)")
                    
                    // 기본 검사
                    if email.isEmpty || !email.contains("@") {
                        print("이메일 오류")
                        return
                    }
                    if pwd.isEmpty {
                        print("비밀번호 입력 필요")
                        return
                    }
                    
                    // 서버 URL
                    guard let url = URL(string: "http://124.56.5.77/projectOOTD/login.php") else {
                        print("URL 오류")
                        return
                    }
                    
                    let body = "email=\(email)&pwd=\(pwd)"
                    let encodedData = body.data(using: .utf8)
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = encodedData
                    
                    // 서버 통신
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        
                        if let error = error {
                            print("에러:", error)
                            return
                        }
                        guard let data = data else {
                            print("데이터 없음")
                            return
                        }
                        
                        // 서버 응답 출력
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("서버 응답:", json)
                            
                            if let result = json["result"] as? Int, result == 1 {
                                
                                // user_id 저장
                                if let userId = json["user_id"] as? Int {
                                    UserDefaults.standard.set(userId, forKey: "userID")
                                    print("UserDefaults 저장 userID =", userId)
                                }
                                
                                // 로그인 성공 이동
                                DispatchQueue.main.async {
                                    isSucceedLogin = true
                                }
                            } else {
                                print("로그인 실패")
                            }
                        } else {
                            print("JSON 파싱 실패")
                        }
                        
                    }.resume()
                    
                }
                
                
                // 로그인 성공 → 메인탭뷰 이동
                .fullScreenCover(isPresented: $isSucceedLogin) {
                    MainTabView()
                }
                
                // -----------------------------
                // 회원가입 버튼
                // -----------------------------
                Button("회원가입") {
                    showSignUp = true
                }
                
                NavigationLink(destination: SignUpView(), isActive: $showSignUp) {
                    EmptyView()
                }
            }
            .padding()
        }
    }
}

#Preview {
    LoginView()
}


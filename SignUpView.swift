import SwiftUI


struct Signup {
    var email: String
    var id: String
    var pwd: String
    var name: String
    var birth: String
}

struct SignUpView: View {
    

    let styleList = [
        (1, "캐주얼"),
        (2, "스트릿"),
        (3, "빈티지"),
        (4, "페미닌"),
        (5, "코스프레"),
        (6, "오피스"),
        (7, "꾸안꾸"),
        (8, "발레코어"),
        (9, "청청")
    ]
    
    let colorList = [
        (1,  "빨강"),
        (2,  "초록"),
        (3,  "파랑"),
        (4,  "노랑"),
        (5,  "주황"),
        (6,  "보라"),
        (7,  "분홍"),
        (8,  "하늘색"),
        (9,  "남색"),
        (10, "갈색"),
        (11, "검정"),
        (12, "회색"),
        (13, "흰색")
    ]
    
    let bodyShapeList = [
        (1, "내추럴"),
        (2, "스트레이트"),
        (3, "웨이브")
    ]
    

    @State private var signup = Signup(email: "", id: "", pwd: "", name: "", birth: "")
    @State private var birthDate = Date()
    
    @State private var selectedStyleIds: [Int] = []
    @State private var selectedColorIds: [Int] = []
    @State private var selectedBodyShapeId: Int = 1
    
    @State private var isSucceedSignup = false
    @State private var showAlert = false
    @State private var alertMsg = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    
                    Text("회원가입")
                        .font(.title)
                        .bold()
                        .padding(.bottom, 10)
                    
        
                    Group {
                        HStack {
                            Text("Email")
                            TextField("user@example.com", text: $signup.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                        }
                        
                        HStack {
                            Text("ID")
                            TextField("아이디 입력", text: $signup.id)
                                .textInputAutocapitalization(.never)
                        }
                        
                        HStack {
                            Text("PWD")
                            SecureField("비밀번호 입력", text: $signup.pwd)
                        }
                        
                        HStack {
                            Text("이름")
                            TextField("이름 입력", text: $signup.name)
                        }
                        
                        DatePicker("생년월일", selection: $birthDate, displayedComponents: .date)
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    // 스타일 다중 선택
                    VStack(alignment: .leading, spacing: 6) {
                        Text("스타일 (복수 선택 가능)")
                            .font(.headline)
                        ForEach(styleList, id: \.0) { item in
                            let id = item.0
                            let name = item.1
                            Button {
                                toggleStyle(id: id)
                            } label: {
                                HStack {
                                    Image(systemName: selectedStyleIds.contains(id) ? "checkmark.square.fill" : "square")
                                    Text(name)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // 색상 다중 선택
                    VStack(alignment: .leading, spacing: 6) {
                        Text("선호 색상 (복수 선택 가능)")
                            .font(.headline)
                        ForEach(colorList, id: \.0) { item in
                            let id = item.0
                            let name = item.1
                            Button {
                                toggleColor(id: id)
                            } label: {
                                HStack {
                                    Image(systemName: selectedColorIds.contains(id) ? "checkmark.square.fill" : "square")
                                    Text(name)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // 체형
                    VStack(alignment: .leading, spacing: 6) {
                        Text("체형")
                            .font(.headline)
                        Picker("체형 선택", selection: $selectedBodyShapeId) {
                            ForEach(bodyShapeList, id: \.0) { item in
                                Text(item.1).tag(item.0)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    

                    Button("가입하기") {
                        validateAndSend()
                    }
                    .padding()
                    
                    NavigationLink(destination: MainTabView(), isActive: $isSucceedSignup) {
                        EmptyView()
                    }
                }
                .padding()
            }

        }
    }
    

    
    func toggleStyle(id: Int) {
        if let index = selectedStyleIds.firstIndex(of: id) {
            selectedStyleIds.remove(at: index)
        } else {
            selectedStyleIds.append(id)
        }
    }
    
    func toggleColor(id: Int) {
        if let index = selectedColorIds.firstIndex(of: id) {
            selectedColorIds.remove(at: index)
        } else {
            selectedColorIds.append(id)
        }
    }
    

    
    func validateAndSend() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        signup.birth = formatter.string(from: birthDate)
        
        if signup.email.isEmpty || !signup.email.contains("@") {
            alertMsg = "이메일 형식을 확인하세요."
            showAlert = true
            return
        }
        if signup.id.isEmpty {
            alertMsg = "아이디를 입력하세요."
            showAlert = true
            return
        }
        if signup.pwd.isEmpty {
            alertMsg = "비밀번호를 입력하세요."
            showAlert = true
            return
        }
        if signup.name.isEmpty {
            alertMsg = "이름을 입력하세요."
            showAlert = true
            return
        }
        if selectedStyleIds.isEmpty {
            alertMsg = "스타일을 최소 1개 이상 선택하세요."
            showAlert = true
            return
        }
        if selectedColorIds.isEmpty {
            alertMsg = "선호 색상을 최소 1개 이상 선택하세요."
            showAlert = true
            return
        }
        
        sendToServer()
    }
    
    func sendToServer() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/signup.php") else {
            alertMsg = "URL 오류"
            showAlert = true
            return
        }
        
        let styleString = selectedStyleIds.map { String($0) }.joined(separator: ",")
        let colorString = selectedColorIds.map { String($0) }.joined(separator: ",")
        
        let body =
        "email=\(signup.email)" +
        "&id=\(signup.id)" +
        "&pwd=\(signup.pwd)" +
        "&name=\(signup.name)" +
        "&birth=\(signup.birth)" +
        "&style=\(styleString)" +
        "&color=\(colorString)" +
        "&bodyShape=\(selectedBodyShapeId)"
        
        let encodedData = body.data(using: .utf8)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = encodedData
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("에러:", error)
                return
            }
            guard let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("서버 응답:", json)
                    if let result = json["result"] as? Int, result == 1 {
                        if let userId = json["user_id"] as? Int {
                            UserDefaults.standard.set(userId, forKey: "userID")
                            print("UserDefaults userID 저장:", userId)
                        }
                        DispatchQueue.main.async {
                            isSucceedSignup = true
                            alertMsg = "회원가입 성공"
                            showAlert = true
                        }
                    } else {
                        DispatchQueue.main.async {
                            alertMsg = json["error"] as? String ?? "회원가입 실패"
                            showAlert = true
                        }
                    }
                }
            } catch {
                print("JSON 파싱 오류:", error)
                if let s = String(data: data, encoding: .utf8) { print("raw:", s) }
            }
        }.resume()
    }
}

#Preview {
    SignUpView()
}

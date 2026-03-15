import SwiftUI

struct FollowItem: Codable, Identifiable {
    let follows_id: Int
    let follow_id: Int
    let name: String
    let email: String
    
    var id: Int { follows_id }
}

struct FollowListResponse: Codable {
    let result: Int
    let follows: [FollowItem]?
    let error: String?
}

struct SimpleResponse: Codable {
    let result: Int
    let error: String?
}

struct SearchUserItem: Codable {
    let user_id: Int
    let name: String
    let email: String
}

struct SearchUserResponse: Codable {
    let result: Int
    let users: [SearchUserItem]?
    let error: String?
}

struct FollowListView: View {
    
    @State private var keyword: String = ""
    @State private var followList: [FollowItem] = []
    @State private var searchResults: [SearchUserItem] = []
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                
                Text("팔로우")
                    .font(.title)
                    .bold()
                    .padding(.top, 16)
                    .padding(.leading, 16)
                
                // 검색창 + 버튼
                HStack {
                    TextField("찾고 싶은 사용자 이름/이메일", text: $keyword)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("검색") {
                        searchUsers()
                    }
                    .padding(.leading, 4)
                }
                .padding(.horizontal, 16)
                
                // 팔로우 리스트 (11.17:어떤 유저를 눌렀는지 ID 넘기도록 수정)
                List(followList) { user in
                    NavigationLink(destination: UserProfileFeedView(userId: user.follow_id)) {
                        HStack {
                            Circle()
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading) {
                                Text(user.name)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button("언팔로우") {
                                unfollow(user: user)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // 검색 결과 리스트 (있을 때만)
                if !searchResults.isEmpty {
                    Text("검색 결과")
                        .font(.headline)
                        .padding(.horizontal, 16)
                    
                    List {
                        ForEach(searchResults, id: \.user_id) { user in
                            HStack {
                                // 프로필 영역을 누르면 상세로 이동
                                NavigationLink(
                                    destination: UserProfileFeedView(userId: user.user_id)
                                ) {
                                    HStack {
                                        Circle()
                                            .frame(width: 32, height: 32)
                                        
                                        VStack(alignment: .leading) {
                                            Text(user.name)
                                            Text(user.email)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                
                                Spacer()
                                

                                Button("팔로우") {
                                    follow(user: user)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                Spacer()
            }
            .onAppear {
                fetchFollowList()
            }
            .navigationBarHidden(true)
        }
    }
    
    // 팔로우 리스트 가져오기
    func fetchFollowList() {
        let myId = UserDefaults.standard.integer(forKey: "userID")  // userID 값을 가져오기
        if myId == 0 {
            print("userID 없음 (로그인 필요)")
            return
        }
        
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/follow_list.php") else {
            print("URL 오류")
            return
        }
        
        let body = "user_id=\(myId)"
        let data = body.data(using: .utf8)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = data
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("에러:", error)
                return
            }
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode(FollowListResponse.self, from: data)
                if decoded.result == 1, let list = decoded.follows {
                    DispatchQueue.main.async {
                        self.followList = list
                    }
                } else {
                    print("서버 에러:", decoded.error ?? "알 수 없는 오류")
                }
            } catch {
                print("디코딩 오류:", error)
                if let s = String(data: data, encoding: .utf8) { print("raw:", s) }
            }
        }.resume()
    }
    
    // 언팔로우
    func unfollow(user: FollowItem) {
        let myId = UserDefaults.standard.integer(forKey: "userID")
        if myId == 0 {
            print("userID 없음 (로그인 필요)")
            return
        }
        
        guard let url = URL(string: "http://localhost/ip1/20231013/unfollow.php") else {
            print("URL 오류")
            return
        }
        
        let body = "user_id=\(myId)&target_id=\(user.follow_id)"
        let data = body.data(using: .utf8)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = data
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("언팔로우 에러:", error)
                return
            }
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode(SimpleResponse.self, from: data)
                if decoded.result == 1 {
                    print("언팔로우 성공")
                    DispatchQueue.main.async {
                        self.followList.removeAll { $0.follows_id == user.follows_id }
                    }
                } else {
                    print("언팔로우 실패:", decoded.error ?? "알 수 없는 오류")
                }
            } catch {
                print("언팔로우 디코딩 오류:", error)
                if let s = String(data: data, encoding: .utf8) { print("raw:", s) }
            }
        }.resume()
    }
    
    // 사용자 검색
    func searchUsers() {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines) // 문자열 앞뒤의 공백·줄바꿈을 제거
        if trimmed.isEmpty {
            print("검색어 없음")
            self.searchResults = []
            return
        }
        
        guard let url = URL(string: "http://localhost/ip1/20231013/search_user.php") else {
            print("검색 URL 오류")
            return
        }
        let myId = UserDefaults.standard.integer(forKey: "userID")   // 내 아이디 가져오기
        let body = "keyword=\(trimmed)&my_id=\(myId)"               // my_id 같이 전송 \(trimmed) = 문자열 안에 변수 값 넣기
        let data = body.data(using: .utf8)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = data
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("검색 에러:", error)
                return
            }
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode(SearchUserResponse.self, from: data)
                if decoded.result == 1, let users = decoded.users {
                    DispatchQueue.main.async {
                        self.searchResults = users
                    }
                } else {
                    print("검색 실패:", decoded.error ?? "알 수 없는 오류")
                    DispatchQueue.main.async {
                        self.searchResults = []
                    }
                }
            } catch {
                print("검색 디코딩 오류:", error)
                if let s = String(data: data, encoding: .utf8) { print("raw:", s) }
            }
        }.resume()
    }
    
    // 팔로우 추가
    func follow(user: SearchUserItem) {
        let myId = UserDefaults.standard.integer(forKey: "userID")
        if myId == 0 {
            print("userID 없음 (로그인 필요)")
            return
        }
        
        guard let url = URL(string: "http://localhost/ip1/20231013/follow_add.php") else {
            print("follow_add URL 오류")
            return
        }
        
        let body = "user_id=\(myId)&target_id=\(user.user_id)"
        let data = body.data(using: .utf8)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = data
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("팔로우 에러:", error)
                return
            }
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode(SimpleResponse.self, from: data)
                if decoded.result == 1 {
                    print("팔로우 성공")
                    DispatchQueue.main.async {
                        // 검색 결과에서 제거 + 팔로우 목록 다시 불러오기
                        self.searchResults.removeAll { $0.user_id == user.user_id }
                        self.fetchFollowList()
                    }
                } else {
                    print("팔로우 실패:", decoded.error ?? "알 수 없는 오류")
                }
            } catch {
                print("팔로우 디코딩 오류:", error)
                if let s = String(data: data, encoding: .utf8) { print("raw:", s) }
            }
        }.resume()
    }
}

#Preview {
    FollowListView()
}

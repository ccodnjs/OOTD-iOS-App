import SwiftUI
struct Post: Codable, Hashable {

    var post_id: Int?
    var user_id: Int?
    var name: String?
    var content: String?
    var like_count: Int?
    var comment_count: Int?
    var created_at: String?
}

struct Comment: Codable, Hashable {
    var comment_id: Int
    var content: String
    var name: String // 작성자 이름
    var created_at: String
}

// 서버 응답용 래퍼
struct CommentResponse: Codable {
    var comments: [Comment]
    var is_liked: Bool
}

// 2. 게시물 배열을 감싸는 구조체

struct Posts: Codable {
    var posts: [Post]
}



// 3. 리스트의 각 항목을 표시할 뷰

struct PostItem: View {
    @State var postData: Post

    
    var truncatedContent: String {
        let content = postData.content ?? "내용 없음"
        if content.count > 100 {
            // 100자로 자르고 "..." 붙이기
            return String(content.prefix(100)) + "..."
        } else {
            // 100자 미만이면 그대로 반환
            return content
        }
    }

    

    var body: some View {
        VStack(alignment: .leading) {
            Text(postData.name ?? "사용자")
                .font(.headline)
            Text(truncatedContent)
                .padding(.top, 2)
            Text(postData.created_at ?? "")
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.top, 5)
        }
        .padding(.vertical, 8)
    }
}


struct RecommendFeedView: View {
    
    @State var posts: Posts = Posts(posts: [Post]())
    
    // UserDefaults에서 user_id 가져오기
    // 뷰가 나타날 때 이 값을 사용합니다.
    @State var user_id: Int = UserDefaults.standard.integer(forKey: "userID")
    
    var body: some View {
            NavigationView {
                List(posts.posts, id: \.post_id) { post in
                    
                    // [수정된 호출] user_id를 넘기지 않습니다.
                    NavigationLink(destination: UserPostView(postId: post.post_id ?? 0)) {
                        PostItem(postData: post)
                    }
                }
                .navigationTitle("추천 피드")
                .onAppear {
                    getPosts(userId: self.user_id)
                }
            }
        }
    // 1. 네트워크 요청을 별도 함수로 분리
    func getPosts(userId: Int) {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/getRecommendFeed.php") else {
            print("url error")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 2. (수정됨) @State의 user_id 값을 body에 포함
        // "user_id" 라는 문자열 대신 "user_id=값" 형태로 전송
        let body = "user_id=\(userId)"
        
        let encodedData = body.data(using: String.Encoding.utf8)
        request.httpBody = encodedData
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                let decoder = JSONDecoder()
                if let jsonPostData = try? decoder.decode(Posts.self, from: data) {
                    
                    // 3. (추가됨) UI 업데이트는 반드시 메인 스레드에서!
                    DispatchQueue.main.async {
                        posts = jsonPostData
                    }
                    
                } else {
                    print("JSON Decode Error")
                    let str = String(decoding: data, as: UTF8.self)
                    print("Received data: \(str)")
                }
            }
        }.resume()
    }
}

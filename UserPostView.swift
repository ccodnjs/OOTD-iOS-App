import SwiftUI

// 게시물 상세 화면을 보여주는 뷰입니다.
struct UserPostView: View {
    // MARK: - 1. Properties (속성)
    
    // [외부에서 받는 데이터]
    // 이전 화면(리스트)에서 클릭된 게시물의 고유 ID입니다.
    // 이 ID를 이용해 서버에서 상세 내용을 다시 조회합니다.
    let postId: Int
    
    // [내부 상태 (State)]
    // @State: 뷰의 상태를 관리하는 변수입니다. 값이 바뀌면 뷰가 다시 그려집니다.
    
    // 현재 로그인한 사용자의 ID입니다. 앱 저장소(UserDefaults)에서 가져옵니다.
    // 좋아요를 누르거나 댓글을 달 때 "누가" 했는지 알기 위해 필요합니다.
    @State var user_id: Int = UserDefaults.standard.integer(forKey: "userID")
    
    // [서버 데이터 저장용]
    // postData: 게시글의 상세 내용 (제목, 내용, 작성자 등). 로딩 전엔 nil입니다.
    @State private var postData: Post? = nil
    // comments: 댓글 목록을 저장하는 배열입니다.
    @State private var comments: [Comment] = []
    
    // [UI 제어용]
    // newCommentText: 댓글 입력창에 입력되는 텍스트와 바인딩됩니다.
    @State private var newCommentText: String = ""
    
    // isLiked: 내가 이 글에 좋아요를 눌렀는지 여부 (true: 빨간 하트, false: 빈 하트)
    @State private var isLiked: Bool = false
    
    // likeCount, commentCount: 화면에 보여질 숫자들입니다.
    // 서버에서 받은 값으로 초기화되고, 사용자가 버튼을 누르면 즉시 +1 / -1 하여 반응 속도를 높입니다.
    @State private var likeCount: Int = 0
    @State private var commentCount: Int = 0
    
    // isLoading: 데이터가 로딩 중인지 나타냅니다. true면 로딩 휠이 돕니다.
    @State private var isLoading = true

    // MARK: - 2. Body (화면 구성)
    var body: some View {
        VStack {
            // [상태에 따른 분기 처리]
            if isLoading {
                // 1. 데이터를 불러오는 중일 때
                ProgressView("로딩 중...")
            } else if let post = postData {
                // 2. 데이터 로드 성공 (postData가 nil이 아님)
                contentView(post: post)
            } else {
                // 3. 로드 실패 또는 데이터 없음
                Text("게시물을 불러올 수 없습니다.")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("게시물 상세") // 상단 네비게이션 타이틀
        .navigationBarTitleDisplayMode(.inline) // 타이틀 작게 표시
        .onAppear {
            // [화면 진입 시점]
            // UserDefaults에서 가져온 user_id가 0(기본값)이라면 다시 시도합니다.
            // 로그인 직후 등 타이밍 이슈를 방지하기 위함입니다.
            if user_id == 0 {
                user_id = UserDefaults.standard.integer(forKey: "userID")
            }
        }
        .task {
            // [비동기 작업 실행]
            // .task는 뷰가 나타날 때 비동기 함수(async)를 실행하고, 뷰가 사라지면 작업을 취소합니다.
            await fetchPostDetail() // 게시글 내용 가져오기
            await fetchComments()   // 댓글 목록 가져오기
        }
    }
    
    // MARK: - 3. UI Components (하위 뷰 분리)
    
    // 게시물 본문을 그리는 함수
    func contentView(post: Post) -> some View {
        VStack {
            ScrollView { // 내용이 길어질 수 있으므로 스크롤 가능하게 처리
                VStack(alignment: .leading, spacing: 15) {
                    
                    // (1) 상단 프로필 영역
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            Text(post.name ?? "알 수 없음") // 작성자 이름
                                .font(.headline)
                            Text(post.created_at ?? "")    // 작성일
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Divider() // 구분선
                    
                    // (2) 게시물 텍스트 내용
                    Text(post.content ?? "")
                        .font(.body)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    
                    Divider()
                    
                    // (3) 좋아요/댓글 버튼 영역 (아래 변수로 분리됨)
                    actionButtons
                    
                    // (4) 댓글 리스트 영역 (아래 변수로 분리됨)
                    commentListView
                }
            }
            
            // (5) 하단 댓글 입력창 (화면 하단에 고정)
            commentInputArea
        }
    }
    
    // 좋아요 버튼과 댓글 수를 보여주는 뷰
    var actionButtons: some View {
        HStack {
            // [좋아요 버튼]
            Button(action: {
                // 버튼 클릭 시 비동기 함수 실행 (Task로 감싸야 await 함수 호출 가능)
                Task { await toggleLike() }
            }) {
                HStack {
                    // isLiked 상태에 따라 꽉 찬 하트 / 빈 하트 이미지 변경
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                        .font(.system(size: 20))
                    Text("좋아요 \(likeCount)")
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            // [댓글 수 표시] (단순 표시용)
            HStack {
                Image(systemName: "bubble.right")
                Text("댓글 \(commentCount)")
            }
            .foregroundColor(.gray)
        }
        .padding()
    }
    
    // 댓글 목록을 나열하는 뷰
    var commentListView: some View {
        VStack(alignment: .leading) {
            Text("댓글")
                .font(.headline)
                .padding(.bottom, 5)
            
            if comments.isEmpty {
                // 댓글이 없을 경우 안내 문구
                Text("첫 댓글을 남겨보세요!")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical)
            } else {
                // 댓글이 있을 경우 반복문(ForEach)으로 표시
                ForEach(comments, id: \.comment_id) { comment in
                    HStack(alignment: .top) {
                        Text(comment.name) // 댓글 작성자
                            .font(.caption)
                            .bold()
                        Text(comment.content) // 댓글 내용
                            .font(.caption)
                        Spacer()
                        Text(comment.created_at) // 작성 시간
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    Divider() // 댓글 사이 구분선
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 하단 댓글 입력바 뷰
    var commentInputArea: some View {
        HStack {
            // $newCommentText 바인딩: 입력한 내용이 변수에 실시간 저장됨
            TextField("댓글 입력...", text: $newCommentText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // 전송 버튼
            Button(action: {
                Task { await addComment() }
            }) {
                Text("전송")
                    .bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    // 내용이 없으면 회색, 있으면 파란색
                    .background(newCommentText.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            // 내용이 비어있으면 버튼 비활성화 (클릭 불가)
            .disabled(newCommentText.isEmpty)
        }
        .padding()
        .background(Color(UIColor.systemGray6)) // 연한 회색 배경
    }
    
    // MARK: - 4. Network Logic (서버 통신)
    // async/await를 사용하여 비동기 통신을 처리합니다.
    
    // [게시물 상세 정보 조회] - GET 방식
    func fetchPostDetail() async {
        // URL 생성: post_id와 user_id를 쿼리 파라미터로 보냄
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/getPostDetail.php?post_id=\(postId)&user_id=\(self.user_id)") else { return }
        
        do {
            // 서버에 데이터 요청 (URLSession)
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            // 받아온 JSON 데이터를 Post 구조체로 변환 (Decoding)
            let fetchedPost = try decoder.decode(Post.self, from: data)
            
            // [추가 작업] JSON을 딕셔너리로 한 번 더 풀어서 'is_liked_by_me' 확인
            // Post 구조체에 없는 별도 필드를 확인하기 위함입니다.
            if let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let liked = jsonDict["is_liked_by_me"] as? Bool {
                self.isLiked = liked // 내가 좋아요 눌렀던 글이면 하트를 빨갛게
            }
            
            // [UI 업데이트] - 반드시 메인 스레드(MainActor)에서 해야 함
            await MainActor.run {
                self.postData = fetchedPost
                self.likeCount = fetchedPost.like_count ?? 0
                self.commentCount = fetchedPost.comment_count ?? 0
                self.isLoading = false // 로딩 종료 -> 화면 표시
            }
        } catch {
            print("Fetch Error: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
    
    // [댓글 목록 조회] - POST 방식
    func fetchComments() async {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/getComments.php") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // POST Body에 데이터 담기
        let body = "post_id=\(postId)&user_id=\(self.user_id)"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            // CommentResponse 구조체(배열 포함)로 디코딩
            let response = try JSONDecoder().decode(CommentResponse.self, from: data)
            
            await MainActor.run {
                self.comments = response.comments // 댓글 배열 업데이트
                self.commentCount = self.comments.count // 댓글 개수 UI 동기화
            }
        } catch {
            print("Comment Error: \(error)")
        }
    }
    
    // [좋아요 토글] - POST 방식
    // *특징: Optimistic UI (낙관적 업데이트) 적용
    // 서버 응답을 기다리지 않고 화면의 하트와 숫자를 먼저 바꿉니다. (반응성 향상)
    func toggleLike() async {
        // 1. UI 먼저 변경
        isLiked.toggle() // true <-> false 반전
        likeCount += isLiked ? 1 : -1 // 숫자를 +1 혹은 -1
        
        // 2. 서버에 요청 전송 (백그라운드)
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/toggleLike.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "post_id=\(postId)&user_id=\(self.user_id)"
        request.httpBody = body.data(using: .utf8)
        
        // 결과값은 굳이 안 받아도 되므로 try? 사용 (실패해도 앱이 죽진 않음)
        try? await URLSession.shared.data(for: request)
    }
    
    // [댓글 등록] - POST 방식
    func addComment() async {
        let content = newCommentText // 입력한 내용 임시 저장
        newCommentText = "" // 입력창은 즉시 비워줌 (사용자 경험 향상)
        
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/addComment.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "post_id=\(postId)&user_id=\(self.user_id)&content=\(content)"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            // HTTP 상태 코드가 200(성공)이면
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                // 댓글 목록을 다시 불러와서 내 댓글이 보이게 함
                await fetchComments()
            }
        } catch {
            print("Add Comment Error: \(error)")
        }
    }
}

import SwiftUI

// MARK: - 인기 피드 뷰 (PopularFeedView)
// 서버에서 받아온 게시물들을 좋아요가 많은 순서대로 보여주는 화면입니다.
struct PopularFeedView: View {
    // MARK: - Properties (변수 선언)
    
    // [게시물 데이터 저장소]
    // 서버에서 받아온 게시물 목록을 저장하는 변수입니다.
    // @State: 이 값이 변경되면(새 데이터가 들어오면) 뷰가 자동으로 다시 그려져서 화면이 갱신됩니다.
    // 초기값은 비어있는 상태(Posts(posts: []))로 시작합니다.
    @State var posts: Posts = Posts(posts: [])
    
    // [사용자 ID]
    // 앱 내부 저장소(UserDefaults)에 저장된 "userID" 값을 가져옵니다.
    // 현재 이 화면에서 필수적으로 쓰이지 않더라도, 사용자 정보가 필요할 때를 대비해 가져옵니다.
    @State var user_id: Int = UserDefaults.standard.integer(forKey: "userID")
    
    // MARK: - Body (화면 구성)
    // 실제 사용자에게 보여지는 UI를 정의하는 부분입니다.
    var body: some View {
        // [네비게이션 뷰]
        // 다른 화면으로 이동(NavigationLink)하는 기능을 사용하기 위해 최상단을 감싸줍니다.
        NavigationView {
            // [ZStack]
            // 뷰를 겹쳐서 배치할 때 사용합니다. 여기서는 '배경색'과 '스크롤 뷰'를 겹치기 위해 썼습니다.
            ZStack {
                // 1. 전체 배경색 설정
                // 시스템 기본 배경색(회색조)을 사용하여 카드(흰색)와 대비를 줍니다.
                // edgesIgnoringSafeArea(.all): 화면의 맨 위(노치)와 맨 아래까지 색을 꽉 채웁니다.
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                // 2. 스크롤 가능한 영역
                // 내용이 길어지면 위아래로 스크롤할 수 있게 해줍니다.
                ScrollView {
                    // [LazyVStack]
                    // 세로 방향(Vertical)으로 뷰를 쌓아주는 컨테이너입니다.
                    // 'Lazy': 화면에 보이는 부분만 그때그때 그리기 때문에 데이터가 많아도 성능이 좋습니다.
                    // spacing: 15 -> 각 게시물 카드 사이에 15포인트 간격을 줍니다.
                    LazyVStack(spacing: 15) {
                        // [ForEach 반복문]
                        // posts.posts 배열에 있는 데이터를 하나씩 꺼내서 반복합니다.
                        // id: \.post_id -> 각 게시물을 구별하는 고유한 번호(ID)를 지정합니다.
                        ForEach(posts.posts, id: \.post_id) { post in
                            
                            // [화면 이동 링크]
                            // 카드를 클릭하면 상세 화면(UserPostView)으로 이동합니다.
                            // postId: post.post_id를 넘겨주어 어떤 글을 눌렀는지 알려줍니다.
                            NavigationLink(destination: UserPostView(postId: post.post_id ?? 0)) {
                                
                                // [카드 디자인 적용]
                                // 실제 게시물의 모양은 별도로 정의한 'FeedCardView'를 사용합니다.
                                FeedCardView(post: post)
                            }
                            // 링크를 걸면 글씨가 파랗게 변하는 기본 스타일을 제거합니다.
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 15) // 리스트 전체의 위아래에 여백을 줍니다.
                }
                // [새로고침 기능]
                // 리스트를 위에서 아래로 당기면(Pull-to-refresh), 데이터를 다시 서버에서 받아옵니다.
                .refreshable {
                    fetchPopularPosts()
                }
            }
            // 상단 네비게이션 바의 제목을 설정합니다.
            .navigationTitle("인기 피드")
            
            // [화면 진입 시 실행]
            // 이 탭을 눌러서 화면이 켜지는 순간(onAppear), 데이터를 불러오는 함수를 실행합니다.
            .onAppear {
                fetchPopularPosts()
            }
        }
    }
    
    // MARK: - Network Logic (서버 통신)
    
    // [데이터 요청 함수]
    // PHP 서버에 접속해서 인기 게시물 데이터를 가져오는 함수입니다.
    func fetchPopularPosts() {
        // 1. 주소 확인
        // 접속할 서버의 URL이 정확한지 확인합니다. 틀렸다면 함수를 중단합니다.
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/getPopularFeed.php") else { return }
        
        // 2. 요청 객체 생성
        // "GET" 방식(데이터 조회용)으로 요청을 설정합니다.
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 3. 비동기 통신 시작
        // 백그라운드에서 서버에 다녀오는 작업을 시작합니다.
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // [에러 체크 1] 인터넷 연결 등 통신 자체에 실패했는지 확인
            if let error = error {
                print("통신 에러: \(error.localizedDescription)")
                return
            }
            
            // [데이터 확인] 서버에서 온 데이터(내용물)가 비어있는지 확인
            guard let data = data else { return }
            
            do {
                // 4. 데이터 해석 (Decoding)
                // 서버가 보낸 JSON 데이터를 우리가 사용하는 Swift 객체(Posts)로 변환합니다.
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(Posts.self, from: data)
                
                // 5. 화면 갱신 (Main Thread)
                // [중요] 화면을 그리는 작업은 반드시 '메인 스레드'에서 해야 합니다.
                // 해석된 데이터를 posts 변수에 넣으면, @State 덕분에 화면이 새로고침됩니다.
                DispatchQueue.main.async {
                    self.posts = decodedData
                }
            } catch {
                // [에러 체크 2] JSON 형식이 안 맞거나 변환에 실패한 경우
                print("JSON 변환 실패: \(error)")
            }
        }.resume() // 작업을 실행(시작)합니다.
    }
}

// MARK: - [디자인] 카드 형태의 게시물 뷰 (FeedCardView)
// 각 게시물을 예쁜 카드 모양으로 보여주는 별도의 뷰입니다.
struct FeedCardView: View {
    let post: Post // 상위 뷰에서 전달받은 게시물 데이터 하나
    
    // [내용 미리보기 로직]
    // 본문이 너무 길면 100자까지만 자르고 "..."을 붙여서 보여줍니다.
    var truncatedContent: String {
        let content = post.content ?? ""
        if content.count > 100 {
            return String(content.prefix(100)) + "..."
        } else {
            return content
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // (1) 헤더 영역: 프로필 사진, 이름, 작성일
            HStack {
                // 프로필 아이콘 (이미지가 없으므로 회색 원 + 사람 아이콘으로 대체)
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.name ?? "알 수 없음") // 작성자 이름
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(post.created_at ?? "") // 작성 날짜
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer() // 오른쪽으로 밀어내기
                
                // 더보기 아이콘 (옵션)
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
            
            // (2) 본문 영역
            Text(truncatedContent)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3) // 최대 3줄까지만 보여주고 나머지는 생략(...)
                .lineSpacing(4) // 줄 간격 조정
            
            Divider() // 가는 구분선
            
            // (3) 푸터 영역: 좋아요, 댓글, 자세히 보기 버튼
            HStack(spacing: 20) {
                // 좋아요 아이콘과 개수
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red.opacity(0.8)) // 빨간색 하트
                    Text("\(post.like_count ?? 0)")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                
                // 댓글 아이콘과 개수
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.blue.opacity(0.8)) // 파란색 말풍선
                    Text("\(post.comment_count ?? 0)")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                
                Spacer() // 오른쪽으로 밀어내기
                
                Text("자세히 보기")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(15) // 카드 내부 내용과 테두리 사이의 여백
        .background(Color.white) // 카드 배경색은 흰색
        .cornerRadius(15) // 모서리를 둥글게(15pt) 깎음
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2) // 살짝 그림자를 주어 입체감 효과
        .padding(.horizontal, 15) // 화면 좌우와 카드 사이의 여백
    }
}

// [미리보기]
// 엑스코드 캔버스에서 화면을 미리 볼 수 있게 해주는 코드입니다.
struct PopularFeedView_Previews: PreviewProvider {
    static var previews: some View {
        PopularFeedView()
    }
}

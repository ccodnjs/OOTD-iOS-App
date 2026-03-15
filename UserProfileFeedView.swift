//
//  UserProfileFeedView.swift
//  projectOOTD
//
//  Created by mac19 on 10/27/25.
//

import SwiftUI

struct UserProfile: Codable {
    let user_id: Int
    let name: String
    let profile_image: String?
    let body_shape: String?
}

struct UserPost: Codable, Identifiable {
    let post_id: Int
    let content: String
    let created_at: String
    
    var id: Int { post_id }
}

struct UserProfileFeedResponse: Codable {
    let result: Int
    let profile: UserProfile?
    let styles: [String]?
    let colors: [String]?
    let posts: [UserPost]?
    let error: String?
}

// 프로필 + 피드 화면
struct UserProfileFeedView: View {
    
    // 어떤 사용자의 프로필/피드를 볼지
    let userId: Int
    
    @State private var profile: UserProfile?
    @State private var posts: [UserPost] = []
    
    @State private var styleTags: [String] = []
    @State private var colorTags: [String] = []
    
    var body: some View {
        NavigationView {
            List {
                // 1. 프로필 섹션 (분리됨)
                profileSection
                
                // 2. 게시물 리스트 섹션 (분리됨)
                postFeedSection
            }
            .navigationTitle("계정 정보")
            .onAppear {
                fetchUserProfileFeed()
            }
        }
    }
    
    // MARK: - Subviews (뷰 분리)
    
    // 프로필 정보를 보여주는 섹션
    @ViewBuilder
    private var profileSection: some View {
        if let p = profile {
            Section {
                HStack(alignment: .center, spacing: 16) {
                    
                    // 프로필 이미지 자리
                    Circle()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray.opacity(0.3)) // 임시 색상 추가
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(p.name)
                            .font(.title3)
                            .bold()
                        
                        Text("ID: \(p.user_id)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    if !styleTags.isEmpty {
                        Text("스타일: \(styleTags.joined(separator: ", "))")
                    }
                    
                    if !colorTags.isEmpty {
                        Text("선호 색상: \(colorTags.joined(separator: ", "))")
                    }
                    
                    if let bodyShape = p.body_shape {
                        Text("체형: \(bodyShape)")
                    }
                }
                .font(.subheadline)
                .padding(.vertical, 4)
                
            } header: {
                Text("프로필")
            }
        }
    }
    
    // 게시물 리스트를 보여주는 섹션
    private var postFeedSection: some View {
        Section(header: Text("게시물 피드")) {
            if posts.isEmpty {
                Text("게시물이 없습니다.")
                    .foregroundColor(.gray)
            } else {
                ForEach(posts) { post in
                    // UserPostView가 있다는 가정하에 작성
                    NavigationLink(destination: UserPostView(postId: post.post_id ?? 0)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.content)
                                .lineLimit(2)
                            
                            Text(post.created_at)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Network
    
    func fetchUserProfileFeed() {
        guard let url = URL(string: "http://124.56.5.77/projectOOTD/user_profile_feed.php") else {
            print("URL 오류")
            return
        }

        let body = "user_id=\(userId)"
        let data = body.data(using: .utf8)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("프로필 피드 에러:", error)
                return
            }
            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode(UserProfileFeedResponse.self, from: data)
                
                if decoded.result == 1 {
                    DispatchQueue.main.async {
                        self.profile   = decoded.profile
                        self.posts     = decoded.posts ?? []
                        self.styleTags = decoded.styles ?? []
                        self.colorTags = decoded.colors ?? []
                    }
                } else {
                    print("서버 에러:", decoded.error ?? "알 수 없는 오류")
                }

            } catch {
                print("디코딩 오류:", error)
                if let s = String(data: data, encoding: .utf8) {
                    print("raw:", s)
                }
            }
        }.resume()
    }
}


#Preview {
    UserProfileFeedView(userId: 1)
}

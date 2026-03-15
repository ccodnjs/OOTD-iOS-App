import SwiftUI



struct MainView: View {

    // 0: 추천, 1: 인기, 2: 팔로우

    @State private var selectedFeedType = 0

   

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

               
                // ===== 상단 프로필 + 버튼들 =====
                HStack {
                    // 프로필 (지금은 그냥 동그라미)
                    Circle()
                        .frame(width: 40, height: 40)
                    Spacer()

                   

                    NavigationLink(destination: FollowListView()) {
                        Text("팔로우")
                    }

                   

                NavigationLink(destination: FollowerListView()) {
                        Text("팔로워")
                    }

                   

                    NavigationLink(destination: WritingView()) {

                        Text("글쓰기")

                    }

                }

                .padding(.horizontal, 16)

                .padding(.vertical, 8)

               

               

                // 중간 탭: 추천 / 인기 / 팔로우

                HStack {

                    Button("추천") {

                        selectedFeedType = 0

                    }

                    .frame(maxWidth: .infinity)

                   

                    Button("인기") {

                        selectedFeedType = 1

                    }

                    .frame(maxWidth: .infinity)

                   

                    Button("팔로우") {

                        selectedFeedType = 2

                    }

                    .frame(maxWidth: .infinity)

                }

                .padding(.vertical, 8)

                .background(Color.gray.opacity(0.2))

               

                Divider()

               

                //  피드 영역

                if selectedFeedType == 0 {

                    // 추천 피드

                    RecommendFeedView()

                } else if selectedFeedType == 1 {

                    // 인기 피드

                    PopularFeedView()



                } else {

                    // 팔로우 피드

                    FollowFeedView()

                   

                }

               

                Spacer()

            }

            .navigationTitle("피드")

        }

    }

}



#Preview {

    MainView()

}

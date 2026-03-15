//
//  MainTabView.swift
//  projectOOTD
//
//  Created by mac19 on 10/27/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        // 1. 하단 탭 바(TabView)를 설치합니다.
        TabView {
            
            // --- 1. 피드 탭 (MainView) ---
            // 각 탭은 독립적인 네비게이션 스택을 가지는 것이 좋습니다.
            // (피드에서 -> 상세페이지로 갔다가, 옷장 탭을 눌렀다 다시 와도 상세페이지가 유지됨)
            NavigationStack {
                MainView()
            }
            .tabItem {
                Image(systemName: "house") // 아이콘
                Text("피드")                 // 이름
            }
            
            // --- 2. 옷장 탭 (ClosetView) ---
            NavigationStack {
                ClosetView()
            }
            .tabItem {
                Image(systemName: "hanger")
                Text("옷장")
            }
            
            // --- 3. 마켓 탭 (MarketView) ---
            NavigationStack {
                MarketView() // 이 파일도 생성되어 있어야 합니다.
            }
            .tabItem {
                Image(systemName: "storefront") // "storefront" 또는 "dollarsign.circle"
                Text("마켓")
            }
            
            // --- 4. 채팅 탭 (ChattingView) ---
            NavigationStack {
                ChattingView()
            }
            .tabItem {
                Image(systemName: "message")
                Text("채팅")
            }
            
            // --- 5. 설정 탭 (SettingView) ---
            NavigationStack {
                SettingView() // 이 파일도 생성되어 있어야 합니다.
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("설정")
            }
        }
    }
}





#Preview {
    MainTabView()
}

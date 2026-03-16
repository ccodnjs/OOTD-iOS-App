
#(1) OnFit - OOTD 패션 SNS iOS App

사용자가 자신의 옷을 디지털 옷장에 기록하고 관리하고,
OOTD 스타일을 공유하며 다른 사용자와 소통하고 중고 거래까지 할 수 있는 패션 플랫폼입니다.

#(2) Project Overview

OnFit은 패션 스타일을 기록하고 공유할 수 있는 SNS 기반 패션 플랫폼입니다.

사용자는 자신의 옷을 디지털 옷장에 등록하고
OOTD 게시글을 통해 스타일을 공유하며
안 입는 옷은 마켓에서 거래할 수 있습니다.

#(3) Target Users

자신의 스타일을 기록하고 공유하고 싶은 사용자

패션에 관심 있는 10~20대 사용자

중고 의류 거래 및 합리적인 소비에 관심 있는 사용자

#(4) Tech Stack
Category	Technology
Language	Swift
Platform	iOS
Architecture	MVC
IDE	Xcode

#(5) 주요 기능
#(5-1) Authentication
사용자가 계정을 생성하고 로그인할 수 있는 기능을 구현
● Login 
 -이메일 또는 ID와 비밀번호로 로그인
 -입력값 유효성 검사(빈 값, 길이 검사)
 -서버에서 사용자 정보 조회 후 로그인 처리
 -로그인 실패 시 오류 메시지 표시
● Sign Up
 -사용자 계정 생성 기능
 -입력 정보(이메일, ID, 비밀번호, 이름, 생년월일, 스타일, 선호 색상, 체형)
 -입력 데이터 검증 (이메일 형식 검사, ID길이 제한, 특수문자 제한, 필수 정보 입력 확인)
 -서버 처리 (ID/이메일 중복 검사, 사용자 정보 데이터베이스 저장)


#(5-2) OOTD Feed (SNS)
사용자가 자신의 스타일을 공유하고 다른 사용자와 소통하며 사용자간의 옷 중고거래까지 가능한 SNS피드 기능을 구현

● 3가지로 구성된 Feed Tabs
 1. 추천 피드 (회원가입 시 선택한 스타일 카테고리를 기반으로 게시물 추천)
 2. 인기 피드 (최근 1개월 기준 좋아요 수가 많은 게시물 순으로 정렬)
 3. 팔로우 피드 (사용자가 팔로우한 계정의 게시물을 최신순으로 표시)

● User Search & Follow & Unfollow 기능

● Post
 -Create Post(사진 업로드, 게시글 작성, 게시물 저장)
 -Read Post(피드에서 게시글 조회, 게시물 클릭 시 상세 페이지 이동, 사진 및 게시글 전체 내용 표시, 좋아요 수 표시, 댓글 조회 가능)
 -Update Post(작성자가 게시글 수정 가능, 수정 시 '수정됨' 표시)
 -Delete Post(작성자가 게시글 삭제 가능, 업로드된 이미지 파일 함께 삭제)

 ● 게시글 댓글 기능

#(5-3) Profile View
사용자 프로필 기능
 - 사용자 스타일 정보 표시
 - 작성한 게시글 목록 조회
 - 팔로우 / 언팔로우 가능
   
#(5-4) Digital Closet

자신의 옷을 관리하는 디지털 옷장 기능

 ● Add Item
 - 옷 아이템 등록(사진, 스타일, 브랜드, 색상, 재질/두께, 계절, 스타일, 체형)
 - 카테고리 태그 관리
 - 아이템 수정 및 삭제

 ● View Items
 자신의 옷장에 등록된 아이템 조회

 ● Update Item
 등록한 아이템 정보 수정

 ● Delete Item
 등록한 아이템 삭제

#(5-5) Outfit Recommendation

사용자의 옷장에서 상의/하의를 랜덤으로 조합하여 오늘의 코디를 추천

#(5-6) Fashion Market

사용자가 자신의 옷을 판매하고 다른 사용자와 거래할 수 있는 마켓 기능 구현

● Product Listing
사용자 자신의 판매 게시글 등록
 -옷장 아이템 선택, 상품 사진 업로드, 상품 설명 작성, 판매 가격 입력
 -게시글 상태 설정 가능 (판매중, 예약중, 판매 완료)

● Product Search
필터를 이용한 상품 검색

● Product Management
자신의 판매 게시글 관리
- 판매 게시글 조회
- 가격 수정, 상품 설명 수정
- 판매 게시글 삭제

● Chat
구매 과정시 필요한 판매자와 구매자와의 실시간 채팅 가능

● Whishlist
상품 찜 기능

● Review System
구매 완료 후 상품 후기 작성 가능(별점 평가, 후기 작성)

(5-6) User Profile
● Profile View
사용자 프로필 페이지(이미지, ID, 이메일, 이름, 생년월일, 스타일 정보 확인 가능)

● Profile Update 
사용자 계정 정보 수정(비밀번호, 사용자 정보, 프로필 이미지)

● Account Deletion 
사용자 계정 탈퇴 가능

#(6)Project Structure
OOTD-App
 ┣ Authentication
 ┃ ┣ Login
 ┃ ┗ Signup
 ┣ Feed
 ┣ Closet
 ┣ Market
 ┣ Profile
 ┗ Assets

#(7) Future Improvements

추천 알고리즘(어울리는 색상 학습)(모자, 악세사리, 신발 등 추천 종류 추가) 개선

UI/UX 개선

# OnFit 중고 상품 예약 서버

Java 17+ · Spring Boot · Spring JDBC · MySQL 8.4 · Flyway.
기존 Python/SQLite 데모와 독립된 Java API 서버입니다. 기존 iOS/PHP API 및 판매 데이터와 자동 연결되지 않습니다. 이 서버의 상품 생성 API로 만든 상품 ID를 사용합니다. 결제·예약 만료·회원가입·iOS 예약 화면은 이번 범위에 포함하지 않습니다.

## 실행

Docker Desktop을 켜고 이 폴더에서 실행합니다.

```sh
docker compose up -d --wait
./mvnw spring-boot:run -Dspring-boot.run.profiles=demo
```

Maven Wrapper가 Maven을 내려받으므로 Maven 별도 설치는 필요 없습니다. 최초 실행에는 네트워크가 필요합니다. 기본 서버 주소는 `127.0.0.1:8080`, MySQL 포트는 `3307`입니다. `PORT`, `SERVER_ADDRESS`, `DB_URL`, `DB_USER`, `DB_PASSWORD`로 변경할 수 있습니다. Flyway가 새 MySQL DB에 스키마를 생성합니다.

`demo` 프로필만 사용자 1(판매자), 2·3(구매자)을 생성하며 암호는 모두 `onfit-demo`입니다. 기존 계정의 암호를 덮어쓰지 않습니다. 기본 프로필은 계정을 자동 생성하지 않습니다. 인증은 DB의 BCrypt 해시를 확인하는 HTTP Basic입니다. 원격 서비스에는 HTTPS와 기존 회원 인증 체계 연동이 필요합니다. 요청 본문의 사용자 ID는 신원 판단에 사용하지 않습니다.

```sh
# 판매자 1의 상품 생성. 응답 id를 다음 요청의 1 자리에 사용합니다.
curl -u 1:onfit-demo -H 'Content-Type: application/json' \
  -d '{"title":"OnFit 재킷"}' http://127.0.0.1:8080/api/products

# 구매자 2의 예약. 응답의 id가 예약 UUID입니다.
curl -u 2:onfit-demo -X POST http://127.0.0.1:8080/api/products/1/reservations

# 아래 RESERVATION_ID를 예약 UUID로 교체합니다.
curl -u 2:onfit-demo -X POST http://127.0.0.1:8080/api/products/1/reservations/RESERVATION_ID/cancel

# 취소하지 않은 활성 예약에 대해 판매자만 완료 가능
curl -u 1:onfit-demo -X POST http://127.0.0.1:8080/api/products/1/reservations/RESERVATION_ID/complete
```

상품 조회: `GET /api/products/{id}`. 모든 API는 인증이 필요합니다. 상품 생성·예약은 201, 취소·완료·조회는 200입니다. 미인증 401, 권한 없음 403, 대상 없음 404, 예약 불가·종료된 예약 409입니다. 업무 오류 본문은 `{"code":"product_unavailable"}` 형태입니다. DB 장애·잠금 시간 초과는 성공으로 응답하지 않고 트랜잭션을 롤백합니다.

## 정책과 트랜잭션

| 작업 | 권한 | 상품 상태 | 예약 상태 |
| --- | --- | --- | --- |
| 예약 | 판매자를 제외한 로그인 사용자 | AVAILABLE → RESERVED | ACTIVE 생성 |
| 취소 | 해당 예약 구매자 또는 판매자 | RESERVED → AVAILABLE | ACTIVE → CANCELLED |
| 완료 | 판매자 | RESERVED → SOLD | ACTIVE → COMPLETED |

판매 완료는 최종 상태입니다. 종료된 예약의 재취소·재완료는 409입니다. 요청 재전송은 성공 결과를 재사용하지 않고 409로 처리하므로, 네트워크 오류 시 상품 조회로 상태를 확인해야 합니다. 취소 후에는 새 예약 UUID가 생깁니다. 이전 UUID로 취소해도 새 예약에 영향을 주지 않습니다. 예약 이력은 삭제하지 않습니다.

`MarketService`의 Spring `@Transactional` 경계에서 상품 상태 변경과 예약 저장을 함께 커밋합니다. FK 위반 등 저장 실패 시 상태 변경도 롤백합니다. 상품 행 → 예약 행의 순서로 잠가 취소·완료 요청을 직렬화합니다. MySQL 생성 컬럼과 UNIQUE 인덱스로 상품당 활성 예약을 DB에서도 하나로 제한합니다.

## 두 동시성 제어 방식

기본은 `CONDITIONAL`입니다. `RESERVATION_STRATEGY=PESSIMISTIC`으로 비관적 락을 선택할 수 있습니다.

- CONDITIONAL: `UPDATE ... WHERE status='AVAILABLE' AND seller_id<>?`의 변경 행 수가 1일 때만 예약 저장을 진행합니다. InnoDB의 행 잠금을 사용하며 JVM 프로세스 내 락에 의존하지 않습니다.
- PESSIMISTIC: 상품을 `SELECT ... FOR UPDATE`로 읽고 권한·상태 확인 후 갱신합니다. 복잡한 상태 검사가 늘어날 때 읽기 쉽지만 조회가 한 번 더 필요합니다.

현재 예약 조건이 단순해서 기본값은 조건부 UPDATE로 선택했습니다. 이는 설계상 선택이며 두 방식의 성능 우열을 측정한 결과는 아닙니다. 두 방식 모두 동일한 MySQL 정확성 테스트를 통과해야 합니다.

## 테스트

```sh
./mvnw test
```

Testcontainers가 별도 MySQL 8.4 컨테이너와 임시 DB를 생성·정리합니다. compose DB와 기존 SQLite에는 접근하지 않습니다. Docker가 없으면 테스트가 실패하며 H2 대체나 자동 건너뛰기를 하지 않습니다. Docker 29 호환을 위해 테스트의 Docker API 버전을 1.44로 지정했습니다.

검증 항목:

- 두 방식 각각 100개의 구매자 스레드를 동시에 시작: 성공 1건·충돌 99건, 활성 예약 1개.
- 두 방식 각각 예약 INSERT를 FK 위반으로 실패시켜 상품 상태 롤백 확인.
- 취소 후 재예약, 이전 예약의 취소 요청 차단.
- 자기 상품 예약·타인 취소·구매자의 완료 요청 차단.
- 완료 이후 재예약·취소·완료 차단.
- 취소/완료 경합에서 한 전환만 성공하고 상품·예약 상태 일치.
- DB 유일성 제약으로 두 번째 활성 예약 차단.
- HTTP 인증 실패·본문 사용자 ID 위조 무시·판매자 완료 흐름.

100건은 합성 동시성 실험이며 실사용자 트래픽이나 처리량 성과가 아닙니다. 테스트 클래스에는 `@Transactional`을 붙이지 않아 각 호출이 독립된 실제 커밋을 수행합니다.

참고: [Spring 트랜잭션](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/annotations.html), [MySQL 잠금 읽기](https://dev.mysql.com/doc/refman/8.4/en/innodb-locking-reads.html).

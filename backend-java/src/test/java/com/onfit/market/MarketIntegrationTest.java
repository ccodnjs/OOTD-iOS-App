package com.onfit.market;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import java.util.*;
import java.util.concurrent.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.*;

@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class MarketIntegrationTest {
  @Container static final MySQLContainer<?> MYSQL = new MySQLContainer<>("mysql:8.4");

  @DynamicPropertySource
  static void database(DynamicPropertyRegistry r) {
    r.add("spring.datasource.url", MYSQL::getJdbcUrl);
    r.add("spring.datasource.username", MYSQL::getUsername);
    r.add("spring.datasource.password", MYSQL::getPassword);
  }

  @Autowired MarketService service;
  @Autowired JdbcTemplate db;
  @Autowired MockMvc http;
  @Autowired PasswordEncoder encoder;

  @BeforeEach
  void seed() {
    db.update("DELETE FROM reservations");
    db.update("DELETE FROM products");
    db.update("DELETE FROM app_users");
    String hash = encoder.encode("test-password");
    for (long id = 1; id <= 101; id++) db.update("INSERT INTO app_users VALUES (?,?)", id, hash);
  }

  long product() {
    return service.create(1, "OnFit jacket").id();
  }

  long count(String sql, Object... args) {
    return db.queryForObject(sql, Long.class, args);
  }

  void fails(int status, Runnable action) {
    assertEquals(
        status, assertThrows(ResponseStatusException.class, action::run).getStatusCode().value());
  }

  @ParameterizedTest
  @EnumSource(MarketService.Strategy.class)
  void hundredBuyersExactlyOneWinner(MarketService.Strategy mode) throws Exception {
    long p = product();
    var pool = Executors.newFixedThreadPool(100);
    var ready = new CountDownLatch(100);
    var start = new CountDownLatch(1);
    List<Future<Boolean>> futures = new ArrayList<>();
    try {
      for (long id = 2; id <= 101; id++) {
        long buyer = id;
        futures.add(
            pool.submit(
                () -> {
                  ready.countDown();
                  if (!start.await(15, TimeUnit.SECONDS)) throw new AssertionError("start timeout");
                  try {
                    service.reserve(p, buyer, mode);
                    return true;
                  } catch (ResponseStatusException e) {
                    assertEquals(409, e.getStatusCode().value());
                    return false;
                  }
                }));
      }
      assertTrue(ready.await(15, TimeUnit.SECONDS));
      start.countDown();
      int wins = 0;
      for (var f : futures) if (f.get(45, TimeUnit.SECONDS)) wins++;
      assertEquals(1, wins);
      assertEquals(
          1, count("SELECT COUNT(*) FROM reservations WHERE product_id=? AND status='ACTIVE'", p));
      assertEquals("RESERVED", service.product(p).status());
    } finally {
      start.countDown();
      pool.shutdownNow();
      assertTrue(pool.awaitTermination(10, TimeUnit.SECONDS));
    }
  }

  @ParameterizedTest
  @EnumSource(MarketService.Strategy.class)
  void insertFailureRollsBackProduct(MarketService.Strategy mode) {
    long p = product();
    assertThrows(
        org.springframework.dao.DataIntegrityViolationException.class,
        () -> service.reserve(p, 999999, mode));
    assertEquals("AVAILABLE", service.product(p).status());
    assertEquals(0, count("SELECT COUNT(*) FROM reservations"));
    assertEquals("ACTIVE", service.reserve(p, 2, mode).status());
  }

  @Test
  void cancelThenReserveAndStaleCancelCannotAffectNewReservation() {
    long p = product();
    var first = service.reserve(p, 2);
    service.cancel(p, first.id(), 2);
    var second = service.reserve(p, 3);
    fails(409, () -> service.cancel(p, first.id(), 1));
    assertEquals("RESERVED", service.product(p).status());
    assertEquals(
        1, count("SELECT COUNT(*) FROM reservations WHERE id=? AND status='ACTIVE'", second.id()));
    service.cancel(p, second.id(), 1);
    assertEquals("AVAILABLE", service.product(p).status());
  }

  @Test
  void completeIsTerminalAndOnlySellerCanComplete() {
    long p = product();
    var r = service.reserve(p, 2);
    fails(403, () -> service.complete(p, r.id(), 2));
    fails(403, () -> service.cancel(p, r.id(), 3));
    assertEquals("COMPLETED", service.complete(p, r.id(), 1).status());
    fails(409, () -> service.reserve(p, 3));
    fails(409, () -> service.cancel(p, r.id(), 1));
    fails(409, () -> service.complete(p, r.id(), 1));
    assertEquals("SOLD", service.product(p).status());
  }

  @Test
  void ownershipAndMissingResources() {
    long p = product();
    fails(403, () -> service.reserve(p, 1));
    fails(404, () -> service.reserve(999999, 2));
    var r = service.reserve(p, 2);
    long other = product();
    fails(404, () -> service.cancel(other, r.id(), 1));
    assertEquals("RESERVED", service.product(p).status());
  }

  @Test
  void databaseRejectsSecondActiveReservation() {
    long p = product();
    service.reserve(p, 2);
    assertThrows(
        org.springframework.dao.DataIntegrityViolationException.class,
        () ->
            db.update(
                "INSERT INTO reservations(id,product_id,buyer_id) VALUES (?,?,?)",
                UUID.randomUUID().toString(),
                p,
                3));
  }

  @Test
  void cancelVersusCompleteRaceIsConsistent() throws Exception {
    long p = product();
    var r = service.reserve(p, 2);
    var pool = Executors.newFixedThreadPool(2);
    var start = new CountDownLatch(1);
    try {
      var cancel =
          pool.submit(
              () -> {
                start.await();
                try {
                  service.cancel(p, r.id(), 2);
                  return true;
                } catch (ResponseStatusException e) {
                  assertEquals(409, e.getStatusCode().value());
                  return false;
                }
              });
      var complete =
          pool.submit(
              () -> {
                start.await();
                try {
                  service.complete(p, r.id(), 1);
                  return true;
                } catch (ResponseStatusException e) {
                  assertEquals(409, e.getStatusCode().value());
                  return false;
                }
              });
      start.countDown();
      assertNotEquals(cancel.get(15, TimeUnit.SECONDS), complete.get(15, TimeUnit.SECONDS));
      String status =
          db.queryForObject("SELECT status FROM reservations WHERE id=?", String.class, r.id());
      assertEquals(status.equals("CANCELLED") ? "AVAILABLE" : "SOLD", service.product(p).status());
      assertEquals(0, count("SELECT COUNT(*) FROM reservations WHERE status='ACTIVE'"));
    } finally {
      pool.shutdownNow();
    }
  }

  @Test
  void httpUsesAuthenticatedIdentityAndRejectsUnauthorizedChanges() throws Exception {
    long p = product();
    http.perform(post("/api/products/" + p + "/reservations")).andExpect(status().isUnauthorized());
    http.perform(post("/api/products/" + p + "/reservations").with(httpBasic("2", "wrong")))
        .andExpect(status().isUnauthorized());
    String body =
        http.perform(
                post("/api/products/" + p + "/reservations")
                    .with(httpBasic("2", "test-password"))
                    .contentType("application/json")
                    .content("{\"buyerId\":3}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.buyerId").value(2))
            .andReturn()
            .getResponse()
            .getContentAsString();
    String id = new com.fasterxml.jackson.databind.ObjectMapper().readTree(body).get("id").asText();
    http.perform(
            post("/api/products/" + p + "/reservations/" + id + "/complete")
                .with(httpBasic("2", "test-password")))
        .andExpect(status().isForbidden());
    http.perform(
            post("/api/products/" + p + "/reservations/" + id + "/complete")
                .with(httpBasic("1", "test-password")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("COMPLETED"));
  }
}

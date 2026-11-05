package com.onfit.market;

import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@Transactional
public class MarketService {
  public enum Strategy {
    CONDITIONAL,
    PESSIMISTIC
  }

  private final JdbcTemplate db;
  private final Strategy strategy;

  public MarketService(JdbcTemplate db, @Value("${onfit.reservation-strategy}") Strategy strategy) {
    this.db = db;
    this.strategy = strategy;
  }

  public record Product(long id, long sellerId, String title, String status) {}

  public record Reservation(String id, long productId, long buyerId, String status) {}

  static ResponseStatusException error(HttpStatus status, String code) {
    return new ResponseStatusException(status, code);
  }

  public Product create(long seller, String title) {
    if (title == null || title.isBlank() || title.length() > 200)
      throw error(HttpStatus.BAD_REQUEST, "invalid_title");
    var key = new GeneratedKeyHolder();
    db.update(
        c -> {
          var p =
              c.prepareStatement(
                  "INSERT INTO products(seller_id,title) VALUES (?,?)",
                  java.sql.Statement.RETURN_GENERATED_KEYS);
          p.setLong(1, seller);
          p.setString(2, title.strip());
          return p;
        },
        key);
    return product(key.getKey().longValue(), false);
  }

  public Product product(long id) {
    return product(id, false);
  }

  private Product product(long id, boolean lock) {
    var rows =
        db.query(
            "SELECT * FROM products WHERE id=?" + (lock ? " FOR UPDATE" : ""),
            (r, n) ->
                new Product(
                    r.getLong("id"),
                    r.getLong("seller_id"),
                    r.getString("title"),
                    r.getString("status")),
            id);
    if (rows.isEmpty()) throw error(HttpStatus.NOT_FOUND, "product_not_found");
    return rows.get(0);
  }

  public Reservation reserve(long product, long buyer) {
    return reserve(product, buyer, strategy);
  }

  // Both strategies run inside the Spring proxy's transaction, including the INSERT.
  public Reservation reserve(long productId, long buyer, Strategy mode) {
    if (mode == Strategy.CONDITIONAL) {
      int changed =
          db.update(
              "UPDATE products SET status='RESERVED' WHERE id=? AND status='AVAILABLE' AND"
                  + " seller_id<>?",
              productId,
              buyer);
      if (changed != 1) {
        var p = product(productId, true);
        if (p.sellerId() == buyer) throw error(HttpStatus.FORBIDDEN, "cannot_reserve_own_product");
        throw error(HttpStatus.CONFLICT, "product_unavailable");
      }
    } else {
      var p = product(productId, true);
      if (p.sellerId() == buyer) throw error(HttpStatus.FORBIDDEN, "cannot_reserve_own_product");
      if (!p.status().equals("AVAILABLE")) throw error(HttpStatus.CONFLICT, "product_unavailable");
      db.update("UPDATE products SET status='RESERVED' WHERE id=?", productId);
    }
    String id = UUID.randomUUID().toString();
    db.update(
        "INSERT INTO reservations(id,product_id,buyer_id) VALUES (?,?,?)", id, productId, buyer);
    return new Reservation(id, productId, buyer, "ACTIVE");
  }

  public Reservation cancel(long productId, String reservationId, long actor) {
    return transition(productId, reservationId, actor, false);
  }

  public Reservation complete(long productId, String reservationId, long actor) {
    return transition(productId, reservationId, actor, true);
  }

  private Reservation transition(long productId, String id, long actor, boolean complete) {
    // Always acquire product first: reserve/cancel/complete share the same lock order.
    var p = product(productId, true);
    var rows =
        db.query(
            "SELECT * FROM reservations WHERE id=? AND product_id=? FOR UPDATE",
            (r, n) ->
                new Reservation(
                    r.getString("id"),
                    r.getLong("product_id"),
                    r.getLong("buyer_id"),
                    r.getString("status")),
            id,
            productId);
    if (rows.isEmpty()) throw error(HttpStatus.NOT_FOUND, "reservation_not_found");
    var r = rows.get(0);
    if (actor != p.sellerId() && (complete || actor != r.buyerId()))
      throw error(HttpStatus.FORBIDDEN, "not_allowed");
    if (!r.status().equals("ACTIVE") || !p.status().equals("RESERVED"))
      throw error(HttpStatus.CONFLICT, "invalid_transition");
    String next = complete ? "COMPLETED" : "CANCELLED";
    db.update("UPDATE reservations SET status=? WHERE id=?", next, id);
    db.update(
        "UPDATE products SET status=? WHERE id=?", complete ? "SOLD" : "AVAILABLE", productId);
    return new Reservation(id, productId, r.buyerId(), next);
  }
}

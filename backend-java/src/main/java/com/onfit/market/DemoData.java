package com.onfit.market;

import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@Profile("demo")
class DemoData {
  @Bean
  ApplicationRunner seed(JdbcTemplate db, PasswordEncoder encoder) {
    return args -> {
      for (long id = 1; id <= 3; id++)
        db.update(
            "INSERT IGNORE INTO app_users(id,password_hash) VALUES (?,?)",
            id,
            encoder.encode("onfit-demo"));
    };
  }
}

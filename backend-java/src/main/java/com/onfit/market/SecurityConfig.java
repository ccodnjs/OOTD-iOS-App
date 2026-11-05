package com.onfit.market;

import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {
  @Bean
  PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
  }

  @Bean
  UserDetailsService users(JdbcTemplate db) {
    return name -> {
      if (!name.matches("[1-9][0-9]{0,17}")) throw new UsernameNotFoundException("Unknown user");
      var hashes =
          db.queryForList(
              "SELECT password_hash FROM app_users WHERE id=?", String.class, Long.parseLong(name));
      if (hashes.isEmpty()) throw new UsernameNotFoundException("Unknown user");
      return User.withUsername(name).password(hashes.get(0)).roles("USER").build();
    };
  }

  @Bean
  SecurityFilterChain security(HttpSecurity http) throws Exception {
    // Stateless Authorization header authentication; no cookie-based login.
    return http.csrf(c -> c.disable())
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(a -> a.anyRequest().authenticated())
        .httpBasic(Customizer.withDefaults())
        .build();
  }
}

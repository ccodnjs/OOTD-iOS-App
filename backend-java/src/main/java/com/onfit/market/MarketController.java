package com.onfit.market;

import java.security.Principal;
import java.util.Map;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/products")
class MarketController {
  private final MarketService service;

  MarketController(MarketService service) {
    this.service = service;
  }

  record CreateProduct(String title) {}

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  MarketService.Product create(@RequestBody CreateProduct request, Principal user) {
    return service.create(Long.parseLong(user.getName()), request.title());
  }

  @GetMapping("/{id}")
  MarketService.Product get(@PathVariable long id) {
    return service.product(id);
  }

  @PostMapping("/{id}/reservations")
  @ResponseStatus(HttpStatus.CREATED)
  MarketService.Reservation reserve(@PathVariable long id, Principal user) {
    return service.reserve(id, Long.parseLong(user.getName()));
  }

  @PostMapping("/{id}/reservations/{reservationId}/cancel")
  MarketService.Reservation cancel(
      @PathVariable long id, @PathVariable String reservationId, Principal user) {
    return service.cancel(id, reservationId, Long.parseLong(user.getName()));
  }

  @PostMapping("/{id}/reservations/{reservationId}/complete")
  MarketService.Reservation complete(
      @PathVariable long id, @PathVariable String reservationId, Principal user) {
    return service.complete(id, reservationId, Long.parseLong(user.getName()));
  }

  @ExceptionHandler(ResponseStatusException.class)
  ResponseEntity<?> failure(ResponseStatusException e) {
    return ResponseEntity.status(e.getStatusCode()).body(Map.of("code", e.getReason()));
  }
}

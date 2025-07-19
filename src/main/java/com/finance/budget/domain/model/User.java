package com.finance.budget.domain.model;

import lombok.*;
import lombok.experimental.FieldDefaults;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class User {

    Long id;
    String email;
    String passwordHash;
    String firstName;
    String lastName;
    String phoneEncrypted;

    @Builder.Default
    String defaultCurrency = "USD";

    @Builder.Default
    boolean isActive = true;

    @Builder.Default
    LocalDateTime createdAt = LocalDateTime.now();

    @Builder.Default
    LocalDateTime updatedAt = LocalDateTime.now();
}

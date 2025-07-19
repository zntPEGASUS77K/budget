package com.finance.budget.domain.model;

import com.finance.budget.valueobject.AccountType;
import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Account {
    private Long id;
    private Long userId;
    private String name;
    private AccountType accountType;
    private BigDecimal balance;
    private String currency;
    private boolean isActive;
}

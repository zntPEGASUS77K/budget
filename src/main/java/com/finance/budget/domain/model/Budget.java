package com.finance.budget.domain.model;

import com.finance.budget.domain.valueobject.BudgetPeriod;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Budget {
    private Long id;
    private Long userId;
    private Long categoryId;
    private BigDecimal amount;
    private String currency;
    private BudgetPeriod periodType;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal alertThreshold;
    private boolean isActive;
}

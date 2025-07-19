package com.finance.budget.domain.model;

import com.finance.budget.valueobject.SharedBudgetRole;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SharedBudget {
    private Long id;
    private Long budgetId;
    private Long userId;
    private SharedBudgetRole role;
}

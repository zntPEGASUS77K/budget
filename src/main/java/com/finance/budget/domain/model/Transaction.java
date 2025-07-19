package com.finance.budget.domain.model;

import com.finance.budget.valueobject.TransactionType;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Transaction {
    private Long id;
    private String description;
    private BigDecimal amount;
    private String currency;
    private LocalDateTime transactionDate;
    private Long userId;
    private Long categoryId;
    private Long accountId;
    private TransactionType type;
    private String receiptUrl;
    private List<String> tags;
    private boolean isSynced;
}


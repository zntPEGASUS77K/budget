package com.finance.budget.domain.model;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Category {
    private Long id;
    private String name;
    private String description;
    private String color;
    private String icon;
    private Long parentId;
    private Long userId;
    private boolean isSystem;
    private boolean isDefault;
}

---
name: refactoring
description: Knowledge base for safely improving code structure and reducing technical debt
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: refactoring
---

# Refactoring Skill

Comprehensive knowledge for improving code structure without changing behavior.

## When to Use

- Improving code readability and maintainability
- Reducing technical debt
- Preparing code for new features
- Addressing code review feedback
- Consolidating duplicate code
- Simplifying complex logic
- Applying SOLID principles

## The Golden Rule

> **"Make the change easy, then make the easy change."** - Kent Beck

1. First: Add tests (if missing)
2. Then: Refactor in small, safe steps
3. Finally: Implement the new feature

## Code Smells Catalog

### Bloaters

| Smell | Symptoms | Refactoring |
|-------|----------|-------------|
| **Long Method** | >20 lines, multiple responsibilities | Extract Method |
| **Large Class** | >300 lines, many instance variables | Extract Class |
| **Long Parameter List** | >3-4 parameters | Introduce Parameter Object |
| **Data Clumps** | Same group of variables appears together | Extract Class |
| **Primitive Obsession** | Using primitives instead of small objects | Replace Primitive with Object |

### Object-Orientation Abusers

| Smell | Symptoms | Refactoring |
|-------|----------|-------------|
| **Switch Statements** | Repeated switch/if-else on type | Replace Conditional with Polymorphism |
| **Refused Bequest** | Subclass doesn't use inherited methods | Replace Inheritance with Delegation |
| **Alternative Classes** | Different classes, same interface | Extract Superclass/Interface |

### Change Preventers

| Smell | Symptoms | Refactoring |
|-------|----------|-------------|
| **Divergent Change** | One class changed for multiple reasons | Extract Class |
| **Shotgun Surgery** | One change requires edits everywhere | Move Method, Inline Class |
| **Parallel Inheritance** | Creating subclass requires another | Move Method, Move Field |

### Dispensables

| Smell | Symptoms | Refactoring |
|-------|----------|-------------|
| **Dead Code** | Unreachable/unused code | Delete it |
| **Speculative Generality** | "We might need this" abstractions | Collapse Hierarchy, Inline |
| **Duplicate Code** | Same/similar code in multiple places | Extract Method/Class |
| **Comments** | Comments explaining bad code | Refactor, then remove comments |

### Couplers

| Smell | Symptoms | Refactoring |
|-------|----------|-------------|
| **Feature Envy** | Method uses another class's data more | Move Method |
| **Inappropriate Intimacy** | Classes know too much about each other | Move Method, Extract Class |
| **Message Chains** | a.getB().getC().getD() | Hide Delegate |
| **Middle Man** | Class delegates everything | Remove Middle Man |

## Common Refactoring Patterns

### Extract Method

```python
# BEFORE
def print_invoice(invoice):
    print("====================")
    print("INVOICE")
    print("====================")
    
    total = 0
    for item in invoice.items:
        print(f"{item.name}: ${item.price}")
        total += item.price
    
    print("--------------------")
    print(f"Total: ${total}")
    print("====================")

# AFTER
def print_invoice(invoice):
    print_header()
    total = print_line_items(invoice.items)
    print_footer(total)

def print_header():
    print("====================")
    print("INVOICE")
    print("====================")

def print_line_items(items):
    total = 0
    for item in items:
        print(f"{item.name}: ${item.price}")
        total += item.price
    return total

def print_footer(total):
    print("--------------------")
    print(f"Total: ${total}")
    print("====================")
```

### Replace Conditional with Polymorphism

```python
# BEFORE
def calculate_shipping(order):
    if order.shipping_type == "standard":
        return order.weight * 1.5
    elif order.shipping_type == "express":
        return order.weight * 3.0 + 10
    elif order.shipping_type == "overnight":
        return order.weight * 5.0 + 25
    else:
        raise ValueError("Unknown shipping type")

# AFTER
class ShippingStrategy(ABC):
    @abstractmethod
    def calculate(self, weight: float) -> float:
        pass

class StandardShipping(ShippingStrategy):
    def calculate(self, weight: float) -> float:
        return weight * 1.5

class ExpressShipping(ShippingStrategy):
    def calculate(self, weight: float) -> float:
        return weight * 3.0 + 10

class OvernightShipping(ShippingStrategy):
    def calculate(self, weight: float) -> float:
        return weight * 5.0 + 25

def calculate_shipping(order):
    return order.shipping_strategy.calculate(order.weight)
```

### Introduce Parameter Object

```python
# BEFORE
def create_event(name, start_date, end_date, start_time, end_time, timezone):
    ...

def validate_event(start_date, end_date, start_time, end_time, timezone):
    ...

# AFTER
@dataclass
class DateTimeRange:
    start_date: date
    end_date: date
    start_time: time
    end_time: time
    timezone: str
    
    def duration(self) -> timedelta:
        ...
    
    def is_valid(self) -> bool:
        ...

def create_event(name: str, when: DateTimeRange):
    ...

def validate_event(when: DateTimeRange):
    ...
```

### Replace Magic Numbers/Strings

```python
# BEFORE
def calculate_discount(total):
    if total > 100:
        return total * 0.1
    elif total > 50:
        return total * 0.05
    return 0

if user.role == "admin":
    ...

# AFTER
BULK_DISCOUNT_THRESHOLD = 100
STANDARD_DISCOUNT_THRESHOLD = 50
BULK_DISCOUNT_RATE = 0.1
STANDARD_DISCOUNT_RATE = 0.05

class UserRole:
    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"

def calculate_discount(total):
    if total > BULK_DISCOUNT_THRESHOLD:
        return total * BULK_DISCOUNT_RATE
    elif total > STANDARD_DISCOUNT_THRESHOLD:
        return total * STANDARD_DISCOUNT_RATE
    return 0

if user.role == UserRole.ADMIN:
    ...
```

## SOLID Principles Checklist

### Single Responsibility (SRP)
- [ ] Class has one reason to change
- [ ] Method does one thing
- [ ] Can describe purpose without "and"

### Open/Closed (OCP)
- [ ] Open for extension, closed for modification
- [ ] New behavior via new classes, not editing existing
- [ ] Use abstractions/interfaces

### Liskov Substitution (LSP)
- [ ] Subclasses can replace parent classes
- [ ] No surprising behavior changes
- [ ] Preconditions not strengthened, postconditions not weakened

### Interface Segregation (ISP)
- [ ] No "fat" interfaces
- [ ] Clients don't depend on methods they don't use
- [ ] Many specific interfaces > one general interface

### Dependency Inversion (DIP)
- [ ] Depend on abstractions, not concretions
- [ ] High-level modules don't depend on low-level modules
- [ ] Dependencies injected, not created internally

## Safe Refactoring Process

```
1. VERIFY TESTS EXIST
   └─ No tests? Write characterization tests first
   
2. MAKE ONE SMALL CHANGE
   └─ Rename, extract, move - one at a time
   
3. RUN TESTS
   └─ All green? Continue
   └─ Red? Revert immediately
   
4. COMMIT
   └─ Small, atomic commits
   └─ "Refactor: Extract UserValidator class"
   
5. REPEAT
   └─ Next small change
```

### Commit Message Prefixes for Refactoring

```
Refactor: Extract method calculate_tax
Refactor: Rename User -> Customer  
Refactor: Move validation to separate module
Refactor: Replace conditionals with strategy pattern
Refactor: Remove dead code in payment module
```

## Refactoring Output Template

```markdown
## Refactoring Plan: [Module/Feature Name]

### Current Issues
| Code Smell | Location | Impact |
|------------|----------|--------|
| Long Method | order_service.py:45 | Hard to test |
| Duplicate Code | utils.py, helpers.py | Bug risk |

### Proposed Changes
1. **Extract `OrderValidator` class** from `OrderService`
   - Move validation methods
   - Inject as dependency
   
2. **Consolidate duplicate `format_currency`**
   - Keep in `utils.py`
   - Update imports

### Risk Assessment
- [ ] Tests exist for affected code
- [ ] Changes are reversible
- [ ] No public API changes (or documented)

### Execution Steps
- [ ] Step 1: Add missing tests
- [ ] Step 2: Extract class
- [ ] Step 3: Run tests
- [ ] Step 4: Update imports
- [ ] Step 5: Run tests
- [ ] Step 6: Remove old code
```

---

## TO FILL: Your Refactoring Configuration

### Codebase-Specific Smells

```markdown
<!-- Add anti-patterns specific to your codebase -->

<!-- Example:
- God objects: UserManager, AppController
- Circular dependencies: services <-> utils
- Inconsistent naming: mix of camelCase and snake_case
-->
```

### Priority Technical Debt

```markdown
<!-- List known technical debt to address -->

<!-- Example:
| Area | Debt | Priority | Effort |
|------|------|----------|--------|
| Auth | Hardcoded roles | High | Medium |
| API | No input validation | Critical | High |
-->
```

### Refactoring Boundaries

```markdown
<!-- Define what CAN and CANNOT be refactored freely -->

<!-- Example:
Safe to refactor (internal):
- /src/services/*
- /src/utils/*

Requires approval (public API):
- /src/api/*
- /src/sdk/*

Do not touch:
- /vendor/*
- /legacy/* (scheduled for removal)
-->
```

### Code Style Conventions

```markdown
<!-- Add your project's conventions -->

<!-- Example:
- Max function length: 30 lines
- Max file length: 300 lines
- Max class methods: 10
- Naming: snake_case for Python, camelCase for JS
-->
```

### Refactoring Commands

```bash
# Add your refactoring-related commands:
#
# Run linter:
# 
# Run type checker:
#
# Find unused code:
#
# Check complexity:
#
```

---
name: documentation
description: Knowledge base for generating technical documentation with mermaid diagrams
license: MIT
compatibility: opencode
metadata:
  audience: backend-engineers
  workflow: documentation
---

# Documentation Skill

Knowledge and patterns for creating comprehensive technical documentation.

## When to Use

- Generating README files
- Creating API documentation
- Documenting architecture and system design
- Building database schema documentation
- Writing developer guides and onboarding docs

## Mermaid Diagram Patterns

### Architecture Diagrams

```mermaid
flowchart TD
    subgraph frontend [Frontend Layer]
        Web[Web App]
        Mobile[Mobile App]
    end
    
    subgraph backend [Backend Services]
        API[API Gateway]
        Auth[Auth Service]
        Core[Core Service]
    end
    
    subgraph data [Data Layer]
        DB[(PostgreSQL)]
        Cache[(Redis)]
        Queue[Message Queue]
    end
    
    Web --> API
    Mobile --> API
    API --> Auth
    API --> Core
    Core --> DB
    Core --> Cache
    Core --> Queue
```

### Sequence Diagrams (API Flows)

```mermaid
sequenceDiagram
    participant C as Client
    participant A as API
    participant S as Service
    participant D as Database
    
    C->>A: POST /resource
    A->>A: Validate request
    A->>S: Process request
    S->>D: Query/Insert
    D-->>S: Result
    S-->>A: Response
    A-->>C: 201 Created
```

### Entity Relationship Diagrams

```mermaid
erDiagram
    USER ||--o{ ORDER : places
    USER {
        uuid id PK
        string email UK
        string name
        timestamp created_at
    }
    ORDER ||--|{ ORDER_ITEM : contains
    ORDER {
        uuid id PK
        uuid user_id FK
        decimal total
        string status
    }
    ORDER_ITEM {
        uuid id PK
        uuid order_id FK
        uuid product_id FK
        int quantity
    }
```

### State Diagrams

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Pending: submit
    Pending --> Approved: approve
    Pending --> Rejected: reject
    Rejected --> Draft: revise
    Approved --> Published: publish
    Published --> [*]
```

## Documentation Templates

### API Endpoint Template

```markdown
## Endpoint Name

`METHOD /path/to/endpoint`

Description of what this endpoint does.

### Request

**Headers:**
| Header | Required | Description |
|--------|----------|-------------|
| Authorization | Yes | Bearer token |

**Body:**
```json
{
  "field": "value"
}
```

### Response

**Success (200):**
```json
{
  "data": {}
}
```

**Errors:**
| Code | Description |
|------|-------------|
| 400 | Invalid request |
| 401 | Unauthorized |
```

### README Template

```markdown
# Project Name

Brief description of the project.

## Architecture

[Mermaid diagram here]

## Getting Started

### Prerequisites
- Requirement 1
- Requirement 2

### Installation
```bash
# Installation commands
```

### Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| DATABASE_URL | Yes | - | PostgreSQL connection string |

## API Reference

See [API Documentation](./docs/api.md)

## Development

### Running Tests
```bash
# Test commands
```

### Code Style
Description of code style and linting.

## Deployment

Deployment instructions and requirements.
```

## Best Practices

1. **Start with diagrams** - Visualize before writing prose
2. **Use consistent terminology** - Define terms in a glossary if needed
3. **Include examples** - Real code examples for every concept
4. **Keep it updated** - Documentation rots quickly
5. **Link related docs** - Cross-reference for discoverability
6. **Version your docs** - Match documentation to code versions

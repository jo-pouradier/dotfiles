---
name: framework-specific
description: Knowledge base for framework-specific patterns and best practices
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: development
---

# Framework-Specific Skill

Centralized knowledge for framework-specific patterns, conventions, and best practices.

## When to Use

- Building new features in a specific framework
- Following framework conventions and idioms
- Avoiding common pitfalls and anti-patterns
- Structuring projects according to best practices
- Optimizing framework-specific performance

---

## Framework: Spring Boot + jOOQ

### Overview

```yaml
Name: Spring Boot + jOOQ
Version: Spring Boot 3.x / jOOQ 3.18+
Language: Java 17+ / Kotlin
Type: Backend
Documentation: 
  - https://docs.spring.io/spring-boot/docs/current/reference/html/
  - https://www.jooq.org/doc/latest/manual/
```

### Project Structure

```
src/
├── main/
│   ├── java/com/example/app/
│   │   ├── Application.java              # @SpringBootApplication entry point
│   │   ├── config/                        # Configuration classes
│   │   │   ├── JooqConfig.java           # jOOQ configuration
│   │   │   ├── SecurityConfig.java
│   │   │   └── WebConfig.java
│   │   ├── controller/                    # REST Controllers (Web Layer)
│   │   │   ├── UserController.java
│   │   │   └── OrderController.java
│   │   ├── service/                       # Business Logic Layer
│   │   │   ├── UserService.java
│   │   │   └── impl/
│   │   │       └── UserServiceImpl.java
│   │   ├── repository/                    # Data Access Layer (jOOQ)
│   │   │   ├── UserRepository.java
│   │   │   └── impl/
│   │   │       └── UserRepositoryImpl.java
│   │   ├── dto/                           # Data Transfer Objects
│   │   │   ├── request/
│   │   │   │   └── CreateUserRequest.java
│   │   │   └── response/
│   │   │       └── UserResponse.java
│   │   ├── mapper/                        # Record <-> DTO mappers
│   │   │   └── UserMapper.java
│   │   ├── exception/                     # Custom exceptions & handlers
│   │   │   ├── ResourceNotFoundException.java
│   │   │   └── GlobalExceptionHandler.java
│   │   └── util/                          # Utilities
│   └── resources/
│       ├── application.yml                # Main config
│       ├── application-dev.yml            # Dev profile
│       ├── application-prod.yml           # Prod profile
│       └── db/migration/                  # Flyway migrations
│           ├── V1__create_users_table.sql
│           └── V2__create_orders_table.sql
├── generated/                             # jOOQ generated classes (gitignored or committed)
│   └── jooq/com/example/app/
│       └── tables/
│           ├── Users.java
│           ├── Orders.java
│           └── records/
│               ├── UsersRecord.java
│               └── OrdersRecord.java
└── test/
    └── java/com/example/app/
        ├── controller/                    # @WebMvcTest
        ├── service/                       # Unit tests
        ├── repository/                    # @JooqTest or @SpringBootTest
        └── integration/                   # @SpringBootTest
```

### Key Patterns

#### Layered Architecture

```
┌─────────────────────────────────────┐
│           Controller Layer          │  @RestController
│         (HTTP / Validation)         │  Handles requests, returns responses
├─────────────────────────────────────┤
│            Service Layer            │  @Service
│         (Business Logic)            │  Orchestrates operations, transactions
├─────────────────────────────────────┤
│          Repository Layer           │  @Repository (jOOQ DSLContext)
│           (Data Access)             │  Type-safe SQL queries
├─────────────────────────────────────┤
│        jOOQ Generated Classes       │  Tables, Records, POJOs
│           (Schema Model)            │  Generated from DB schema
└─────────────────────────────────────┘
```

#### jOOQ Configuration

```java
@Configuration
public class JooqConfig {

    @Bean
    public DefaultConfigurationCustomizer jooqConfigurationCustomizer() {
        return configuration -> configuration
                .set(SQLDialect.POSTGRES)
                .set(new Settings()
                        .withRenderNameCase(RenderNameCase.LOWER)
                        .withRenderQuotedNames(RenderQuotedNames.NEVER)
                        .withExecuteWithOptimisticLocking(true));
    }
}
```

#### REST Controller

```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Validated
public class UserController {

    private final UserService userService;

    @GetMapping
    public ResponseEntity<Page<UserResponse>> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(userService.findAll(page, size));
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUser(@PathVariable UUID id) {
        return ResponseEntity.ok(userService.findById(id));
    }

    @PostMapping
    public ResponseEntity<UserResponse> createUser(
            @Valid @RequestBody CreateUserRequest request) {
        UserResponse created = userService.create(request);
        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(created.getId())
                .toUri();
        return ResponseEntity.created(location).body(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<UserResponse> updateUser(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateUserRequest request) {
        return ResponseEntity.ok(userService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable UUID id) {
        userService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

#### Service Layer with Transactions

```java
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    @Override
    public Page<UserResponse> findAll(int page, int size) {
        List<UserResponse> users = userRepository.findAll(page, size)
                .stream()
                .map(userMapper::toResponse)
                .toList();
        long total = userRepository.count();
        return new PageImpl<>(users, PageRequest.of(page, size), total);
    }

    @Override
    public UserResponse findById(UUID id) {
        return userRepository.findById(id)
                .map(userMapper::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));
    }

    @Override
    @Transactional
    public UserResponse create(CreateUserRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateResourceException("User", "email", request.getEmail());
        }

        UsersRecord record = userMapper.toRecord(request);
        record.setPassword(passwordEncoder.encode(request.getPassword()));
        record.setStatus(UserStatus.ACTIVE.name());
        record.setCreatedAt(LocalDateTime.now());

        UsersRecord created = userRepository.insert(record);
        return userMapper.toResponse(created);
    }

    @Override
    @Transactional
    public void delete(UUID id) {
        if (!userRepository.existsById(id)) {
            throw new ResourceNotFoundException("User", "id", id);
        }
        userRepository.deleteById(id);
    }
}
```

#### jOOQ Repository

```java
public interface UserRepository {
    List<UsersRecord> findAll(int page, int size);
    Optional<UsersRecord> findById(UUID id);
    Optional<UsersRecord> findByEmail(String email);
    boolean existsByEmail(String email);
    boolean existsById(UUID id);
    UsersRecord insert(UsersRecord record);
    void update(UsersRecord record);
    void deleteById(UUID id);
    long count();
}

@Repository
@RequiredArgsConstructor
public class UserRepositoryImpl implements UserRepository {

    private final DSLContext dsl;

    @Override
    public List<UsersRecord> findAll(int page, int size) {
        return dsl.selectFrom(USERS)
                .orderBy(USERS.CREATED_AT.desc())
                .offset(page * size)
                .limit(size)
                .fetch();
    }

    @Override
    public Optional<UsersRecord> findById(UUID id) {
        return dsl.selectFrom(USERS)
                .where(USERS.ID.eq(id))
                .fetchOptional();
    }

    @Override
    public Optional<UsersRecord> findByEmail(String email) {
        return dsl.selectFrom(USERS)
                .where(USERS.EMAIL.eq(email))
                .fetchOptional();
    }

    @Override
    public boolean existsByEmail(String email) {
        return dsl.fetchExists(
                dsl.selectFrom(USERS)
                   .where(USERS.EMAIL.eq(email))
        );
    }

    @Override
    public boolean existsById(UUID id) {
        return dsl.fetchExists(
                dsl.selectFrom(USERS)
                   .where(USERS.ID.eq(id))
        );
    }

    @Override
    public UsersRecord insert(UsersRecord record) {
        record.setId(UUID.randomUUID());
        record.attach(dsl.configuration());
        record.insert();
        return record;
    }

    @Override
    public void update(UsersRecord record) {
        record.attach(dsl.configuration());
        record.update();
    }

    @Override
    public void deleteById(UUID id) {
        dsl.deleteFrom(USERS)
           .where(USERS.ID.eq(id))
           .execute();
    }

    @Override
    public long count() {
        return dsl.selectCount()
                  .from(USERS)
                  .fetchOne(0, Long.class);
    }
}
```

#### Complex Queries with jOOQ

```java
// Join query with mapping
public List<UserWithOrdersDto> findUsersWithOrders() {
    return dsl.select(
                USERS.ID,
                USERS.EMAIL,
                USERS.NAME,
                count(ORDERS.ID).as("orderCount"),
                sum(ORDERS.TOTAL).as("totalSpent")
            )
            .from(USERS)
            .leftJoin(ORDERS).on(ORDERS.USER_ID.eq(USERS.ID))
            .groupBy(USERS.ID, USERS.EMAIL, USERS.NAME)
            .fetch(record -> new UserWithOrdersDto(
                record.get(USERS.ID),
                record.get(USERS.EMAIL),
                record.get(USERS.NAME),
                record.get("orderCount", Long.class),
                record.get("totalSpent", BigDecimal.class)
            ));
}

// Conditional query building
public List<UsersRecord> search(UserSearchCriteria criteria) {
    var query = dsl.selectFrom(USERS).where(DSL.trueCondition());

    if (criteria.getEmail() != null) {
        query = query.and(USERS.EMAIL.containsIgnoreCase(criteria.getEmail()));
    }
    if (criteria.getName() != null) {
        query = query.and(USERS.NAME.containsIgnoreCase(criteria.getName()));
    }
    if (criteria.getStatus() != null) {
        query = query.and(USERS.STATUS.eq(criteria.getStatus().name()));
    }
    if (criteria.getCreatedAfter() != null) {
        query = query.and(USERS.CREATED_AT.ge(criteria.getCreatedAfter()));
    }

    return query.orderBy(USERS.CREATED_AT.desc())
                .fetch();
}

// Batch insert
@Transactional
public void batchInsert(List<UsersRecord> records) {
    dsl.batchInsert(records).execute();
}

// Upsert (INSERT ON CONFLICT)
public void upsert(UsersRecord record) {
    dsl.insertInto(USERS)
       .set(record)
       .onConflict(USERS.EMAIL)
       .doUpdate()
       .set(USERS.NAME, record.getName())
       .set(USERS.UPDATED_AT, LocalDateTime.now())
       .execute();
}

// CTE (Common Table Expression)
public List<UserRankDto> getUsersByOrderRank() {
    var rankedUsers = name("ranked_users").as(
        select(
            USERS.ID,
            USERS.NAME,
            count(ORDERS.ID).as("order_count"),
            rank().over(orderBy(count(ORDERS.ID).desc())).as("rank")
        )
        .from(USERS)
        .leftJoin(ORDERS).on(ORDERS.USER_ID.eq(USERS.ID))
        .groupBy(USERS.ID, USERS.NAME)
    );

    return dsl.with(rankedUsers)
              .selectFrom(rankedUsers)
              .where(field("rank").le(10))
              .fetch(record -> new UserRankDto(
                  record.get(USERS.ID),
                  record.get(USERS.NAME),
                  record.get("order_count", Long.class),
                  record.get("rank", Long.class)
              ));
}
```

#### DTOs with Validation

```java
// Request DTO
@Data
@Builder
public class CreateUserRequest {

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Password is required")
    @Size(min = 8, max = 100, message = "Password must be 8-100 characters")
    @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).*$",
             message = "Password must contain uppercase, lowercase, and digit")
    private String password;

    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 100)
    private String name;
}

// Response DTO
@Data
@Builder
public class UserResponse {
    private UUID id;
    private String email;
    private String name;
    private UserStatus status;
    private LocalDateTime createdAt;
}
```

#### Mapper (jOOQ Record <-> DTO)

```java
@Mapper(componentModel = "spring")
public interface UserMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "password", ignore = true)
    @Mapping(target = "status", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    UsersRecord toRecord(CreateUserRequest request);

    @Mapping(target = "status", expression = "java(UserStatus.valueOf(record.getStatus()))")
    UserResponse toResponse(UsersRecord record);

    List<UserResponse> toResponseList(List<UsersRecord> records);
}
```

#### Global Exception Handler

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        log.warn("Resource not found: {}", ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(ErrorResponse.of(ex.getMessage(), "RESOURCE_NOT_FOUND"));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .collect(Collectors.toMap(
                        FieldError::getField,
                        error -> error.getDefaultMessage() != null ?
                                 error.getDefaultMessage() : "Invalid value",
                        (a, b) -> a));

        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ErrorResponse.of("Validation failed", "VALIDATION_ERROR", errors));
    }

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<ErrorResponse> handleDataAccess(DataAccessException ex) {
        log.error("Database error", ex);
        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(ErrorResponse.of("Database operation failed", "DATA_ACCESS_ERROR"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneral(Exception ex) {
        log.error("Unexpected error", ex);
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ErrorResponse.of("Internal server error", "INTERNAL_ERROR"));
    }
}
```

#### Configuration with Profiles

```yaml
# application.yml
spring:
  application:
    name: my-app
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}
  datasource:
    hikari:
      maximum-pool-size: 10
      minimum-idle: 2
  flyway:
    enabled: true
    locations: classpath:db/migration

server:
  port: 8080
  error:
    include-message: always
    include-binding-errors: always

# jOOQ settings
spring.jooq.sql-dialect: POSTGRES

---
# application-dev.yml
spring:
  config:
    activate:
      on-profile: dev
  datasource:
    url: jdbc:postgresql://localhost:5432/myapp_dev
    username: dev
    password: dev

logging:
  level:
    org.jooq: DEBUG
    com.example.app: DEBUG

---
# application-prod.yml
spring:
  config:
    activate:
      on-profile: prod
  datasource:
    url: ${DATABASE_URL}
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5

logging:
  level:
    org.jooq: INFO
    com.example.app: INFO
```

#### Security Configuration (Spring Security 6)

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;
    private final AuthenticationProvider authenticationProvider;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/v1/auth/**").permitAll()
                        .requestMatchers("/actuator/health").permitAll()
                        .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                        .anyRequest().authenticated())
                .authenticationProvider(authenticationProvider)
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of("http://localhost:3000"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
```

### jOOQ Code Generation (Maven)

```xml
<plugin>
    <groupId>org.jooq</groupId>
    <artifactId>jooq-codegen-maven</artifactId>
    <version>${jooq.version}</version>
    <executions>
        <execution>
            <id>jooq-codegen</id>
            <phase>generate-sources</phase>
            <goals>
                <goal>generate</goal>
            </goals>
        </execution>
    </executions>
    <configuration>
        <jdbc>
            <driver>org.postgresql.Driver</driver>
            <url>jdbc:postgresql://localhost:5432/myapp_dev</url>
            <user>dev</user>
            <password>dev</password>
        </jdbc>
        <generator>
            <database>
                <name>org.jooq.meta.postgres.PostgresDatabase</name>
                <includes>.*</includes>
                <excludes>flyway_schema_history</excludes>
                <inputSchema>public</inputSchema>
            </database>
            <generate>
                <records>true</records>
                <pojos>false</pojos>
                <daos>false</daos>
                <fluentSetters>true</fluentSetters>
            </generate>
            <target>
                <packageName>com.example.app.generated.jooq</packageName>
                <directory>src/generated/java</directory>
            </target>
        </generator>
    </configuration>
</plugin>
```

### Common Gotchas

| Gotcha | Description | Solution |
|--------|-------------|----------|
| **Record not attached** | Calling `store()`/`insert()` on detached record | Call `record.attach(dsl.configuration())` first |
| **Transaction not rolling back** | Checked exceptions don't trigger rollback | Use `@Transactional(rollbackFor = Exception.class)` |
| **N+1 queries** | Fetching related records in loop | Use JOINs or batch fetch with `IN` clause |
| **Generated code stale** | Schema changed but code not regenerated | Run `mvn jooq-codegen:generate` after migrations |
| **Type mismatch** | Java types don't match DB types | Configure type bindings in jOOQ codegen |
| **Connection pool exhaustion** | Long-running queries hold connections | Set proper timeouts, use async for long ops |
| **Optimistic locking fails** | Concurrent updates | Enable optimistic locking, handle `DataChangedException` |

### Performance Tips

- Use **pagination** with `OFFSET`/`LIMIT` for all list queries
- Configure **connection pooling** (HikariCP) properly
- Use **batch operations** (`batchInsert`, `batchUpdate`) for bulk data
- Add **indexes** for frequently queried columns
- Use **`fetchLazy()`** for large result sets
- Enable **query caching** where appropriate
- Use **projections** (select specific columns) instead of `SELECT *`
- Consider **async queries** with `CompletableFuture` for non-blocking ops

### Testing Approach

```java
// Unit Test (Service Layer) - Fast, no Spring context
@ExtendWith(MockitoExtension.class)
class UserServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserMapper userMapper;

    @InjectMocks
    private UserServiceImpl userService;

    @Test
    void findById_WhenExists_ReturnsUser() {
        // Arrange
        UUID id = UUID.randomUUID();
        UsersRecord record = new UsersRecord();
        record.setId(id);
        record.setEmail("test@example.com");

        UserResponse expected = UserResponse.builder()
                .id(id)
                .email("test@example.com")
                .build();

        when(userRepository.findById(id)).thenReturn(Optional.of(record));
        when(userMapper.toResponse(record)).thenReturn(expected);

        // Act
        UserResponse result = userService.findById(id);

        // Assert
        assertThat(result).isEqualTo(expected);
        verify(userRepository).findById(id);
    }
}

// Repository Test with real DB
@SpringBootTest
@Testcontainers
class UserRepositoryTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DSLContext dsl;

    @BeforeEach
    void setUp() {
        dsl.deleteFrom(USERS).execute();
    }

    @Test
    void findByEmail_WhenExists_ReturnsUser() {
        // Arrange
        UsersRecord record = new UsersRecord();
        record.setId(UUID.randomUUID());
        record.setEmail("test@example.com");
        record.setPassword("encoded");
        record.setName("Test");
        record.setStatus("ACTIVE");
        record.setCreatedAt(LocalDateTime.now());
        record.attach(dsl.configuration());
        record.insert();

        // Act
        Optional<UsersRecord> found = userRepository.findByEmail("test@example.com");

        // Assert
        assertThat(found).isPresent();
        assertThat(found.get().getEmail()).isEqualTo("test@example.com");
    }
}

// Integration Test - Full Spring context
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
class UserIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void fullUserLifecycle() {
        // Create
        CreateUserRequest createRequest = CreateUserRequest.builder()
                .email("integration@test.com")
                .password("Password123")
                .name("Integration Test")
                .build();

        ResponseEntity<UserResponse> createResponse = restTemplate.postForEntity(
                "/api/v1/users", createRequest, UserResponse.class);

        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        UUID userId = createResponse.getBody().getId();

        // Read
        ResponseEntity<UserResponse> getResponse = restTemplate.getForEntity(
                "/api/v1/users/{id}", UserResponse.class, userId);

        assertThat(getResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(getResponse.getBody().getEmail()).isEqualTo("integration@test.com");
    }
}
```

### Useful Commands

```bash
# Development
./mvnw spring-boot:run
./gradlew bootRun

# Generate jOOQ classes
./mvnw jooq-codegen:generate
./gradlew generateJooq

# Build
./mvnw clean package -DskipTests
./gradlew clean build -x test

# Run tests
./mvnw test
./gradlew test

# Run with profile
java -jar target/app.jar --spring.profiles.active=prod

# Flyway commands
./mvnw flyway:migrate
./mvnw flyway:info
./mvnw flyway:repair
```

### Essential Dependencies (pom.xml)

```xml
<dependencies>
    <!-- Core -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-jooq</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>

    <!-- Database -->
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-core</artifactId>
    </dependency>

    <!-- Utilities -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.mapstruct</groupId>
        <artifactId>mapstruct</artifactId>
        <version>1.5.5.Final</version>
    </dependency>

    <!-- Testing -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>postgresql</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

---

## Framework: React + React Router

### Overview

```yaml
Name: React + React Router
Version: React 18.x / React Router 6.x
Language: TypeScript
Type: Frontend
Documentation:
  - https://react.dev
  - https://reactrouter.com
```

### Project Structure

```
src/
├── main.tsx                   # Entry point, router setup
├── App.tsx                    # Root component
├── routes/                    # Route definitions
│   ├── index.tsx             # Route configuration
│   ├── ProtectedRoute.tsx    # Auth guard
│   └── layouts/              # Layout components
│       ├── RootLayout.tsx
│       ├── DashboardLayout.tsx
│       └── AuthLayout.tsx
├── pages/                     # Route page components
│   ├── Home.tsx
│   ├── Login.tsx
│   ├── Dashboard/
│   │   ├── index.tsx
│   │   ├── Users.tsx
│   │   └── Settings.tsx
│   └── NotFound.tsx
├── components/                # Reusable UI components
│   ├── ui/                   # Base components (Button, Input, Card)
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   └── index.ts
│   └── features/             # Feature-specific components
│       ├── UserCard.tsx
│       └── OrderList.tsx
├── hooks/                     # Custom hooks
│   ├── useAuth.ts
│   ├── useApi.ts
│   └── useLocalStorage.ts
├── services/                  # API calls
│   ├── api.ts                # Axios/fetch instance
│   ├── auth.service.ts
│   └── user.service.ts
├── stores/                    # State management (Zustand/Context)
│   ├── authStore.ts
│   └── uiStore.ts
├── types/                     # TypeScript types
│   ├── user.ts
│   └── api.ts
├── utils/                     # Helper functions
│   ├── format.ts
│   └── validation.ts
└── styles/                    # Global styles
    └── globals.css
```

### Key Patterns

#### Router Setup (React Router 6)

```tsx
// src/routes/index.tsx
import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import RootLayout from './layouts/RootLayout';
import DashboardLayout from './layouts/DashboardLayout';
import AuthLayout from './layouts/AuthLayout';
import ProtectedRoute from './ProtectedRoute';
import Home from '@/pages/Home';
import Login from '@/pages/Login';
import Dashboard from '@/pages/Dashboard';
import Users from '@/pages/Dashboard/Users';
import Settings from '@/pages/Dashboard/Settings';
import NotFound from '@/pages/NotFound';

const router = createBrowserRouter([
  {
    path: '/',
    element: <RootLayout />,
    errorElement: <NotFound />,
    children: [
      { index: true, element: <Home /> },
      {
        path: 'auth',
        element: <AuthLayout />,
        children: [
          { path: 'login', element: <Login /> },
          { path: 'register', element: <Register /> },
        ],
      },
      {
        path: 'dashboard',
        element: (
          <ProtectedRoute>
            <DashboardLayout />
          </ProtectedRoute>
        ),
        children: [
          { index: true, element: <Dashboard /> },
          { path: 'users', element: <Users /> },
          { path: 'users/:userId', element: <UserDetail /> },
          { path: 'settings', element: <Settings /> },
        ],
      },
    ],
  },
]);

export default function AppRouter() {
  return <RouterProvider router={router} />;
}

// src/main.tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import AppRouter from './routes';
import './styles/globals.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <AppRouter />
  </React.StrictMode>
);
```

#### Layout Components

```tsx
// src/routes/layouts/RootLayout.tsx
import { Outlet, ScrollRestoration } from 'react-router-dom';
import { Toaster } from '@/components/ui/Toaster';

export default function RootLayout() {
  return (
    <>
      <Outlet />
      <ScrollRestoration />
      <Toaster />
    </>
  );
}

// src/routes/layouts/DashboardLayout.tsx
import { Outlet, NavLink } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';

export default function DashboardLayout() {
  const { user, logout } = useAuth();

  return (
    <div className="flex h-screen">
      {/* Sidebar */}
      <aside className="w-64 bg-gray-800 text-white">
        <nav className="p-4 space-y-2">
          <NavLink
            to="/dashboard"
            end
            className={({ isActive }) =>
              `block p-2 rounded ${isActive ? 'bg-gray-700' : 'hover:bg-gray-700'}`
            }
          >
            Dashboard
          </NavLink>
          <NavLink
            to="/dashboard/users"
            className={({ isActive }) =>
              `block p-2 rounded ${isActive ? 'bg-gray-700' : 'hover:bg-gray-700'}`
            }
          >
            Users
          </NavLink>
          <NavLink
            to="/dashboard/settings"
            className={({ isActive }) =>
              `block p-2 rounded ${isActive ? 'bg-gray-700' : 'hover:bg-gray-700'}`
            }
          >
            Settings
          </NavLink>
        </nav>
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-auto">
        <header className="bg-white shadow p-4 flex justify-between">
          <h1>Welcome, {user?.name}</h1>
          <button onClick={logout}>Logout</button>
        </header>
        <div className="p-6">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
```

#### Protected Route

```tsx
// src/routes/ProtectedRoute.tsx
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredRole?: string;
}

export default function ProtectedRoute({
  children,
  requiredRole,
}: ProtectedRouteProps) {
  const { user, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return <div>Loading...</div>;
  }

  if (!user) {
    // Redirect to login, preserving the intended destination
    return <Navigate to="/auth/login" state={{ from: location }} replace />;
  }

  if (requiredRole && user.role !== requiredRole) {
    return <Navigate to="/unauthorized" replace />;
  }

  return <>{children}</>;
}
```

#### Navigation & Route Params

```tsx
// src/pages/Dashboard/Users.tsx
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useUsers } from '@/hooks/useUsers';

export default function Users() {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();

  const page = Number(searchParams.get('page')) || 1;
  const search = searchParams.get('search') || '';

  const { data: users, isLoading } = useUsers({ page, search });

  const handleSearch = (value: string) => {
    setSearchParams({ search: value, page: '1' });
  };

  const handlePageChange = (newPage: number) => {
    setSearchParams({ ...Object.fromEntries(searchParams), page: String(newPage) });
  };

  const handleUserClick = (userId: string) => {
    navigate(`/dashboard/users/${userId}`);
  };

  return (
    <div>
      <input
        type="search"
        placeholder="Search users..."
        value={search}
        onChange={(e) => handleSearch(e.target.value)}
      />

      {isLoading ? (
        <div>Loading...</div>
      ) : (
        <ul>
          {users?.map((user) => (
            <li key={user.id} onClick={() => handleUserClick(user.id)}>
              {user.name}
            </li>
          ))}
        </ul>
      )}

      <Pagination
        currentPage={page}
        onPageChange={handlePageChange}
      />
    </div>
  );
}

// src/pages/Dashboard/UserDetail.tsx
import { useParams, useNavigate } from 'react-router-dom';
import { useUser } from '@/hooks/useUser';

export default function UserDetail() {
  const { userId } = useParams<{ userId: string }>();
  const navigate = useNavigate();
  const { data: user, isLoading, error } = useUser(userId!);

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading user</div>;
  if (!user) return <div>User not found</div>;

  return (
    <div>
      <button onClick={() => navigate(-1)}>Back</button>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}
```

#### Auth Hook with React Router

```tsx
// src/hooks/useAuth.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { useNavigate, useLocation } from 'react-router-dom';
import { authService } from '@/services/auth.service';
import type { User, LoginCredentials } from '@/types/user';

interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  setUser: (user: User | null) => void;
  setToken: (token: string | null) => void;
  setLoading: (loading: boolean) => void;
  reset: () => void;
}

const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isLoading: true,
      setUser: (user) => set({ user }),
      setToken: (token) => set({ token }),
      setLoading: (isLoading) => set({ isLoading }),
      reset: () => set({ user: null, token: null }),
    }),
    { name: 'auth-storage' }
  )
);

export function useAuth() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, token, isLoading, setUser, setToken, setLoading, reset } = useAuthStore();

  const login = async (credentials: LoginCredentials) => {
    try {
      setLoading(true);
      const { user, token } = await authService.login(credentials);
      setUser(user);
      setToken(token);

      // Redirect to intended destination or dashboard
      const from = (location.state as { from?: Location })?.from?.pathname || '/dashboard';
      navigate(from, { replace: true });
    } catch (error) {
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    reset();
    navigate('/auth/login', { replace: true });
  };

  const checkAuth = async () => {
    if (!token) {
      setLoading(false);
      return;
    }

    try {
      const user = await authService.me();
      setUser(user);
    } catch {
      reset();
    } finally {
      setLoading(false);
    }
  };

  return {
    user,
    token,
    isLoading,
    isAuthenticated: !!user,
    login,
    logout,
    checkAuth,
  };
}
```

#### Data Fetching with TanStack Query

```tsx
// src/hooks/useUsers.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { userService } from '@/services/user.service';
import type { User, CreateUserRequest } from '@/types/user';

interface UseUsersOptions {
  page?: number;
  search?: string;
}

export function useUsers(options: UseUsersOptions = {}) {
  const { page = 1, search = '' } = options;

  return useQuery({
    queryKey: ['users', { page, search }],
    queryFn: () => userService.getAll({ page, search }),
    staleTime: 5 * 60 * 1000, // 5 minutes
    placeholderData: (previousData) => previousData, // Keep previous data while fetching
  });
}

export function useUser(userId: string) {
  return useQuery({
    queryKey: ['users', userId],
    queryFn: () => userService.getById(userId),
    enabled: !!userId,
  });
}

export function useCreateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateUserRequest) => userService.create(data),
    onSuccess: () => {
      // Invalidate users list to refetch
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });
}

export function useUpdateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<User> }) =>
      userService.update(id, data),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      queryClient.invalidateQueries({ queryKey: ['users', id] });
    },
  });
}

export function useDeleteUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => userService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });
}
```

#### API Service

```tsx
// src/services/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - add auth token
api.interceptors.request.use((config) => {
  const token = JSON.parse(localStorage.getItem('auth-storage') || '{}')?.state?.token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor - handle errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('auth-storage');
      window.location.href = '/auth/login';
    }
    return Promise.reject(error);
  }
);

export default api;

// src/services/user.service.ts
import api from './api';
import type { User, CreateUserRequest, PaginatedResponse } from '@/types/user';

interface GetAllParams {
  page?: number;
  search?: string;
}

export const userService = {
  getAll: async (params: GetAllParams): Promise<PaginatedResponse<User>> => {
    const { data } = await api.get('/users', { params });
    return data;
  },

  getById: async (id: string): Promise<User> => {
    const { data } = await api.get(`/users/${id}`);
    return data;
  },

  create: async (userData: CreateUserRequest): Promise<User> => {
    const { data } = await api.post('/users', userData);
    return data;
  },

  update: async (id: string, userData: Partial<User>): Promise<User> => {
    const { data } = await api.put(`/users/${id}`, userData);
    return data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/users/${id}`);
  },
};
```

#### Component Structure

```tsx
// src/components/features/UserCard.tsx
interface UserCardProps {
  user: User;
  onEdit?: (user: User) => void;
  onDelete?: (userId: string) => void;
}

export function UserCard({ user, onEdit, onDelete }: UserCardProps) {
  return (
    <div className="bg-white rounded-lg shadow p-4">
      <div className="flex items-center gap-4">
        <img
          src={user.avatar || '/default-avatar.png'}
          alt={user.name}
          className="w-12 h-12 rounded-full"
        />
        <div className="flex-1">
          <h3 className="font-semibold">{user.name}</h3>
          <p className="text-gray-500 text-sm">{user.email}</p>
        </div>
        <div className="flex gap-2">
          {onEdit && (
            <button
              onClick={() => onEdit(user)}
              className="text-blue-600 hover:underline"
            >
              Edit
            </button>
          )}
          {onDelete && (
            <button
              onClick={() => onDelete(user.id)}
              className="text-red-600 hover:underline"
            >
              Delete
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
```

### Common Gotchas

| Gotcha | Description | Solution |
|--------|-------------|----------|
| **Stale closures** | Event handlers capture old state | Use `useCallback` with deps or functional updates |
| **Infinite useEffect loops** | Object/array deps recreated each render | `useMemo` the dependency or use primitives |
| **Memory leaks** | Subscriptions not cleaned up | Return cleanup function from `useEffect` |
| **Router state lost on refresh** | Using component state for URL data | Use `useSearchParams` for filters/pagination |
| **Protected route flash** | Shows protected content before redirect | Check `isLoading` state before rendering |
| **Missing key prop** | Lists without unique keys | Always use stable, unique `key` values |
| **useNavigate in render** | Calling navigate during render | Move to `useEffect` or event handler |

### Performance Tips

- Use `React.memo()` for expensive pure components
- Use `useMemo`/`useCallback` only when necessary (measure first)
- Virtualize long lists with `@tanstack/react-virtual`
- Code-split routes with `React.lazy()`:
  ```tsx
  const Dashboard = lazy(() => import('@/pages/Dashboard'));
  ```
- Use React DevTools Profiler to identify bottlenecks
- Prefetch data on hover for faster navigation:
  ```tsx
  const queryClient = useQueryClient();
  const prefetchUser = (id: string) => {
    queryClient.prefetchQuery({
      queryKey: ['users', id],
      queryFn: () => userService.getById(id),
    });
  };
  ```

### Testing Approach

```tsx
// Component test with React Testing Library
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import Users from '@/pages/Dashboard/Users';

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false } },
});

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <QueryClientProvider client={queryClient}>
    <BrowserRouter>{children}</BrowserRouter>
  </QueryClientProvider>
);

describe('Users page', () => {
  it('renders user list', async () => {
    render(<Users />, { wrapper });

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });
  });

  it('navigates to user detail on click', async () => {
    const user = userEvent.setup();
    render(<Users />, { wrapper });

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    await user.click(screen.getByText('John Doe'));

    expect(window.location.pathname).toBe('/dashboard/users/1');
  });
});

// Hook test
import { renderHook, waitFor } from '@testing-library/react';
import { useUsers } from '@/hooks/useUsers';

describe('useUsers', () => {
  it('fetches users', async () => {
    const { result } = renderHook(() => useUsers(), { wrapper });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data).toHaveLength(10);
  });
});
```

### Useful Commands

```bash
# Development
npm run dev
pnpm dev

# Build
npm run build
pnpm build

# Preview production build
npm run preview

# Run tests
npm test
pnpm test

# Run tests in watch mode
npm test -- --watch

# Type check
npm run typecheck
tsc --noEmit

# Lint
npm run lint
pnpm lint

# Format
npm run format
prettier --write .
```

### Essential Dependencies (package.json)

```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "@tanstack/react-query": "^5.8.0",
    "axios": "^1.6.0",
    "zustand": "^4.4.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@testing-library/react": "^14.1.0",
    "@testing-library/user-event": "^14.5.0",
    "@vitejs/plugin-react": "^4.2.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "vitest": "^1.0.0"
  }
}
```

---

## TO FILL: Additional Patterns

### Your Custom Patterns

```markdown
<!-- Add any project-specific patterns here -->
```

### Your API Conventions

```markdown
<!-- Document your API conventions -->
```

### Your Component Library

```markdown
<!-- List your UI component library (shadcn, MUI, etc.) -->
```

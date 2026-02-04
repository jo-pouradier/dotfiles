---
name: testing
description: Knowledge base for Spring Boot testing with Mockito, WireMock, and jOOQ
license: MIT
compatibility: opencode
metadata:
  audience: backend-engineers
  workflow: testing
---

# Testing Skill (Spring Boot + jOOQ)

Comprehensive knowledge for testing Spring Boot applications with jOOQ, using Mockito for unit tests and WireMock for external API mocking.

## When to Use

- Writing unit tests for services and repositories
- Adding integration tests with real database (Testcontainers)
- Mocking external APIs with WireMock
- Testing REST controllers with MockMvc
- Setting up test infrastructure for jOOQ

## Testing Pyramid

```
        /\
       /  \      @SpringBootTest + WireMock (Few)
      /----\     - Full integration tests
     /      \    - Real DB with Testcontainers
    /--------\   @WebMvcTest / @DataJpaTest (Some)
   /          \  - Slice tests
  /------------\ - Controller or Repository only
 /              \ @ExtendWith(MockitoExtension.class) (Many)
/________________\ - Unit tests with mocks
                   - Fast, isolated
```

**Ratio guideline:** 70% unit / 20% slice / 10% integration

## Test Structure Pattern

### Arrange-Act-Assert (AAA)

```java
@Test
void findById_WhenUserExists_ReturnsUser() {
    // Arrange
    UUID id = UUID.randomUUID();
    UsersRecord record = createUserRecord(id, "test@example.com");
    when(userRepository.findById(id)).thenReturn(Optional.of(record));
    when(userMapper.toResponse(record)).thenReturn(expectedResponse);

    // Act
    UserResponse result = userService.findById(id);

    // Assert
    assertThat(result.getEmail()).isEqualTo("test@example.com");
    verify(userRepository).findById(id);
}
```

### Test Naming Convention

```java
// Pattern: methodName_StateUnderTest_ExpectedBehavior

void findById_WhenUserExists_ReturnsUser()
void findById_WhenUserNotFound_ThrowsResourceNotFoundException()
void create_WhenEmailAlreadyExists_ThrowsDuplicateException()
void delete_WhenUserExists_DeletesSuccessfully()
```

---

## Unit Testing with Mockito

### Service Layer Unit Tests

```java
@ExtendWith(MockitoExtension.class)
class UserServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserMapper userMapper;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserServiceImpl userService;

    @Test
    void findById_WhenUserExists_ReturnsUser() {
        // Arrange
        UUID id = UUID.randomUUID();
        UsersRecord record = new UsersRecord();
        record.setId(id);
        record.setEmail("test@example.com");
        record.setName("Test User");
        record.setStatus("ACTIVE");

        UserResponse expected = UserResponse.builder()
                .id(id)
                .email("test@example.com")
                .name("Test User")
                .build();

        when(userRepository.findById(id)).thenReturn(Optional.of(record));
        when(userMapper.toResponse(record)).thenReturn(expected);

        // Act
        UserResponse result = userService.findById(id);

        // Assert
        assertThat(result).isEqualTo(expected);
        assertThat(result.getEmail()).isEqualTo("test@example.com");
        verify(userRepository).findById(id);
        verify(userMapper).toResponse(record);
    }

    @Test
    void findById_WhenUserNotFound_ThrowsException() {
        // Arrange
        UUID id = UUID.randomUUID();
        when(userRepository.findById(id)).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> userService.findById(id))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("User")
                .hasMessageContaining(id.toString());

        verify(userRepository).findById(id);
        verifyNoInteractions(userMapper);
    }

    @Test
    void create_WhenValidRequest_ReturnsCreatedUser() {
        // Arrange
        CreateUserRequest request = CreateUserRequest.builder()
                .email("new@example.com")
                .password("Password123")
                .name("New User")
                .build();

        UsersRecord inputRecord = new UsersRecord();
        UsersRecord savedRecord = new UsersRecord();
        savedRecord.setId(UUID.randomUUID());
        savedRecord.setEmail("new@example.com");

        UserResponse expected = UserResponse.builder()
                .id(savedRecord.getId())
                .email("new@example.com")
                .build();

        when(userRepository.existsByEmail("new@example.com")).thenReturn(false);
        when(userMapper.toRecord(request)).thenReturn(inputRecord);
        when(passwordEncoder.encode("Password123")).thenReturn("encoded_password");
        when(userRepository.insert(any(UsersRecord.class))).thenReturn(savedRecord);
        when(userMapper.toResponse(savedRecord)).thenReturn(expected);

        // Act
        UserResponse result = userService.create(request);

        // Assert
        assertThat(result.getEmail()).isEqualTo("new@example.com");
        verify(userRepository).existsByEmail("new@example.com");
        verify(passwordEncoder).encode("Password123");
        verify(userRepository).insert(any(UsersRecord.class));
    }

    @Test
    void create_WhenEmailExists_ThrowsDuplicateException() {
        // Arrange
        CreateUserRequest request = CreateUserRequest.builder()
                .email("existing@example.com")
                .password("Password123")
                .name("User")
                .build();

        when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

        // Act & Assert
        assertThatThrownBy(() -> userService.create(request))
                .isInstanceOf(DuplicateResourceException.class)
                .hasMessageContaining("email");

        verify(userRepository).existsByEmail("existing@example.com");
        verify(userRepository, never()).insert(any());
    }
}
```

### Mockito Annotations Reference

```java
@Mock                    // Creates a mock instance
@Spy                     // Wraps real object, can stub specific methods
@InjectMocks             // Injects mocks into the tested class
@Captor                  // Captures arguments passed to mocks
@MockBean                // Spring Boot: replaces bean in context with mock
```

### Mockito Verification Patterns

```java
// Verify method was called
verify(repository).findById(id);

// Verify method was called exactly N times
verify(repository, times(2)).save(any());

// Verify method was never called
verify(repository, never()).delete(any());

// Verify no more interactions after verified ones
verifyNoMoreInteractions(repository);

// Verify no interactions at all
verifyNoInteractions(mapper);

// Verify call order
InOrder inOrder = inOrder(repository, eventPublisher);
inOrder.verify(repository).save(any());
inOrder.verify(eventPublisher).publish(any());

// Capture arguments
@Captor
ArgumentCaptor<UsersRecord> recordCaptor;

verify(repository).insert(recordCaptor.capture());
UsersRecord captured = recordCaptor.getValue();
assertThat(captured.getEmail()).isEqualTo("test@example.com");
```

### Mockito Stubbing Patterns

```java
// Return value
when(repository.findById(id)).thenReturn(Optional.of(record));

// Return different values on consecutive calls
when(repository.count())
    .thenReturn(0L)
    .thenReturn(1L)
    .thenReturn(2L);

// Throw exception
when(repository.findById(any())).thenThrow(new DataAccessException("DB error") {});

// Answer - dynamic response based on input
when(repository.insert(any(UsersRecord.class))).thenAnswer(invocation -> {
    UsersRecord record = invocation.getArgument(0);
    record.setId(UUID.randomUUID());
    record.setCreatedAt(LocalDateTime.now());
    return record;
});

// Void methods
doNothing().when(repository).deleteById(any());
doThrow(new RuntimeException()).when(repository).deleteById(any());

// Argument matchers
when(repository.findById(any(UUID.class))).thenReturn(Optional.empty());
when(repository.findByEmail(eq("test@example.com"))).thenReturn(Optional.of(record));
when(repository.findByEmail(argThat(email -> email.contains("@")))).thenReturn(Optional.of(record));
```

---

## Controller Testing with MockMvc

### @WebMvcTest (Slice Test)

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private UserService userService;

    @Test
    void getUser_WhenExists_Returns200() throws Exception {
        // Arrange
        UUID id = UUID.randomUUID();
        UserResponse response = UserResponse.builder()
                .id(id)
                .email("test@example.com")
                .name("Test User")
                .status(UserStatus.ACTIVE)
                .build();

        when(userService.findById(id)).thenReturn(response);

        // Act & Assert
        mockMvc.perform(get("/api/v1/users/{id}", id)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id.toString()))
                .andExpect(jsonPath("$.email").value("test@example.com"))
                .andExpect(jsonPath("$.name").value("Test User"));

        verify(userService).findById(id);
    }

    @Test
    void getUser_WhenNotFound_Returns404() throws Exception {
        // Arrange
        UUID id = UUID.randomUUID();
        when(userService.findById(id))
                .thenThrow(new ResourceNotFoundException("User", "id", id));

        // Act & Assert
        mockMvc.perform(get("/api/v1/users/{id}", id)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("RESOURCE_NOT_FOUND"));
    }

    @Test
    void createUser_WithValidRequest_Returns201() throws Exception {
        // Arrange
        CreateUserRequest request = CreateUserRequest.builder()
                .email("new@example.com")
                .password("Password123")
                .name("New User")
                .build();

        UUID createdId = UUID.randomUUID();
        UserResponse response = UserResponse.builder()
                .id(createdId)
                .email("new@example.com")
                .name("New User")
                .build();

        when(userService.create(any(CreateUserRequest.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(header().exists("Location"))
                .andExpect(jsonPath("$.id").value(createdId.toString()))
                .andExpect(jsonPath("$.email").value("new@example.com"));
    }

    @Test
    void createUser_WithInvalidEmail_Returns400() throws Exception {
        // Arrange
        CreateUserRequest request = CreateUserRequest.builder()
                .email("invalid-email")  // Invalid email format
                .password("Password123")
                .name("User")
                .build();

        // Act & Assert
        mockMvc.perform(post("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.details.email").exists());

        verifyNoInteractions(userService);
    }

    @Test
    void createUser_WithWeakPassword_Returns400() throws Exception {
        // Arrange
        CreateUserRequest request = CreateUserRequest.builder()
                .email("test@example.com")
                .password("weak")  // Too short, no uppercase/digit
                .name("User")
                .build();

        // Act & Assert
        mockMvc.perform(post("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.details.password").exists());
    }

    @Test
    void deleteUser_WhenExists_Returns204() throws Exception {
        // Arrange
        UUID id = UUID.randomUUID();
        doNothing().when(userService).delete(id);

        // Act & Assert
        mockMvc.perform(delete("/api/v1/users/{id}", id))
                .andExpect(status().isNoContent());

        verify(userService).delete(id);
    }

    @Test
    void getUsers_WithPagination_Returns200() throws Exception {
        // Arrange
        Page<UserResponse> page = new PageImpl<>(
                List.of(
                        UserResponse.builder().id(UUID.randomUUID()).email("a@test.com").build(),
                        UserResponse.builder().id(UUID.randomUUID()).email("b@test.com").build()
                ),
                PageRequest.of(0, 20),
                2
        );

        when(userService.findAll(0, 20)).thenReturn(page);

        // Act & Assert
        mockMvc.perform(get("/api/v1/users")
                        .param("page", "0")
                        .param("size", "20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.content.length()").value(2))
                .andExpect(jsonPath("$.totalElements").value(2));
    }
}
```

### Testing with Security

```java
@WebMvcTest(UserController.class)
@Import(SecurityConfig.class)
class UserControllerSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthFilter;

    @Test
    @WithMockUser(username = "admin", roles = {"ADMIN"})
    void adminEndpoint_WithAdminRole_Returns200() throws Exception {
        mockMvc.perform(get("/api/v1/admin/users"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(username = "user", roles = {"USER"})
    void adminEndpoint_WithUserRole_Returns403() throws Exception {
        mockMvc.perform(get("/api/v1/admin/users"))
                .andExpect(status().isForbidden());
    }

    @Test
    void protectedEndpoint_WithoutAuth_Returns401() throws Exception {
        mockMvc.perform(get("/api/v1/users"))
                .andExpect(status().isUnauthorized());
    }
}
```

---

## WireMock for External API Mocking

### Setup with JUnit 5

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@WireMockTest(httpPort = 8089)
class ExternalApiIntegrationTest {

    @Autowired
    private PaymentService paymentService;  // Uses external payment API

    @Test
    void processPayment_WhenExternalApiSucceeds_ReturnsSuccess() {
        // Arrange - stub external API
        stubFor(post(urlEqualTo("/api/payments"))
                .withHeader("Content-Type", equalTo("application/json"))
                .withRequestBody(matchingJsonPath("$.amount", equalTo("100.00")))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("""
                            {
                                "transactionId": "txn_123456",
                                "status": "SUCCESS",
                                "amount": 100.00
                            }
                            """)));

        // Act
        PaymentResult result = paymentService.processPayment(new PaymentRequest("100.00", "USD"));

        // Assert
        assertThat(result.getStatus()).isEqualTo("SUCCESS");
        assertThat(result.getTransactionId()).isEqualTo("txn_123456");

        // Verify the external API was called
        verify(postRequestedFor(urlEqualTo("/api/payments"))
                .withHeader("Content-Type", equalTo("application/json")));
    }

    @Test
    void processPayment_WhenExternalApiTimesOut_ThrowsException() {
        // Arrange - simulate timeout
        stubFor(post(urlEqualTo("/api/payments"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withFixedDelay(5000)));  // 5 second delay

        // Act & Assert
        assertThatThrownBy(() -> paymentService.processPayment(new PaymentRequest("100.00", "USD")))
                .isInstanceOf(PaymentTimeoutException.class);
    }

    @Test
    void processPayment_WhenExternalApiReturns500_RetriesAndFails() {
        // Arrange - simulate server error
        stubFor(post(urlEqualTo("/api/payments"))
                .willReturn(aResponse()
                        .withStatus(500)
                        .withBody("""
                            {"error": "Internal Server Error"}
                            """)));

        // Act & Assert
        assertThatThrownBy(() -> paymentService.processPayment(new PaymentRequest("100.00", "USD")))
                .isInstanceOf(PaymentFailedException.class);

        // Verify retries happened
        verify(3, postRequestedFor(urlEqualTo("/api/payments")));
    }

    @Test
    void processPayment_WhenExternalApiReturns400_ThrowsValidationException() {
        // Arrange
        stubFor(post(urlEqualTo("/api/payments"))
                .willReturn(aResponse()
                        .withStatus(400)
                        .withHeader("Content-Type", "application/json")
                        .withBody("""
                            {
                                "error": "INVALID_AMOUNT",
                                "message": "Amount must be positive"
                            }
                            """)));

        // Act & Assert
        assertThatThrownBy(() -> paymentService.processPayment(new PaymentRequest("-10.00", "USD")))
                .isInstanceOf(PaymentValidationException.class)
                .hasMessageContaining("INVALID_AMOUNT");
    }
}
```

### WireMock with State (Scenarios)

```java
@Test
void orderFlow_WithStateTransitions_WorksCorrectly() {
    // First call - order pending
    stubFor(get(urlEqualTo("/api/orders/123"))
            .inScenario("Order Flow")
            .whenScenarioStateIs(Scenario.STARTED)
            .willReturn(aResponse()
                    .withStatus(200)
                    .withBody("""
                        {"id": "123", "status": "PENDING"}
                        """))
            .willSetStateTo("ORDER_PROCESSING"));

    // Second call - order processing
    stubFor(get(urlEqualTo("/api/orders/123"))
            .inScenario("Order Flow")
            .whenScenarioStateIs("ORDER_PROCESSING")
            .willReturn(aResponse()
                    .withStatus(200)
                    .withBody("""
                        {"id": "123", "status": "PROCESSING"}
                        """))
            .willSetStateTo("ORDER_COMPLETED"));

    // Third call - order completed
    stubFor(get(urlEqualTo("/api/orders/123"))
            .inScenario("Order Flow")
            .whenScenarioStateIs("ORDER_COMPLETED")
            .willReturn(aResponse()
                    .withStatus(200)
                    .withBody("""
                        {"id": "123", "status": "COMPLETED"}
                        """)));

    // Act & Assert
    assertThat(orderService.getOrderStatus("123")).isEqualTo("PENDING");
    assertThat(orderService.getOrderStatus("123")).isEqualTo("PROCESSING");
    assertThat(orderService.getOrderStatus("123")).isEqualTo("COMPLETED");
}
```

### WireMock Request Matching

```java
// URL matching
stubFor(get(urlEqualTo("/exact/path")));
stubFor(get(urlPathEqualTo("/path")));  // Ignores query params
stubFor(get(urlMatching("/users/[0-9]+")));
stubFor(get(urlPathMatching("/api/v[0-9]+/users")));

// Query parameters
stubFor(get(urlPathEqualTo("/search"))
        .withQueryParam("q", equalTo("test"))
        .withQueryParam("page", matching("[0-9]+")));

// Headers
stubFor(post(anyUrl())
        .withHeader("Authorization", matching("Bearer .*"))
        .withHeader("Content-Type", equalTo("application/json")));

// Request body (JSON)
stubFor(post(urlEqualTo("/api/users"))
        .withRequestBody(matchingJsonPath("$.email"))
        .withRequestBody(matchingJsonPath("$.name", equalTo("John")))
        .withRequestBody(equalToJson("""
            {"email": "test@example.com", "name": "John"}
            """, true, false)));  // ignoreArrayOrder, ignoreExtraElements
```

### WireMock Configuration

```java
// application-test.yml
payment:
  api:
    base-url: http://localhost:8089  # WireMock port

// Or programmatic configuration
@TestConfiguration
class WireMockConfig {

    @Bean
    public WireMockServer wireMockServer() {
        WireMockServer server = new WireMockServer(WireMockConfiguration.options()
                .port(8089)
                .notifier(new ConsoleNotifier(true)));  // Log requests
        server.start();
        return server;
    }
}
```

---

## Integration Testing with @SpringBootTest + jOOQ

### Full Integration Test with Testcontainers

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@Transactional  // Rollback after each test
class UserIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.flyway.enabled", () -> "true");
    }

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private DSLContext dsl;

    @BeforeEach
    void setUp() {
        // Clean up test data
        dsl.deleteFrom(ORDERS).execute();
        dsl.deleteFrom(USERS).execute();
    }

    @Test
    void createUser_WithValidData_ReturnsCreatedUser() {
        // Arrange
        CreateUserRequest request = CreateUserRequest.builder()
                .email("integration@test.com")
                .password("Password123")
                .name("Integration Test")
                .build();

        // Act
        ResponseEntity<UserResponse> response = restTemplate.postForEntity(
                "/api/v1/users",
                request,
                UserResponse.class
        );

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getHeaders().getLocation()).isNotNull();

        UserResponse body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getId()).isNotNull();
        assertThat(body.getEmail()).isEqualTo("integration@test.com");
        assertThat(body.getName()).isEqualTo("Integration Test");

        // Verify in database using jOOQ
        Optional<UsersRecord> dbRecord = dsl.selectFrom(USERS)
                .where(USERS.EMAIL.eq("integration@test.com"))
                .fetchOptional();

        assertThat(dbRecord).isPresent();
        assertThat(dbRecord.get().getName()).isEqualTo("Integration Test");
        assertThat(dbRecord.get().getPassword()).isNotEqualTo("Password123");  // Should be encoded
    }

    @Test
    void getUser_WithExistingUser_ReturnsUser() {
        // Arrange - insert directly with jOOQ
        UUID userId = UUID.randomUUID();
        dsl.insertInto(USERS)
                .set(USERS.ID, userId)
                .set(USERS.EMAIL, "existing@test.com")
                .set(USERS.PASSWORD, "encoded_password")
                .set(USERS.NAME, "Existing User")
                .set(USERS.STATUS, "ACTIVE")
                .set(USERS.CREATED_AT, LocalDateTime.now())
                .execute();

        // Act
        ResponseEntity<UserResponse> response = restTemplate.getForEntity(
                "/api/v1/users/{id}",
                UserResponse.class,
                userId
        );

        // Assert
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getEmail()).isEqualTo("existing@test.com");
    }

    @Test
    void deleteUser_WithExistingUser_RemovesFromDatabase() {
        // Arrange
        UUID userId = UUID.randomUUID();
        dsl.insertInto(USERS)
                .set(USERS.ID, userId)
                .set(USERS.EMAIL, "todelete@test.com")
                .set(USERS.PASSWORD, "encoded")
                .set(USERS.NAME, "To Delete")
                .set(USERS.STATUS, "ACTIVE")
                .set(USERS.CREATED_AT, LocalDateTime.now())
                .execute();

        // Act
        restTemplate.delete("/api/v1/users/{id}", userId);

        // Assert - verify deleted from database
        boolean exists = dsl.fetchExists(
                dsl.selectFrom(USERS).where(USERS.ID.eq(userId))
        );
        assertThat(exists).isFalse();
    }

    @Test
    void fullUserLifecycle_CreateReadUpdateDelete() {
        // CREATE
        CreateUserRequest createRequest = CreateUserRequest.builder()
                .email("lifecycle@test.com")
                .password("Password123")
                .name("Lifecycle Test")
                .build();

        ResponseEntity<UserResponse> createResponse = restTemplate.postForEntity(
                "/api/v1/users", createRequest, UserResponse.class);

        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        UUID userId = createResponse.getBody().getId();

        // READ
        ResponseEntity<UserResponse> readResponse = restTemplate.getForEntity(
                "/api/v1/users/{id}", UserResponse.class, userId);

        assertThat(readResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(readResponse.getBody().getEmail()).isEqualTo("lifecycle@test.com");

        // UPDATE
        UpdateUserRequest updateRequest = UpdateUserRequest.builder()
                .name("Updated Name")
                .build();

        restTemplate.put("/api/v1/users/{id}", updateRequest, userId);

        // Verify update
        ResponseEntity<UserResponse> afterUpdate = restTemplate.getForEntity(
                "/api/v1/users/{id}", UserResponse.class, userId);
        assertThat(afterUpdate.getBody().getName()).isEqualTo("Updated Name");

        // DELETE
        restTemplate.delete("/api/v1/users/{id}", userId);

        // Verify deleted
        ResponseEntity<UserResponse> afterDelete = restTemplate.getForEntity(
                "/api/v1/users/{id}", UserResponse.class, userId);
        assertThat(afterDelete.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }
}
```

### Repository Integration Test with jOOQ

```java
@SpringBootTest
@Testcontainers
@Transactional
class UserRepositoryIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

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
    void findAll_WithMultipleUsers_ReturnsPaginatedResults() {
        // Arrange
        for (int i = 0; i < 25; i++) {
            dsl.insertInto(USERS)
                    .set(USERS.ID, UUID.randomUUID())
                    .set(USERS.EMAIL, "user" + i + "@test.com")
                    .set(USERS.PASSWORD, "encoded")
                    .set(USERS.NAME, "User " + i)
                    .set(USERS.STATUS, "ACTIVE")
                    .set(USERS.CREATED_AT, LocalDateTime.now().minusMinutes(i))
                    .execute();
        }

        // Act
        List<UsersRecord> page1 = userRepository.findAll(0, 10);
        List<UsersRecord> page2 = userRepository.findAll(1, 10);
        List<UsersRecord> page3 = userRepository.findAll(2, 10);

        // Assert
        assertThat(page1).hasSize(10);
        assertThat(page2).hasSize(10);
        assertThat(page3).hasSize(5);
        assertThat(userRepository.count()).isEqualTo(25);
    }

    @Test
    void insert_WithValidRecord_SetsIdAndTimestamp() {
        // Arrange
        UsersRecord record = new UsersRecord();
        record.setEmail("new@test.com");
        record.setPassword("encoded");
        record.setName("New User");
        record.setStatus("ACTIVE");

        // Act
        UsersRecord inserted = userRepository.insert(record);

        // Assert
        assertThat(inserted.getId()).isNotNull();
        assertThat(inserted.getCreatedAt()).isNotNull();

        // Verify in DB
        Optional<UsersRecord> fromDb = userRepository.findById(inserted.getId());
        assertThat(fromDb).isPresent();
        assertThat(fromDb.get().getEmail()).isEqualTo("new@test.com");
    }

    @Test
    void search_WithCriteria_ReturnsMatchingUsers() {
        // Arrange
        dsl.insertInto(USERS)
                .set(USERS.ID, UUID.randomUUID())
                .set(USERS.EMAIL, "john@example.com")
                .set(USERS.PASSWORD, "encoded")
                .set(USERS.NAME, "John Doe")
                .set(USERS.STATUS, "ACTIVE")
                .set(USERS.CREATED_AT, LocalDateTime.now())
                .execute();

        dsl.insertInto(USERS)
                .set(USERS.ID, UUID.randomUUID())
                .set(USERS.EMAIL, "jane@example.com")
                .set(USERS.PASSWORD, "encoded")
                .set(USERS.NAME, "Jane Doe")
                .set(USERS.STATUS, "INACTIVE")
                .set(USERS.CREATED_AT, LocalDateTime.now())
                .execute();

        // Act & Assert - search by name
        UserSearchCriteria nameCriteria = new UserSearchCriteria();
        nameCriteria.setName("Doe");
        List<UsersRecord> byName = userRepository.search(nameCriteria);
        assertThat(byName).hasSize(2);

        // Act & Assert - search by status
        UserSearchCriteria statusCriteria = new UserSearchCriteria();
        statusCriteria.setStatus(UserStatus.ACTIVE);
        List<UsersRecord> byStatus = userRepository.search(statusCriteria);
        assertThat(byStatus).hasSize(1);
        assertThat(byStatus.get(0).getEmail()).isEqualTo("john@example.com");
    }
}
```

---

## Test Utilities and Helpers

### Test Data Factory

```java
public class TestDataFactory {

    public static UsersRecord createUserRecord() {
        return createUserRecord(UUID.randomUUID(), "test@example.com");
    }

    public static UsersRecord createUserRecord(UUID id, String email) {
        UsersRecord record = new UsersRecord();
        record.setId(id);
        record.setEmail(email);
        record.setPassword("encoded_password");
        record.setName("Test User");
        record.setStatus("ACTIVE");
        record.setCreatedAt(LocalDateTime.now());
        return record;
    }

    public static CreateUserRequest createUserRequest() {
        return CreateUserRequest.builder()
                .email("new@example.com")
                .password("Password123")
                .name("New User")
                .build();
    }

    public static UserResponse createUserResponse(UUID id) {
        return UserResponse.builder()
                .id(id)
                .email("test@example.com")
                .name("Test User")
                .status(UserStatus.ACTIVE)
                .createdAt(LocalDateTime.now())
                .build();
    }
}
```

### Base Integration Test Class

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@Transactional
public abstract class BaseIntegrationTest {

    @Container
    protected static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    protected TestRestTemplate restTemplate;

    @Autowired
    protected DSLContext dsl;

    @BeforeEach
    void cleanDatabase() {
        // Clean in correct order (foreign keys)
        dsl.deleteFrom(ORDERS).execute();
        dsl.deleteFrom(USERS).execute();
    }

    protected UUID insertTestUser(String email) {
        UUID id = UUID.randomUUID();
        dsl.insertInto(USERS)
                .set(USERS.ID, id)
                .set(USERS.EMAIL, email)
                .set(USERS.PASSWORD, "encoded")
                .set(USERS.NAME, "Test User")
                .set(USERS.STATUS, "ACTIVE")
                .set(USERS.CREATED_AT, LocalDateTime.now())
                .execute();
        return id;
    }
}

// Usage
class UserIntegrationTest extends BaseIntegrationTest {

    @Test
    void getUser_ReturnsUser() {
        UUID userId = insertTestUser("test@example.com");

        ResponseEntity<UserResponse> response = restTemplate.getForEntity(
                "/api/v1/users/{id}", UserResponse.class, userId);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }
}
```

---

## Common Gotchas

| Gotcha | Description | Solution |
|--------|-------------|----------|
| **@Transactional not rolling back** | Test changes persist to DB | Ensure test class has `@Transactional` |
| **jOOQ records not attached** | `store()` fails in tests | Use `record.attach(dsl.configuration())` |
| **Testcontainers startup slow** | Each test class starts new container | Use `static` container with `@Container` |
| **MockMvc returns 403** | Security blocks requests | Add `@WithMockUser` or disable security |
| **WireMock port conflict** | Multiple tests use same port | Use `@WireMockTest` with dynamic port |
| **Flaky async tests** | Race conditions | Use `Awaitility.await()` for async assertions |
| **Mock not reset between tests** | State leaks | Use `@BeforeEach` with `reset(mock)` |

---

## Test Commands

```bash
# Run all tests
./mvnw test
./gradlew test

# Run specific test class
./mvnw test -Dtest=UserServiceImplTest
./gradlew test --tests UserServiceImplTest

# Run specific test method
./mvnw test -Dtest=UserServiceImplTest#findById_WhenUserExists_ReturnsUser

# Run with coverage (JaCoCo)
./mvnw test jacoco:report
./gradlew test jacocoTestReport

# Run integration tests only
./mvnw test -Dgroups=integration
./gradlew test -PincludeTags=integration

# Skip tests
./mvnw package -DskipTests
./gradlew build -x test
```

---

## Essential Test Dependencies (pom.xml)

```xml
<dependencies>
    <!-- Spring Boot Test -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>

    <!-- Testcontainers -->
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>testcontainers</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>postgresql</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>

    <!-- WireMock -->
    <dependency>
        <groupId>org.wiremock</groupId>
        <artifactId>wiremock-standalone</artifactId>
        <version>3.3.1</version>
        <scope>test</scope>
    </dependency>

    <!-- Security testing -->
    <dependency>
        <groupId>org.springframework.security</groupId>
        <artifactId>spring-security-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

---

## TO FILL: Your Test Configuration

### Coverage Thresholds

```yaml
# Define your minimum coverage requirements:
#
# global: 80%
# critical_modules:
#   - auth/*: 95%
#   - payments/*: 95%
#   - api/*: 85%
```

### Custom Test Categories

```java
// Define custom tags for test filtering
// @Tag("integration")
// @Tag("slow")
// @Tag("external")
```

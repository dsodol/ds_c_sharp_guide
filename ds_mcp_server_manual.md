# DS.McpServer - Design Specification

**Version:** 1.0
**Date:** 2025-12-17
**Repository:** https://github.com/dsodol/ds_mcp_server.git
**Location:** C:/Users/dsodo/project/built_with_ai/ds_mcp_server/

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Repository Structure](#3-repository-structure)
4. [Components](#4-components)
5. [HTTPS Support](#5-https-support)
6. [OAuth 2.0 Implementation](#6-oauth-20-implementation)
7. [Tool Registration API](#7-tool-registration-api)
8. [Logging System](#8-logging-system)
9. [Configuration](#9-configuration)
10. [Error Handling](#10-error-handling)
11. [Demo Application](#11-demo-application)
12. [API Reference](#12-api-reference)
13. [Security Considerations](#13-security-considerations)
14. [Development Roadmap](#14-development-roadmap)
15. [SSE Implementation Requirements](#15-sse-implementation-requirements)
16. [SSE Transport Protocol](#16-sse-transport-protocol)

---

## 1. Overview

### 1.1 Purpose

DS.McpServer is a highly configurable, production-ready implementation of the Model Context Protocol (MCP) server specification. It provides:

- **Target Framework:** .NET 10
- **Generic MCP server library** - Reusable across projects
- **OAuth 2.0 authorization server** - Personal use, auto-approve flow
- **HTTPS support** - Both PEM and PFX certificate formats
- **Flexible tool registration** - Delegate and interface-based APIs
- **Comprehensive logging** - Runtime-configurable with detailed telemetry
- **Demo application** - Console app with example tools

### 1.2 Use Case

Primary use case: **Personal MCP server for Claude.ai integration**

- Single user (owner)
- Remote access via HTTPS
- OAuth-secured (Claude.ai requirement)
- Maximum configurability
- Detailed logging for debugging

### 1.3 Design Philosophy

**Highly Configurable:**
- Every aspect controllable by client application
- Sensible defaults for common scenarios
- No hardcoded behavior

**Production Ready:**
- Follows MCP specification exactly
- Implements security best practices
- Comprehensive error handling
- Performance optimized

**Developer Friendly:**
- Simple API for common cases
- Flexible API for advanced scenarios
- Well-documented
- Easy to extend

---

## 2. Architecture

### 2.1 Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     Claude.ai                           │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ 1. OAuth Authorization Request
                 ▼
┌─────────────────────────────────────────────────────────┐
│            DS.McpServer.OAuth                           │
│         (Authorization Server)                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │ /authorize  → Auto-approve (single user)        │  │
│  │ /token      → Issue access token                │  │
│  │ /.well-known/oauth-protected-resource           │  │
│  │               → Metadata                         │  │
│  └─────────────────────────────────────────────────┘  │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ 2. Access Token
                 ▼
┌─────────────────────────────────────────────────────────┐
│            DS.McpServer (Library)                       │
│            (Resource Server)                            │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │ HTTP/HTTPS Server (Kestrel)                     │  │
│  ├─────────────────────────────────────────────────┤  │
│  │ Token Validation Middleware                     │  │
│  ├─────────────────────────────────────────────────┤  │
│  │ Logging Middleware (detailed)                   │  │
│  ├─────────────────────────────────────────────────┤  │
│  │ CORS Middleware                                 │  │
│  ├─────────────────────────────────────────────────┤  │
│  │ JSON-RPC Handler                                │  │
│  ├─────────────────────────────────────────────────┤  │
│  │ Tool Registry & Dispatcher                      │  │
│  └─────────────────────────────────────────────────┘  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │ Registered Tools (client-provided)              │  │
│  │  - echo_tool                                    │  │
│  │  - calculator_tool                              │  │
│  │  - timestamp_tool                               │  │
│  │  - ... (custom tools)                           │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Separation of Concerns

**DS.McpServer (Library):**
- Generic MCP protocol implementation
- HTTP/HTTPS server
- Tool registry and dispatch
- Token validation (not issuance)
- Logging infrastructure
- No business logic
- No specific tools

**DS.McpServer.OAuth (Library):**
- OAuth 2.0 authorization server
- Token issuance and management
- PKCE support
- Protected resource metadata
- Auto-approve flow for single user

**DS.McpServer.Demo (Application):**
- Example console application
- Sample tool implementations
- Configuration examples
- Integration demonstration

### 2.3 Design Patterns

**Dependency Injection:**
- ILogger for logging
- IToolRegistry for tool management
- Configuration via options pattern

**Middleware Pipeline:**
- Token validation → Logging → CORS → JSON-RPC

**Strategy Pattern:**
- Tool registration (delegate vs interface)
- Certificate loading (PEM vs PFX)
- Error handling (result vs JSON-RPC error)

**Observer Pattern:**
- Runtime log level changes
- Server lifecycle events

---

## 3. Repository Structure

```
ds_mcp_server/
├── .git/
├── .gitignore
├── README.md
├── LICENSE
├── ARCHITECTURE.md
│
├── src/
│   ├── DS.McpServer/                    # Core MCP server library
│   │   ├── DS.McpServer.csproj
│   │   │
│   │   ├── GenericMcpServer.cs          # Main server class
│   │   ├── IToolRegistry.cs             # Tool registration interface
│   │   ├── ToolRegistry.cs              # Tool registry implementation
│   │   │
│   │   ├── Models/
│   │   │   ├── JsonRpc.cs               # JSON-RPC 2.0 models
│   │   │   ├── McpModels.cs             # MCP protocol models
│   │   │   ├── ToolDefinition.cs        # Tool schema models
│   │   │   └── McpServerOptions.cs      # Configuration options
│   │   │
│   │   ├── Middleware/
│   │   │   ├── TokenValidationMiddleware.cs
│   │   │   ├── LoggingMiddleware.cs
│   │   │   └── CorsMiddleware.cs
│   │   │
│   │   ├── Handlers/
│   │   │   ├── JsonRpcHandler.cs        # JSON-RPC request/response
│   │   │   ├── ToolDispatcher.cs        # Tool execution
│   │   │   └── SseHandler.cs            # Server-sent events
│   │   │
│   │   ├── Certificates/
│   │   │   ├── ICertificateLoader.cs
│   │   │   ├── PemCertificateLoader.cs
│   │   │   └── PfxCertificateLoader.cs
│   │   │
│   │   └── Utilities/
│   │       ├── ArgumentExtractor.cs     # JSON argument parsing
│   │       └── LogLevelManager.cs       # Runtime log level control
│   │
│   ├── DS.McpServer.OAuth/              # OAuth authorization server
│   │   ├── DS.McpServer.OAuth.csproj
│   │   │
│   │   ├── OAuthServer.cs               # Main OAuth server class
│   │   ├── TokenManager.cs              # Token issuance/validation
│   │   ├── PkceValidator.cs             # PKCE code challenge validation
│   │   │
│   │   ├── Models/
│   │   │   ├── AuthorizationRequest.cs
│   │   │   ├── TokenRequest.cs
│   │   │   ├── TokenResponse.cs
│   │   │   ├── OAuthServerOptions.cs
│   │   │   └── ProtectedResourceMetadata.cs
│   │   │
│   │   ├── Endpoints/
│   │   │   ├── AuthorizeEndpoint.cs     # /authorize (auto-approve)
│   │   │   ├── TokenEndpoint.cs         # /token
│   │   │   └── MetadataEndpoint.cs      # /.well-known/...
│   │   │
│   │   └── Storage/
│   │       ├── ITokenStore.cs
│   │       └── InMemoryTokenStore.cs    # Simple in-memory storage
│   │
│   └── DS.McpServer.Demo/               # Demo console application
│       ├── DS.McpServer.Demo.csproj
│       ├── Program.cs                   # Main entry point
│       │
│       ├── Tools/                       # Example tool implementations
│       │   ├── EchoTool.cs
│       │   └── CalculatorTool.cs
│       │
│       └── appsettings.json             # Demo configuration
│
├── tests/                               # Unit tests (future)
│   ├── DS.McpServer.Tests/
│   └── DS.McpServer.OAuth.Tests/
│
├── docs/                                # Additional documentation
│   ├── GETTING_STARTED.md
│   ├── OAUTH_SETUP.md
│   └── CERTIFICATE_GUIDE.md
│
└── DS.McpServer.sln                     # Solution file
```

### 3.1 Project References

```
DS.McpServer.Demo
  ├─► DS.McpServer
  └─► DS.McpServer.OAuth

DS.McpServer.OAuth
  └─► DS.McpServer (for models only)

DS.McpServer
  └─► (no dependencies - standalone library)
```

---

## 4. Components

### 4.1 DS.McpServer (Core Library)

**Responsibilities:**
- HTTP/HTTPS server lifecycle
- JSON-RPC 2.0 protocol handling
- Tool registration and dispatch
- Bearer token validation
- Server-sent events endpoint
- CORS handling
- Request/response logging
- Error handling

**Does NOT:**
- Issue tokens (OAuth server's job)
- Contain business logic
- Implement specific tools
- Store user data

### 4.2 DS.McpServer.OAuth

**Responsibilities:**
- OAuth 2.0 authorization server
- Token issuance and management
- PKCE validation
- Protected resource metadata
- Auto-approve flow implementation
- Token storage (in-memory)

**Characteristics:**
- Single-user focused
- No user database
- No login page (auto-approve)
- Short-lived tokens (configurable)
- Refresh token support (optional)

### 4.3 DS.McpServer.Demo

**Responsibilities:**
- Demonstrate library usage
- Provide example tools
- Show OAuth integration
- Detailed logging examples
- Configuration templates

**Features:**
- Console application
- Verbose logging (all details)
- Sample tools (echo, calculator, file operations)
- Clear setup instructions
- Run both MCP and OAuth servers

---

## 5. HTTPS Support

### 5.1 Certificate Format Support

**Supported Formats:**

1. **PEM Files** (Linux/Let's Encrypt standard)
   - `cert.pem` - Certificate
   - `privkey.pem` - Private key
   - `chain.pem` - Certificate chain (optional)

2. **PFX/P12 Files** (Windows standard)
   - Single file containing certificate + private key
   - Password protected

3. **Auto-detection**
   - Library detects format from file extension
   - `.pem`, `.crt`, `.key` → PEM loader
   - `.pfx`, `.p12` → PFX loader

### 5.2 Certificate Configuration

**PEM Configuration:**
```csharp
var options = new McpServerOptions
{
    Port = 443,
    UseHttps = true,
    CertificateType = CertificateType.Pem,
    PemCertificateFile = "/path/to/cert.pem",
    PemPrivateKeyFile = "/path/to/privkey.pem",
    PemChainFile = "/path/to/chain.pem"  // Optional
};
```

**PFX Configuration:**
```csharp
var options = new McpServerOptions
{
    Port = 443,
    UseHttps = true,
    CertificateType = CertificateType.Pfx,
    PfxFile = "/path/to/server.pfx",
    PfxPassword = "password"
};
```

**Auto-detect:**
```csharp
var options = new McpServerOptions
{
    Port = 443,
    UseHttps = true,
    CertificateFile = "/path/to/cert.pem",  // Auto-detects PEM
    // Or
    CertificateFile = "/path/to/server.pfx",  // Auto-detects PFX
    CertificatePassword = "password"  // Used if PFX
};
```

### 5.3 Certificate Loading

**Interface:**
```csharp
public interface ICertificateLoader
{
    X509Certificate2 Load(McpServerOptions options);
}
```

**Implementations:**

**PemCertificateLoader:**
- Reads PEM-encoded certificate and private key
- Combines into X509Certificate2
- Optionally loads chain
- Validates key matches certificate

**PfxCertificateLoader:**
- Loads PFX file
- Uses password if provided
- Extracts certificate with private key

### 5.4 HTTPS Optional

**HTTPS is optional but recommended:**

- For local/development: HTTP is acceptable
- For remote access (Claude.ai): HTTPS strongly recommended
- Claude.ai can work with HTTP for testing, but insecure

**If using HTTPS, production certificates required:**

- Valid CA-signed certificate (Let's Encrypt, commercial CA, etc.)
- No self-signed certificates (Claude.ai will reject)
- Certificate must match server hostname
- Not expired
- Complete certificate chain

---

## 6. OAuth 2.0 Implementation

### 6.1 OAuth Flow Overview

```
┌─────────┐                                  ┌──────────────────┐
│         │  1. /authorize?client_id=...     │  OAuth Server    │
│ Claude  │─────────────────────────────────>│  (Auto-approve)  │
│  .ai    │                                  │                  │
│         │  2. 302 Redirect with code       │  Issues:         │
│         │<─────────────────────────────────│  - auth code     │
│         │     Location: callback?code=...  │                  │
│         │                                  └──────────────────┘
│         │
│         │  3. POST /token
│         │     code=...&code_verifier=...   ┌──────────────────┐
│         │─────────────────────────────────>│  OAuth Server    │
│         │                                  │  (Token Issue)   │
│         │  4. {"access_token": "..."}      │                  │
│         │<─────────────────────────────────│                  │
│         │                                  └──────────────────┘
│         │
│         │  5. POST /messages
│         │     Authorization: Bearer token  ┌──────────────────┐
│         │─────────────────────────────────>│  MCP Server      │
│         │                                  │  (Validate token)│
│         │  6. MCP Response                 │                  │
│         │<─────────────────────────────────│                  │
└─────────┘                                  └──────────────────┘
```

### 6.2 OAuth Server Endpoints

**1. Authorization Endpoint (`/authorize`)**

**Request Parameters:**
- `client_id` - Client identifier (URL or UUID from Claude.ai)
- `redirect_uri` - Callback URL (must match registered)
- `response_type` - Must be "code"
- `scope` - Requested scopes (space-separated)
- `resource` - Target MCP server URL
- `code_challenge` - PKCE challenge (required)
- `code_challenge_method` - Must be "S256"
- `state` - CSRF protection (recommended)

**Behavior (Validate client & Auto-approve):**
```csharp
// 1. Validate client_id against registered clients
if (!IsValidClientId(clientId))
{
    return BadRequest("invalid_client");
}

// 2. Auto-approve (no user interaction)
var authCode = GenerateAuthorizationCode();
StoreAuthCode(authCode, codeChallenge, redirectUri, scope, resource, clientId);
return Redirect($"{redirectUri}?code={authCode}&state={state}");
```

**Response:**
```
HTTP/1.1 302 Found
Location: https://claude.ai/api/mcp/auth_callback?code=AUTH_CODE&state=STATE
```

**2. Token Endpoint (`/token`)**

**Request Parameters (POST form-encoded):**
- `grant_type` - Must be "authorization_code"
- `code` - Authorization code from /authorize
- `client_id` - Client identifier (from Claude.ai)
- `client_secret` - Client secret (from Claude.ai config)
- `redirect_uri` - Must match authorization request
- `code_verifier` - PKCE verifier (required)
- `resource` - Target MCP server URL (optional)

**Validation:**
1. **Verify client credentials** (client_id + client_secret match registered client)
2. Verify authorization code exists and not expired
3. Verify client_id matches the one from authorization request
4. Verify PKCE: `SHA256(code_verifier) == code_challenge`
5. Verify redirect_uri matches
6. Verify code not already used (single-use)

**Response (Success):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "mcp:read mcp:write",
  "resource": "https://mcp.example.com"
}
```

**Response (Error):**
```json
{
  "error": "invalid_grant",
  "error_description": "Authorization code expired"
}
```

**3. Protected Resource Metadata (`/.well-known/oauth-protected-resource`)**

**Response:**
```json
{
  "resource": "https://mcp.example.com",
  "authorization_servers": [
    "https://oauth.example.com"
  ],
  "scopes_supported": [
    "mcp:read",
    "mcp:write",
    "mcp:tools"
  ],
  "bearer_methods_supported": [
    "header"
  ],
  "resource_documentation": "https://docs.example.com/mcp"
}
```

**Also returned in 401 response:**
```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer resource_metadata="https://mcp.example.com/.well-known/oauth-protected-resource",
                         scope="mcp:read mcp:write"
```

### 6.3 Token Format

**JWT (JSON Web Token):**

**Header:**
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Payload:**
```json
{
  "iss": "https://oauth.example.com",      // Issuer
  "sub": "user@example.com",               // Subject (user ID)
  "aud": "https://mcp.example.com",        // Audience (resource server)
  "exp": 1735689600,                       // Expiration (Unix timestamp)
  "iat": 1735686000,                       // Issued at
  "jti": "unique-token-id",                // Token ID
  "scope": "mcp:read mcp:write",           // Granted scopes
  "client_id": "https://app.example.com"   // Client identifier
}
```

**Signature:**
- HMAC-SHA256 with secret key
- Key configurable in OAuthServerOptions

### 6.4 PKCE Implementation

**Authorization Request:**
```csharp
// Client generates random code_verifier (43-128 chars)
var codeVerifier = GenerateRandomString(128);

// Client creates challenge
var codeChallenge = Base64UrlEncode(SHA256(codeVerifier));

// Client sends challenge
GET /authorize?code_challenge={codeChallenge}&code_challenge_method=S256&...
```

**Token Request:**
```csharp
// Client sends verifier
POST /token
  code_verifier={codeVerifier}&...

// Server validates
var expectedChallenge = Base64UrlEncode(SHA256(codeVerifier));
if (expectedChallenge != storedChallenge) {
    return Error("invalid_grant");
}
```

### 6.5 OAuth Server Configuration

**Note:** OAuth is integrated into `GenericMcpServer` and runs on the same port. The OAuth server auto-computes its URLs from `McpServerOptions.GetServerUrl()`.

```csharp
public class OAuthServerOptions
{
    // URL computed automatically from McpServerOptions.GetServerUrl()
    // No manual URL configuration needed!

    // Token settings
    public TimeSpan AccessTokenLifetime { get; set; } = TimeSpan.FromHours(1);
    public string SigningKey { get; set; } = "this-is-a-demo-signing-key-32chars!";

    // Authorization code settings
    public TimeSpan AuthorizationCodeLifetime { get; set; } = TimeSpan.FromMinutes(5);

    // Registered clients (client_id -> client_secret mapping)
    public Dictionary<string, string> RegisteredClients { get; set; } = new()
    {
        ["ds"] = "sdfhgdgfhdf"  // Default demo credentials
    };

    // Allowed redirect URIs (for security)
    public List<string> AllowedRedirectUris { get; set; } = new()
    {
        "https://claude.ai/api/mcp/auth_callback",
        "https://claude.com/api/mcp/auth_callback"
    };

    // Allowed scopes
    public List<string> SupportedScopes { get; set; } = new()
    {
        "mcp:read",
        "mcp:write",
        "mcp:tools"
    };

    // Auto-approve (no user interaction)
    public bool AutoApprove { get; set; } = true;

    // Default scopes to grant if auto-approve
    public List<string> DefaultScopes { get; set; } = new()
    {
        "mcp:read",
        "mcp:write",
        "mcp:tools"
    };

    // Computed URL method (uses parent McpServerOptions)
    public string GetServerUrl() => _parentOptions.GetServerUrl();
}
```

**Example Configuration:**

OAuth is configured through `McpServerOptions` - no separate `OAuthServerOptions` configuration needed:

```csharp
// Zero configuration - OAuth works out of the box
var options = new McpServerOptions();

// Custom client credentials
var options = new McpServerOptions
{
    RegisteredClients = new Dictionary<string, string>
    {
        ["my-client-id"] = "my-client-secret"
    }
};
```

### 6.6 Token Storage

**Interface:**
```csharp
public interface ITokenStore
{
    // Authorization codes
    Task StoreAuthorizationCodeAsync(AuthorizationCode code);
    Task<AuthorizationCode?> GetAuthorizationCodeAsync(string code);
    Task RevokeAuthorizationCodeAsync(string code);

    // Access tokens
    Task StoreAccessTokenAsync(AccessToken token);
    Task<AccessToken?> GetAccessTokenAsync(string token);
    Task RevokeAccessTokenAsync(string token);

    // Cleanup
    Task RemoveExpiredTokensAsync();
}
```

**In-Memory Implementation:**
```csharp
public class InMemoryTokenStore : ITokenStore
{
    private readonly ConcurrentDictionary<string, AuthorizationCode> _authCodes = new();
    private readonly ConcurrentDictionary<string, AccessToken> _accessTokens = new();

    // Periodic cleanup every 5 minutes
    private readonly Timer _cleanupTimer;
}
```

**For production:** Could implement database-backed store (SQL, Redis, etc.)

---

## 7. Tool Registration API

### 7.1 Registration Styles

**Style 1: Delegate-based (Simple)**

```csharp
server.RegisterTool(
    name: "echo",
    description: "Echoes the input message back",
    schema: new ToolSchema
    {
        Type = "object",
        Properties = new Dictionary<string, PropertySchema>
        {
            ["message"] = new PropertySchema
            {
                Type = "string",
                Description = "The message to echo"
            }
        },
        Required = new[] { "message" }
    },
    handler: async (args) =>
    {
        var message = ArgumentExtractor.GetString(args, "message");
        return new { echo = message, timestamp = DateTime.UtcNow };
    }
);
```

**Style 2: Interface-based (Structured)**

```csharp
public class EchoTool : ITool
{
    public string Name => "echo";

    public string Description => "Echoes the input message back";

    public ToolSchema Schema => new ToolSchema
    {
        Type = "object",
        Properties = new Dictionary<string, PropertySchema>
        {
            ["message"] = new PropertySchema
            {
                Type = "string",
                Description = "The message to echo"
            }
        },
        Required = new[] { "message" }
    };

    public async Task<object> ExecuteAsync(JsonElement? arguments)
    {
        var message = ArgumentExtractor.GetString(arguments, "message");
        return new { echo = message, timestamp = DateTime.UtcNow };
    }
}

// Register
server.RegisterTool(new EchoTool());
```

**Style 3: Attribute-based (Future)**

```csharp
[McpTool("echo", "Echoes the input message back")]
public class EchoTool
{
    [McpParameter("message", "The message to echo", Required = true)]
    public async Task<object> ExecuteAsync(string message)
    {
        return new { echo = message, timestamp = DateTime.UtcNow };
    }
}

// Auto-discovery
server.RegisterToolsFromAssembly(Assembly.GetExecutingAssembly());
```

### 7.2 Tool Registry Interface

```csharp
public interface IToolRegistry
{
    // Delegate registration
    void RegisterTool(
        string name,
        string description,
        ToolSchema schema,
        Func<JsonElement?, Task<object>> handler
    );

    // Interface registration
    void RegisterTool(ITool tool);

    // Bulk registration
    void RegisterTools(IEnumerable<ITool> tools);

    // Unregister
    void UnregisterTool(string name);

    // Query
    bool HasTool(string name);
    IEnumerable<ToolInfo> GetAllTools();
    ToolInfo? GetTool(string name);

    // Dispatch
    Task<object> ExecuteToolAsync(string name, JsonElement? arguments);
}
```

### 7.3 Tool Schema Models

```csharp
public class ToolSchema
{
    public string Type { get; set; } = "object";
    public Dictionary<string, PropertySchema> Properties { get; set; } = new();
    public string[] Required { get; set; } = Array.Empty<string>();
}

public class PropertySchema
{
    public string Type { get; set; } = "string";  // string, number, boolean, array, object
    public string Description { get; set; } = "";
    public string[]? Enum { get; set; }  // For enumerated values
    public object? Default { get; set; }
    public PropertySchema? Items { get; set; }  // For array types
}

public class ToolInfo
{
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public ToolSchema InputSchema { get; set; } = new();
}
```

### 7.4 Argument Extraction Utilities

```csharp
public static class ArgumentExtractor
{
    // Required parameters
    public static string GetString(JsonElement? args, string name);
    public static int GetInt(JsonElement? args, string name);
    public static bool GetBool(JsonElement? args, string name);
    public static double GetDouble(JsonElement? args, string name);
    public static T GetObject<T>(JsonElement? args, string name);

    // Optional parameters
    public static string? GetStringOrNull(JsonElement? args, string name);
    public static int? GetIntOrNull(JsonElement? args, string name);
    public static bool? GetBoolOrNull(JsonElement? args, string name);
    public static double? GetDoubleOrNull(JsonElement? args, string name);

    // With defaults
    public static string GetStringOrDefault(JsonElement? args, string name, string defaultValue);
    public static int GetIntOrDefault(JsonElement? args, string name, int defaultValue);
    public static bool GetBoolOrDefault(JsonElement? args, string name, bool defaultValue);
}
```

---

## 8. Logging System

### 8.1 Logging Framework

**Uses:** Microsoft.Extensions.Logging (ILogger)

**Benefits:**
- Standard .NET logging
- Multiple providers (console, file, etc.)
- Structured logging
- Log levels (Trace, Debug, Information, Warning, Error, Critical)
- Runtime configuration

### 8.2 Log Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| **Trace** | Detailed diagnostic info | Request headers, JSON bodies |
| **Debug** | Internal state, flow | Tool execution start/end |
| **Information** | General flow | Server started, request received |
| **Warning** | Recoverable issues | Invalid token, tool not found |
| **Error** | Errors requiring attention | Tool threw exception |
| **Critical** | Fatal errors | Server crash, unable to bind port |

### 8.3 Logging Configuration

**Detailed Logging (Demo App):**
```csharp
var loggerFactory = LoggerFactory.Create(builder =>
{
    builder
        .AddConsole()
        .SetMinimumLevel(LogLevel.Trace);
});

var options = new McpServerOptions
{
    Port = 43875,
    LogHeaders = true,           // Log all HTTP headers
    LogClientInfo = true,         // Log IP, port, connection ID
    LogRequestBody = true,        // Log incoming JSON
    LogResponseBody = true,       // Log outgoing JSON
    LogToolExecution = true       // Log tool calls
};

var server = new GenericMcpServer(options, loggerFactory);
```

**Production Logging:**
```csharp
var loggerFactory = LoggerFactory.Create(builder =>
{
    builder
        .AddConsole()
        .AddFile("logs/mcp-{Date}.log")
        .SetMinimumLevel(LogLevel.Warning);  // Only warnings and errors
});

var options = new McpServerOptions
{
    Port = 443,
    LogHeaders = false,
    LogClientInfo = true,
    LogRequestBody = false,
    LogResponseBody = false,
    LogToolExecution = true
};
```

### 8.4 Runtime Log Level Control

**API:**
```csharp
public class GenericMcpServer
{
    public void SetLogLevel(LogLevel level);
    public LogLevel GetLogLevel();
}
```

**Usage:**
```csharp
// Start with detailed logging
server.Start();

// Reduce noise after debugging
server.SetLogLevel(LogLevel.Information);

// Turn back up when issue occurs
server.SetLogLevel(LogLevel.Trace);
```

**Demo Console Commands:**
```
Commands:
  trace     - Set log level to Trace (most detailed)
  debug     - Set log level to Debug
  info      - Set log level to Information
  warning   - Set log level to Warning
  error     - Set log level to Error (least detailed)
  status    - Show current log level
  quit      - Stop server and exit
```

### 8.5 Logged Information

**Request Logging (Trace):**
```
[2025-12-17 15:23:45.123] [TRACE] [conn-a1b2c3] 192.168.1.100:54321 -> POST /messages
[2025-12-17 15:23:45.124] [TRACE] Headers:
  Content-Type: application/json
  Authorization: Bearer eyJhbG...
  User-Agent: Claude Desktop/1.0
  Content-Length: 234
[2025-12-17 15:23:45.125] [TRACE] Request body:
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "echo",
    "arguments": {
      "message": "Hello, World!"
    }
  }
}
```

**Tool Execution (Debug):**
```
[2025-12-17 15:23:45.126] [DEBUG] Calling tool: echo
[2025-12-17 15:23:45.127] [DEBUG] Tool 'echo' completed in 1.2ms
```

**Response Logging (Trace):**
```
[2025-12-17 15:23:45.128] [TRACE] Response body:
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"echo\":\"Hello, World!\",\"timestamp\":\"2025-12-17T15:23:45Z\"}"
      }
    ],
    "isError": false
  }
}
[2025-12-17 15:23:45.129] [TRACE] [conn-a1b2c3] <- 200 OK (6.2ms)
```

**Error Logging (Error):**
```
[2025-12-17 15:24:10.456] [ERROR] [conn-xyz789] Tool 'file_read' threw exception
  Message: File not found: /path/to/missing.txt
  Type: System.IO.FileNotFoundException
  Stack trace:
    at FileReadTool.ExecuteAsync(...) in FileReadTool.cs:line 42
    at ToolDispatcher.ExecuteAsync(...) in ToolDispatcher.cs:line 89
```

---

## 9. Configuration

### 9.1 McpServerOptions

**Zero Configuration:** The default constructor works out of the box with OAuth enabled for Claude.ai integration.

```csharp
public class McpServerOptions
{
    // ===== Network =====
    public int Port { get; set; } = 43875;
    public string BindAddress { get; set; } = "127.0.0.1";  // localhost by default

    // ===== HTTPS =====
    public bool UseHttps { get; set; } = false;

    // Option 1: Auto-detect from file extension
    public string? CertificateFile { get; set; }
    public string? CertificatePassword { get; set; }  // For PFX

    // Option 2: Explicit PEM
    public CertificateType CertificateType { get; set; } = CertificateType.AutoDetect;
    public string? PemCertificateFile { get; set; }
    public string? PemPrivateKeyFile { get; set; }
    public string? PemChainFile { get; set; }

    // Option 3: Explicit PFX
    public string? PfxFile { get; set; }
    public string? PfxPassword { get; set; }

    // ===== OAuth (enabled by default for Claude.ai) =====
    public bool RequireAuthentication { get; set; } = true;  // OAuth ON by default
    public string JwtSigningKey { get; set; } = "this-is-a-demo-signing-key-32chars!";
    public bool ValidateClientCredentials { get; set; } = true;
    public Dictionary<string, string> RegisteredClients { get; set; } = new()
    {
        ["ds"] = "sdfhgdgfhdf"  // Default demo credentials
    };

    // Claude.ai redirect URIs (pre-configured)
    public List<string> AllowedRedirectUris { get; set; } = new()
    {
        "https://claude.ai/api/mcp/auth_callback",
        "https://claude.com/api/mcp/auth_callback"
    };

    // ===== CORS =====
    public CorsOptions Cors { get; set; } = CorsOptions.Default;

    // ===== Server Info (MCP metadata) =====
    public string ServerName { get; set; } = "GenericMcpServer";
    public string ServerVersion { get; set; } = "1.0.0";

    // ===== Logging =====
    public bool LogHeaders { get; set; } = false;
    public bool LogClientInfo { get; set; } = true;
    public bool LogRequestBody { get; set; } = false;
    public bool LogResponseBody { get; set; } = false;
    public bool LogToolExecution { get; set; } = true;

    // ===== Error Handling =====
    public ToolErrorHandling ToolErrorHandling { get; set; } = ToolErrorHandling.ReturnAsResult;

    // ===== Server Lifecycle =====
    public TimeSpan ShutdownTimeout { get; set; } = TimeSpan.Zero;  // Instant shutdown

    // ===== Computed URL =====
    public string GetServerUrl()
    {
        var scheme = UseHttps ? "https" : "http";
        return $"{scheme}://{BindAddress}:{Port}";
    }
}

public enum CertificateType
{
    AutoDetect,
    Pem,
    Pfx
}

public enum ToolErrorHandling
{
    ReturnAsResult,      // Default: { isError: true, content: [...] }
    ThrowJsonRpcError    // Return JSON-RPC error object
}

public class CorsOptions
{
    public string[] AllowedOrigins { get; set; } = { "*" };
    public string[] AllowedMethods { get; set; } = { "GET", "POST", "OPTIONS" };
    public string[] AllowedHeaders { get; set; } = { "Content-Type", "Authorization" };

    public static CorsOptions Default => new CorsOptions();
}
```

### 9.2 Example Configurations

**Zero Configuration (OAuth enabled, default port):**
```csharp
// Just works - OAuth enabled, port 43875, default credentials
var server = new GenericMcpServer(new McpServerOptions());
```

**Disable OAuth (HTTP, no auth):**
```csharp
var server = new GenericMcpServer(new McpServerOptions
{
    RequireAuthentication = false  // OAuth OFF
});
```

**HTTPS with PEM (Let's Encrypt):**
```csharp
var server = new GenericMcpServer(new McpServerOptions
{
    UseHttps = true,
    PemCertificateFile = "/etc/letsencrypt/live/example.com/cert.pem",
    PemPrivateKeyFile = "/etc/letsencrypt/live/example.com/privkey.pem",
    PemChainFile = "/etc/letsencrypt/live/example.com/chain.pem"
    // OAuth enabled by default with built-in credentials
});
```

**HTTPS with PFX:**
```csharp
var server = new GenericMcpServer(new McpServerOptions
{
    UseHttps = true,
    PfxFile = "C:/certs/server.pfx",
    PfxPassword = "password",
    ServerName = "My MCP Server",
    ServerVersion = "2.0.0"
    // OAuth enabled by default
});
```

**Custom client credentials:**
```csharp
var server = new GenericMcpServer(new McpServerOptions
{
    RegisteredClients = new Dictionary<string, string>
    {
        ["my-client-id"] = "my-client-secret"
    },
    JwtSigningKey = "your-custom-256-bit-signing-key-here!"
});
```

**Development with detailed logging:**
```csharp
var loggerFactory = LoggerFactory.Create(b => b.AddConsole().SetMinimumLevel(LogLevel.Trace));

var server = new GenericMcpServer(new McpServerOptions
{
    LogHeaders = true,
    LogClientInfo = true,
    LogRequestBody = true,
    LogResponseBody = true
}, loggerFactory);
```

---

## 10. Error Handling

### 10.1 Error Hierarchy

**Level 1: HTTP Errors (500)**
- Server crash
- Unhandled middleware exceptions
- Kestrel errors

**Level 2: JSON-RPC Errors (HTTP 200 + error object)**
- Parse error (-32700)
- Invalid request (-32600)
- Method not found (-32601)
- Invalid params (-32602)
- Internal error (-32603)

**Level 3: Tool Errors (HTTP 200 + result with isError)**
- File not found
- Permission denied
- Validation errors
- Business logic errors

### 10.2 Tool Error Handling Modes

**Mode 1: ReturnAsResult (Default)**

Tool throws exception:
```csharp
throw new FileNotFoundException("File not found: test.txt");
```

Library catches and returns:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "Error: File not found: test.txt"
      }
    ],
    "isError": true
  }
}
```

**Mode 2: ThrowJsonRpcError**

Tool throws exception:
```csharp
throw new FileNotFoundException("File not found: test.txt");
```

Library returns JSON-RPC error:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32603,
    "message": "Internal error: File not found: test.txt"
  }
}
```

### 10.3 Custom Error Handling

**Tools can return structured errors:**

```csharp
public async Task<object> ExecuteAsync(JsonElement? args)
{
    try
    {
        var filePath = ArgumentExtractor.GetString(args, "file_path");

        if (!File.Exists(filePath))
        {
            return new McpError
            {
                Code = "FILE_NOT_FOUND",
                Message = $"File not found: {filePath}",
                Details = new { filePath, checkedAt = DateTime.UtcNow }
            };
        }

        var content = await File.ReadAllTextAsync(filePath);
        return new { content, size = content.Length };
    }
    catch (UnauthorizedAccessException)
    {
        return new McpError
        {
            Code = "ACCESS_DENIED",
            Message = "Permission denied"
        };
    }
}
```

**McpError is automatically converted to result with isError: true**

---

## 11. Demo Application

### 11.1 Overview

Console application demonstrating:
- MCP server setup
- OAuth server setup
- Tool registration
- Detailed logging
- Runtime commands

### 11.2 Demo Tools

**1. EchoTool**
- Echoes input message back
- Demonstrates simple string handling
- Shows timestamp in response

**2. CalculatorTool**
- Performs basic arithmetic (add, subtract, multiply, divide)
- Demonstrates parameter validation
- Shows error handling (division by zero)

**3. TimestampTool (delegate)**
- Returns current server timestamp
- Demonstrates delegate-based tool registration
- Shows multiple output formats

### 11.3 Program Flow

```csharp
// Program.cs

using Microsoft.Extensions.Logging;
using DS.McpServer;
using DS.McpServer.Demo.Tools;
using DS.McpServer.Models;

// Handle --noauth flag (OAuth is ON by default)
bool useOAuth = !args.Contains("--noauth");

// Handle --https flag
bool useHttps = args.Contains("--https");

// 1. Setup logging
var loggerFactory = LoggerFactory.Create(builder =>
{
    builder.AddConsole()
           .SetMinimumLevel(LogLevel.Trace);
});

// 2. Configure MCP server using defaults (zero configuration)
var options = new McpServerOptions();

// Override only what's needed
options.ServerName = "DS.McpServer Demo";
options.ServerVersion = "1.0.0";

// Command-line overrides
if (useHttps)
{
    options.UseHttps = true;
    options.PemCertificateFile = "certs/cert.pem";
    options.PemPrivateKeyFile = "certs/privkey.pem";
}

if (!useOAuth)
{
    options.RequireAuthentication = false;
}

// Demo logging (verbose for demonstration)
options.LogHeaders = true;
options.LogRequestBody = true;
options.LogResponseBody = true;

// 3. Create MCP server (OAuth integrated on same port)
using var server = new GenericMcpServer(options, loggerFactory);

// 4. Register tools
server.RegisterTool(new EchoTool());
server.RegisterTool(new CalculatorTool());

// Delegate style
server.RegisterTool(
    name: "timestamp",
    description: "Returns current server timestamp",
    schema: new ToolSchema { Type = "object" },
    handler: async (_) => new { timestamp = DateTime.UtcNow, timezone = "UTC" }
);

// 5. Start server
await server.StartAsync();

Console.WriteLine("==============================================");
Console.WriteLine("  DS.McpServer Demo");
Console.WriteLine("==============================================");
Console.WriteLine($"Server:    {server.ServerUrl}");
Console.WriteLine($"OAuth:     {(useOAuth ? "Enabled" : "Disabled")}");
Console.WriteLine($"Log Level: {server.GetLogLevel()}");
Console.WriteLine("==============================================");
Console.WriteLine();
Console.WriteLine("Commands:");
Console.WriteLine("  trace   - Set log level to Trace");
Console.WriteLine("  debug   - Set log level to Debug");
Console.WriteLine("  info    - Set log level to Information");
Console.WriteLine("  warning - Set log level to Warning");
Console.WriteLine("  error   - Set log level to Error");
Console.WriteLine("  status  - Show current status");
Console.WriteLine("  quit    - Stop and exit");
Console.WriteLine();

// 6. Command loop
while (server.IsRunning)
{
    Console.Write("> ");
    var command = Console.ReadLine()?.Trim().ToLower();

    switch (command)
    {
        case "trace":
            server.SetLogLevel(LogLevel.Trace);
            Console.WriteLine("Log level set to Trace");
            break;
        case "debug":
            server.SetLogLevel(LogLevel.Debug);
            Console.WriteLine("Log level set to Debug");
            break;
        case "info":
            server.SetLogLevel(LogLevel.Information);
            Console.WriteLine("Log level set to Information");
            break;
        case "warning":
            server.SetLogLevel(LogLevel.Warning);
            Console.WriteLine("Log level set to Warning");
            break;
        case "error":
            server.SetLogLevel(LogLevel.Error);
            Console.WriteLine("Log level set to Error");
            break;
        case "status":
            Console.WriteLine($"Server: {(server.IsRunning ? "Running" : "Stopped")}");
            Console.WriteLine($"URL: {server.ServerUrl}");
            Console.WriteLine($"OAuth: {(useOAuth ? "Enabled" : "Disabled")}");
            Console.WriteLine($"Log Level: {server.GetLogLevel()}");
            break;
        case "quit":
        case "exit":
            Console.WriteLine("Shutting down...");
            await server.StopAsync();
            return;
        default:
            Console.WriteLine("Unknown command. Type 'quit' to exit.");
            break;
    }
}
```

### 11.4 Sample Output

```
==============================================
  DS.McpServer Demo
==============================================
MCP Server:   https://localhost:43875
OAuth Server: https://localhost:5000
Log Level:    Trace
==============================================

Commands:
  trace   - Set log level to Trace
  debug   - Set log level to Debug
  info    - Set log level to Information
  warning - Set log level to Warning
  error   - Set log level to Error
  status  - Show current status
  quit    - Stop and exit

[2025-12-17 15:23:45.000] [INFO] MCP server started on https://localhost:43875
[2025-12-17 15:23:45.001] [INFO] OAuth server started on https://localhost:5000
[2025-12-17 15:23:45.002] [INFO] Registered 3 tools: echo, calculator, timestamp

>
[2025-12-17 15:24:10.123] [TRACE] [conn-abc123] 127.0.0.1:54321 -> GET /authorize?client_id=...
[2025-12-17 15:24:10.124] [DEBUG] Auto-approving authorization for client: https://claude.ai
[2025-12-17 15:24:10.125] [TRACE] [conn-abc123] <- 302 Found (2.1ms)

[2025-12-17 15:24:11.200] [TRACE] [conn-def456] 127.0.0.1:54322 -> POST /token
[2025-12-17 15:24:11.201] [DEBUG] Issuing access token for resource: https://localhost:43875
[2025-12-17 15:24:11.202] [TRACE] [conn-def456] <- 200 OK (2.3ms)

[2025-12-17 15:24:15.456] [TRACE] [conn-ghi789] 127.0.0.1:54323 -> POST /messages
[2025-12-17 15:24:15.457] [TRACE] Headers:
  Authorization: Bearer eyJhbG...
  Content-Type: application/json
[2025-12-17 15:24:15.458] [DEBUG] Token validated for resource: https://localhost:43875
[2025-12-17 15:24:15.459] [TRACE] Request body:
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "echo",
    "arguments": { "message": "Hello!" }
  }
}
[2025-12-17 15:24:15.460] [DEBUG] Calling tool: echo
[2025-12-17 15:24:15.461] [DEBUG] Tool 'echo' completed in 0.8ms
[2025-12-17 15:24:15.462] [TRACE] Response body:
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [{
      "type": "text",
      "text": "{\"echo\":\"Hello!\",\"timestamp\":\"2025-12-17T15:24:15Z\"}"
    }],
    "isError": false
  }
}
[2025-12-17 15:24:15.463] [TRACE] [conn-ghi789] <- 200 OK (7.2ms)

> info
Log level set to Information
[2025-12-17 15:25:00.000] [INFO] Log level changed to Information

> status
MCP Server: Running
OAuth Server: Running
Log Level: Information

> quit
Shutting down...
[2025-12-17 15:26:00.000] [INFO] MCP server stopping...
[2025-12-17 15:26:00.001] [INFO] OAuth server stopping...
[2025-12-17 15:26:00.100] [INFO] Servers stopped
```

---

## 12. API Reference

### 12.1 GenericMcpServer

```csharp
public class GenericMcpServer : IDisposable
{
    // Constructors
    public GenericMcpServer(McpServerOptions options);
    public GenericMcpServer(McpServerOptions options, ILoggerFactory loggerFactory);
    public GenericMcpServer(int port, bool useHttps = false);  // Simplified

    // Tool Registration
    public void RegisterTool(ITool tool);
    public void RegisterTool(
        string name,
        string description,
        ToolSchema schema,
        Func<JsonElement?, Task<object>> handler
    );
    public void RegisterTools(IEnumerable<ITool> tools);
    public void UnregisterTool(string name);

    // Lifecycle
    public void Start();
    public Task StartAsync(CancellationToken cancellationToken = default);
    public void Stop();
    public Task StopAsync();

    // Logging Control
    public void SetLogLevel(LogLevel level);
    public LogLevel GetLogLevel();

    // Properties
    public bool IsRunning { get; }
    public string ServerUrl { get; }
    public McpServerOptions Options { get; }

    // Events
    public event EventHandler? Started;
    public event EventHandler? Stopped;
    public event EventHandler<ToolExecutedEventArgs>? ToolExecuted;
}
```

### 12.2 OAuthServer

```csharp
public class OAuthServer : IDisposable
{
    // Constructors
    public OAuthServer(OAuthServerOptions options);
    public OAuthServer(OAuthServerOptions options, ILoggerFactory loggerFactory);

    // Lifecycle
    public void Start();
    public Task StartAsync(CancellationToken cancellationToken = default);
    public void Stop();
    public Task StopAsync();

    // Token Management
    public Task<string> GenerateTokenAsync(string clientId, string[] scopes);
    public Task RevokeTokenAsync(string token);
    public Task<bool> ValidateTokenAsync(string token);

    // Properties
    public bool IsRunning { get; }
    public string ServerUrl { get; }
    public OAuthServerOptions Options { get; }

    // Events
    public event EventHandler? Started;
    public event EventHandler? Stopped;
    public event EventHandler<TokenIssuedEventArgs>? TokenIssued;
}
```

### 12.3 ITool Interface

```csharp
public interface ITool
{
    string Name { get; }
    string Description { get; }
    ToolSchema Schema { get; }
    Task<object> ExecuteAsync(JsonElement? arguments);
}
```

### 12.4 IToolRegistry Interface

```csharp
public interface IToolRegistry
{
    void RegisterTool(ITool tool);
    void RegisterTool(string name, string description, ToolSchema schema, Func<JsonElement?, Task<object>> handler);
    void UnregisterTool(string name);
    bool HasTool(string name);
    IEnumerable<ToolInfo> GetAllTools();
    ToolInfo? GetTool(string name);
    Task<object> ExecuteToolAsync(string name, JsonElement? arguments);
}
```

---

## 13. Security Considerations

### 13.1 Token Security

**Token Storage:**
- In-memory by default (lost on restart)
- Production: implement persistent storage (encrypted)
- Never log full tokens (only first/last 4 chars)

**Token Validation:**
- Verify signature
- Check expiration
- Verify audience matches resource server
- Reject tokens from other authorization servers

**Token Lifetime:**
- Short-lived access tokens (1 hour default)
- Authorization codes single-use, 5-minute expiration
- Implement token refresh (future enhancement)

### 13.2 PKCE Security

**Requirements:**
- PKCE mandatory for all authorization requests
- code_verifier: 43-128 characters, cryptographically random
- code_challenge_method: Must be S256 (SHA-256)
- Reject plain challenge method

**Validation:**
- Store code_challenge with authorization code
- Verify SHA256(code_verifier) == code_challenge on token request
- Timing-safe comparison

### 13.3 HTTPS Requirements

**Production:**
- HTTPS required (not optional)
- Valid certificate (not self-signed)
- TLS 1.2 minimum
- Strong cipher suites

**Certificate Security:**
- Private key file permissions (600 on Linux)
- Never commit certificates to git
- Rotate certificates before expiration
- Use Let's Encrypt for free valid certs

### 13.4 Input Validation

**Tool Arguments:**
- Validate all inputs
- Sanitize file paths (no directory traversal)
- Limit string lengths
- Validate ranges for numbers
- Escape special characters

**JSON-RPC:**
- Reject oversized requests (max 1MB)
- Validate JSON structure
- Sanitize error messages (no stack traces to client)

### 13.5 Rate Limiting (Future)

**Recommendations:**
- Limit requests per IP
- Limit token issuance per client
- Implement exponential backoff
- Monitor for abuse

### 13.6 Audit Logging

**Security Events to Log:**
- Failed authentication attempts
- Token issuance
- Token revocation
- Unauthorized access attempts
- Tool execution (with user context)

---

## 14. Development Roadmap

### 14.1 Phase 1: Core Implementation (Current)

**Milestone: v1.0.0**

- [x] Architecture design
- [x] Detailed specification
- [ ] DS.McpServer library
  - [ ] HTTP/HTTPS server
  - [ ] JSON-RPC handler
  - [ ] Tool registry
  - [ ] Certificate loading (PEM/PFX)
  - [ ] Logging system
  - [ ] Token validation middleware
- [ ] DS.McpServer.OAuth library
  - [ ] Authorization endpoint (/authorize)
  - [ ] Token endpoint (/token)
  - [ ] Metadata endpoint (/.well-known/...)
  - [ ] PKCE validation
  - [ ] JWT token generation
  - [ ] In-memory token storage
- [ ] DS.McpServer.Demo app
  - [ ] Console application
  - [ ] 4 example tools
  - [ ] Runtime commands
  - [ ] Detailed logging
- [ ] Documentation
  - [ ] README.md
  - [ ] GETTING_STARTED.md
  - [ ] OAUTH_SETUP.md
  - [ ] CERTIFICATE_GUIDE.md
- [ ] Testing
  - [ ] Manual testing with Claude.ai
  - [ ] OAuth flow validation
  - [ ] HTTPS with real certificates

### 14.2 Phase 2: Enhancements (Future)

**Milestone: v1.1.0**

- [ ] Refresh token support
- [ ] Persistent token storage (SQL/Redis)
- [ ] Rate limiting
- [ ] Request size limits
- [ ] WebSocket support
- [ ] Streaming responses
- [ ] Health check endpoint improvements
- [ ] Metrics/telemetry (Prometheus)

### 14.3 Phase 3: Advanced Features (Future)

**Milestone: v2.0.0**

- [ ] Multi-user support (optional)
- [ ] User database integration
- [ ] Role-based access control (RBAC)
- [ ] Custom scopes per tool
- [ ] Tool versioning
- [ ] Dynamic tool loading (plugins)
- [ ] Admin API
- [ ] Web-based admin UI

### 14.4 Phase 4: Ecosystem (Future)

**Milestone: v3.0.0**

- [ ] NuGet package publication
- [ ] Docker image
- [ ] Kubernetes deployment templates
- [ ] CI/CD pipeline
- [ ] Automated testing
- [ ] Performance benchmarks
- [ ] Community tool repository

---

## 15. SSE Implementation Requirements

Server-Sent Events (SSE) require special handling to work correctly across browsers, particularly Firefox.

### 15.1 Critical Requirements

**1. Response Buffering Bypass**

Logging middleware that buffers responses will break SSE. The middleware MUST skip buffering for streaming endpoints:

```csharp
var isStreaming = context.Request.Path.StartsWithSegments("/sse") ||
                  context.Request.Path.StartsWithSegments("/messages");

if (isStreaming)
{
    _logger.LogDebug("[{ConnectionId}] Streaming endpoint - response not buffered", connectionId);
    await _next(context);
    return;
}
```

**2. Required Headers**

All of these headers are required for cross-browser compatibility:

```csharp
context.Response.ContentType = "text/event-stream; charset=utf-8";  // charset required for Firefox
context.Response.Headers.CacheControl = "no-cache, no-store, must-revalidate";
context.Response.Headers.Pragma = "no-cache";
context.Response.Headers.Expires = "0";
context.Response.Headers.Connection = "keep-alive";
context.Response.Headers["X-Accel-Buffering"] = "no";  // Disable nginx/proxy buffering
context.Response.Headers.AccessControlAllowOrigin = "*";
```

**3. Immediate Flush**

SSE data must be flushed immediately after writing:

```csharp
// Disable ASP.NET Core response buffering
var responseBodyFeature = context.Features.Get<IHttpResponseBodyFeature>();
responseBodyFeature?.DisableBuffering();

// Initial flush before any data
await context.Response.Body.FlushAsync();

// After sending event
await SendEventAsync(context.Response.Body, "endpoint", url);
await context.Response.Body.FlushAsync();  // CRITICAL
```

### 15.2 Common Issues

| Issue | Symptom | Fix |
|-------|---------|-----|
| Middleware buffering | Browser hangs for 84+ seconds | Skip buffering for `/sse` paths |
| Missing charset | Firefox hangs indefinitely | Add `charset=utf-8` to Content-Type |
| No flush | Client receives nothing until connection closes | Call `FlushAsync()` after every write |
| Proxy buffering | Delayed delivery | Add `X-Accel-Buffering: no` header |

### 15.3 Testing Checklist

1. `curl -N http://localhost:43875/sse` — should respond immediately
2. Open in Edge — should show SSE data immediately
3. Open in Firefox — should show SSE data immediately (charset test)
4. Check logs — should show "Streaming endpoint - response not buffered" immediately

---

## 16. SSE Transport Protocol

The MCP SSE transport has specific protocol requirements that differ from typical HTTP request/response patterns.

### 16.1 Protocol Flow

```
┌─────────────┐                              ┌─────────────┐
│   Client    │                              │   Server    │
└──────┬──────┘                              └──────┬──────┘
       │                                            │
       │  1. GET /sse                               │
       │ ──────────────────────────────────────────>│
       │                                            │
       │  event: endpoint                           │
       │  data: /messages?sessionId=abc123          │
       │ <──────────────────────────────────────────│
       │                                            │
       │  (SSE connection stays open)               │
       │                                            │
       │  2. POST /messages?sessionId=abc123        │
       │     {"jsonrpc":"2.0","method":"initialize"}│
       │ ──────────────────────────────────────────>│
       │                                            │
       │  HTTP 202 Accepted (empty body)            │
       │ <──────────────────────────────────────────│
       │                                            │
       │  3. Response via SSE stream:               │
       │  event: message                            │
       │  data: {"jsonrpc":"2.0","result":{...}}    │
       │ <──────────────────────────────────────────│
       │                                            │
```

### 16.2 Key Implementation Details

**Session Management:**
- Each SSE connection gets a unique `sessionId`
- The `/messages` endpoint URL includes `?sessionId=xxx`
- Sessions are tracked in a `ConcurrentDictionary<string, SseConnection>`
- Sessions are removed when the SSE connection closes

**Response Delivery:**
- POST to `/messages` returns **HTTP 202 Accepted** immediately
- The actual JSON-RPC response is sent via the **SSE stream**
- Format: `event: message\ndata: {json}\n\n`

**Common Mistake (causes client hang):**
```csharp
// WRONG - Client waits forever on SSE stream
return Results.Json(response);  // Returns 200 with JSON body

// CORRECT - Returns 202, sends response via SSE
context.Response.StatusCode = 202;
await SseHandler.SendMessageAsync(sessionId, response);
```

### 16.3 Testing with ngrok

For Claude.ai integration, expose your local server via ngrok:

```bash
# Start the MCP server
./DS.McpServer.Demo.exe

# In another terminal, start ngrok
ngrok http 43875
```

**Configure Claude.ai:**
1. Go to Claude Settings → Integrations → Add Custom Integration
2. Enter the ngrok URL: `https://xxxx.ngrok.io`
3. Claude will connect to `/sse` and discover tools

**Verify connection in server logs:**
```
[INFO] SSE connection from x.x.x.x, sessionId: abc123
[DEBUG] Sent endpoint event: https://xxxx.ngrok.io/messages?sessionId=abc123
[DEBUG] Processing initialize
[DEBUG] Sent SSE message
[DEBUG] Response sent via SSE for initialize
```

### 16.4 Testing Locally

**Full flow test script (PowerShell):**
```powershell
# Start SSE connection in background
$sseJob = Start-Job { curl.exe -s -N http://localhost:43875/sse }
Start-Sleep -Seconds 1

# Get sessionId from SSE output
$output = Receive-Job $sseJob -Keep
$sessionId = [regex]::Match($output, 'sessionId=([a-f0-9]+)').Groups[1].Value

# Send initialize request
$body = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}'
curl.exe -s -X POST "http://localhost:43875/messages?sessionId=$sessionId" -H "Content-Type: application/json" -d $body

# Check SSE output for response
Start-Sleep -Seconds 1
Receive-Job $sseJob

# Cleanup
Stop-Job $sseJob; Remove-Job $sseJob
```

**Expected output:**
```
event: endpoint
data: http://localhost:43875/messages?sessionId=abc123

event: message
data: {"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05",...}}
```

---

## Appendix A: MCP Protocol Reference

**Specification:** https://modelcontextprotocol.io/specification/2025-11-25

**Supported Methods:**
- `initialize` - Handshake
- `initialized` - Confirmation
- `tools/list` - List available tools
- `tools/call` - Execute tool
- `ping` - Health check

**Transport:**
- HTTP/HTTPS with SSE for discovery
- Bearer token authentication (OAuth 2.0)

**JSON-RPC Version:** 2.0

---

## Appendix B: OAuth 2.0 Reference

**Specification:** RFC 6749 (OAuth 2.0), RFC 7636 (PKCE), RFC 8707 (Resource Indicators)

**Grant Type:** Authorization Code
**PKCE:** Mandatory
**Token Format:** JWT (HS256)

---

## Appendix C: Certificate Formats

**PEM (Privacy Enhanced Mail):**
- Text format
- Base64 encoded
- Delimited by `-----BEGIN/END-----`
- Common extensions: `.pem`, `.crt`, `.key`

**PFX/PKCS#12:**
- Binary format
- Contains certificate + private key + chain
- Password protected
- Common extensions: `.pfx`, `.p12`

**Conversion:**
```bash
# PEM to PFX
openssl pkcs12 -export -out server.pfx -inkey privkey.pem -in cert.pem -certfile chain.pem

# PFX to PEM
openssl pkcs12 -in server.pfx -out cert.pem -clcerts -nokeys
openssl pkcs12 -in server.pfx -out privkey.pem -nocerts -nodes
```

---

## Appendix D: Claude.ai Integration

**Official Documentation:**

- [Getting Started with Custom Connectors using Remote MCP](https://support.claude.com/en/articles/11175166-getting-started-with-custom-connectors-using-remote-mcp#h_3d1a65aded)

**Setup Steps:**

1. Deploy MCP + OAuth servers with HTTPS
2. Get valid SSL certificates (Let's Encrypt)
3. Configure OAuth server with allowed redirect URIs
4. In Claude.ai settings → Custom Connectors:
   - Server URL: `https://your-domain.com`
   - OAuth Client ID: (auto-registered via DCR or manual)
   - OAuth Client Secret: (if manual)
5. Authorize when prompted
6. Test with MCP tools

**Redirect URI:**
- `https://claude.ai/api/mcp/auth_callback`
- `https://claude.com/api/mcp/auth_callback` (alternative)

---

**End of Specification**

---

## Document Metadata

**Author:** Design Session
**Date:** 2025-12-17
**Version:** 1.0
**Status:** Final
**Review:** Approved for implementation

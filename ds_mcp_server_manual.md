# DS.McpServer Library Manual

A .NET 10 library for building MCP (Model Context Protocol) servers that expose tools to AI assistants like Claude.

## Table of Contents

1. [Overview](#1-overview)
2. [Getting Started](#2-getting-started)
3. [Configuration Options](#3-configuration-options)
4. [Tool Registration](#4-tool-registration)
5. [Implementing Tools](#5-implementing-tools)
6. [Argument Extraction](#6-argument-extraction)
7. [Error Handling](#7-error-handling)
8. [HTTPS Setup](#8-https-setup)
9. [OAuth](#9-oauth)
10. [Events](#10-events)
11. [SSE Transport Protocol](#11-sse-transport-protocol)
12. [Testing](#12-testing)
13. [Complete Example](#13-complete-example)

---

## 1. Overview

DS.McpServer implements the Model Context Protocol (MCP) specification using HTTP/SSE transport. It allows you to create servers that expose tools (functions) that AI assistants can discover and execute.

**Key Features:**
- **Zero configuration** — works out of the box with OAuth enabled for Claude.ai
- HTTP and HTTPS support
- OAuth 2.0 with PKCE (enabled by default)
- Server-Sent Events (SSE) for bidirectional communication
- JSON-RPC 2.0 message format
- Two ways to register tools: interface-based (`ITool`) and delegate-based

**Endpoints:**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/sse` | GET | SSE stream for session establishment and responses |
| `/messages?sessionId=xxx` | POST | JSON-RPC requests |
| `/health` | GET | Health check |
| `/authorize` | GET | OAuth authorization (auto-approve) |
| `/token` | POST | OAuth token exchange |
| `/.well-known/oauth-protected-resource` | GET | OAuth metadata |
| `/.well-known/oauth-authorization-server` | GET | OAuth server metadata |

---

## 2. Getting Started

### Project Reference

```xml
<ItemGroup>
  <ProjectReference Include="..\DS.McpServer\DS.McpServer.csproj" />
</ItemGroup>
```

### Zero Configuration (Recommended)

The default constructor works out of the box with OAuth enabled for Claude.ai:

```csharp
using DS.McpServer;
using DS.McpServer.Models;

// Zero config - OAuth ON, port 43875, default credentials
using var server = new GenericMcpServer(new McpServerOptions());

server.RegisterTool(
    name: "hello",
    description: "Says hello",
    schema: new ToolSchema { Type = "object" },
    handler: async (args) => new { message = "Hello!" }
);

await server.StartAsync();
Console.ReadLine();
await server.StopAsync();
```

**Defaults:**
- Port: 43875
- OAuth: Enabled
- Client credentials: `ds` / `sdfhgdgfhdf`
- JWT signing key: Built-in demo key
- Claude.ai redirect URIs: Pre-configured

### Disable OAuth

```csharp
var options = new McpServerOptions { RequireAuthentication = false };
using var server = new GenericMcpServer(options);
```

### With Logging (Production)

```csharp
var loggerFactory = LoggerFactory.Create(builder =>
{
    builder.AddConsole().SetMinimumLevel(LogLevel.Information);
});

using var server = new GenericMcpServer(new McpServerOptions(), loggerFactory);
```

---

## 3. Configuration Options

```csharp
var options = new McpServerOptions
{
    // Network
    Port = 43875,                    // Default: 43875
    BindAddress = "127.0.0.1",       // Default: "127.0.0.1"

    // HTTPS
    UseHttps = false,                // Default: false
    PemCertificateFile = null,       // Path to cert.pem
    PemPrivateKeyFile = null,        // Path to privkey.pem
    PfxFile = null,                  // Alternative: .pfx file
    PfxPassword = null,

    // OAuth (enabled by default)
    RequireAuthentication = true,    // Default: true (OAuth ON)
    ValidateClientCredentials = true,
    JwtSigningKey = "this-is-a-demo-signing-key-32chars!",
    RegisteredClients = new Dictionary<string, string>
    {
        ["ds"] = "sdfhgdgfhdf"        // Default demo credentials
    },
    AllowedRedirectUris = new List<string>
    {
        "https://claude.ai/api/mcp/auth_callback",
        "https://claude.com/api/mcp/auth_callback"
    },

    // Server Info
    ServerName = "GenericMcpServer",
    ServerVersion = "1.0.0",

    // Logging
    LogHeaders = false,
    LogRequestBody = false,
    LogResponseBody = false,
    LogToolExecution = true,

    // Error Handling
    ToolErrorHandling = ToolErrorHandling.ReturnAsResult
};
```

---

## 4. Tool Registration

### Method 1: Interface-Based (ITool)

```csharp
server.RegisterTool(new MyCustomTool());
```

### Method 2: Delegate-Based

```csharp
server.RegisterTool(
    name: "timestamp",
    description: "Returns the current server timestamp",
    schema: new ToolSchema
    {
        Type = "object",
        Properties = new Dictionary<string, PropertySchema>
        {
            ["format"] = new PropertySchema
            {
                Type = "string",
                Description = "DateTime format string"
            }
        }
    },
    handler: async (args) =>
    {
        var format = ArgumentExtractor.GetStringOrDefault(args, "format", "O");
        return new { timestamp = DateTime.UtcNow.ToString(format) };
    }
);
```

### Batch Registration

```csharp
server.RegisterTools(new ITool[] { new EchoTool(), new CalculatorTool() });
```

---

## 5. Implementing Tools

### ITool Interface

```csharp
using DS.McpServer;
using DS.McpServer.Models;
using DS.McpServer.Utilities;

public class EchoTool : ITool
{
    public string Name => "echo";
    public string Description => "Echoes the input message back";

    public ToolSchema Schema => new()
    {
        Type = "object",
        Properties = new Dictionary<string, PropertySchema>
        {
            ["message"] = new PropertySchema
            {
                Type = "string",
                Description = "The message to echo back"
            }
        },
        Required = new[] { "message" }
    };

    public Task<object> ExecuteAsync(JsonElement? arguments)
    {
        var message = ArgumentExtractor.GetString(arguments, "message");
        return Task.FromResult<object>(new { echo = message });
    }
}
```

---

## 6. Argument Extraction

### Required Parameters (throws if missing)

```csharp
var name = ArgumentExtractor.GetString(args, "name");
var count = ArgumentExtractor.GetInt(args, "count");
var amount = ArgumentExtractor.GetDouble(args, "amount");
var enabled = ArgumentExtractor.GetBool(args, "enabled");
```

### Optional Parameters (returns null)

```csharp
var name = ArgumentExtractor.GetStringOrNull(args, "name");
var count = ArgumentExtractor.GetIntOrNull(args, "count");
```

### Optional Parameters (with default)

```csharp
var name = ArgumentExtractor.GetStringOrDefault(args, "name", "Anonymous");
var count = ArgumentExtractor.GetIntOrDefault(args, "count", 10);
```

---

## 7. Error Handling

### McpToolException

```csharp
if (divisor == 0)
{
    throw new McpToolException(
        message: "Division by zero",
        code: "DIVISION_BY_ZERO",
        details: new { divisor }
    );
}
```

### Error Handling Mode

```csharp
// Return error as tool result (default)
options.ToolErrorHandling = ToolErrorHandling.ReturnAsResult;

// Return JSON-RPC error
options.ToolErrorHandling = ToolErrorHandling.ThrowJsonRpcError;
```

---

## 8. HTTPS Setup

### PEM Files

```csharp
var options = new McpServerOptions
{
    UseHttps = true,
    PemCertificateFile = "/path/to/cert.pem",
    PemPrivateKeyFile = "/path/to/privkey.pem"
};
```

### PFX File

```csharp
var options = new McpServerOptions
{
    UseHttps = true,
    PfxFile = "/path/to/certificate.pfx",
    PfxPassword = "password"
};
```

---

## 9. OAuth

OAuth 2.0 with PKCE is **enabled by default** for Claude.ai integration.

### Default Behavior

- Auto-approve flow (no login UI)
- Client credentials: `ds` / `sdfhgdgfhdf`
- Claude.ai redirect URIs pre-configured
- JWT tokens with 1-hour expiry

### Custom Credentials

```csharp
var options = new McpServerOptions
{
    RegisteredClients = new Dictionary<string, string>
    {
        ["my-client-id"] = "my-client-secret"
    },
    JwtSigningKey = "your-custom-256-bit-signing-key-here!"
};
```

### OAuth Flow

1. Claude.ai redirects to `/authorize?client_id=...&code_challenge=...`
2. Server auto-approves and redirects back with authorization code
3. Claude.ai exchanges code for token at `/token`
4. Claude.ai uses token for `/sse` and `/messages` requests

---

## 10. Events

```csharp
server.Started += (sender, e) => Console.WriteLine("Started!");
server.Stopped += (sender, e) => Console.WriteLine("Stopped!");
server.ToolExecuted += (sender, e) => Console.WriteLine($"Tool: {e.ToolName}");
```

---

## 11. SSE Transport Protocol

```
Client                                Server
  |  1. GET /sse (with Bearer token)    |
  |------------------------------------->|
  |  2. SSE: event: endpoint            |
  |     data: /messages?sessionId=xxx   |
  |<-------------------------------------|
  |  3. POST /messages?sessionId=xxx    |
  |------------------------------------->|
  |  4. HTTP 202 Accepted               |
  |<-------------------------------------|
  |  5. SSE: event: message             |
  |     data: {"jsonrpc":"2.0",...}     |
  |<-------------------------------------|
```

---

## 12. Testing

### Health Check

```bash
curl http://localhost:43875/health
```

### Without OAuth (--noauth mode)

```bash
# Get session
curl -N http://localhost:43875/sse

# Call tool
curl -X POST "http://localhost:43875/messages?sessionId=xxx" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"echo","arguments":{"message":"Hello"}}}'
```

### With OAuth

Use Claude.ai to connect, or implement full OAuth flow with PKCE.

---

## 13. Complete Example

```csharp
using DS.McpServer;
using DS.McpServer.Models;
using Microsoft.Extensions.Logging;

// Handle flags
bool useOAuth = !args.Contains("--noauth");
bool useHttps = args.Contains("--https");

// Logging
var loggerFactory = LoggerFactory.Create(b => b.AddConsole().SetMinimumLevel(LogLevel.Information));

// Zero-config options
var options = new McpServerOptions
{
    ServerName = "My MCP Server",
    ServerVersion = "1.0.0"
};

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

// Create server
using var server = new GenericMcpServer(options, loggerFactory);

// Register tools
server.RegisterTool(
    name: "hello",
    description: "Says hello",
    schema: new ToolSchema { Type = "object" },
    handler: async (args) => new { message = "Hello!" }
);

// Start
await server.StartAsync();
Console.WriteLine($"Server: {server.ServerUrl}");
Console.WriteLine($"OAuth:  {(useOAuth ? "Enabled" : "Disabled")}");
Console.ReadLine();
await server.StopAsync();
```

---

## Version History

| Version | Date | Notes |
|---------|------|-------|
| 1.1.0 | 2025-12-17 | Zero-configuration with OAuth enabled by default |
| 1.0.0 | 2025-12-17 | Initial release |

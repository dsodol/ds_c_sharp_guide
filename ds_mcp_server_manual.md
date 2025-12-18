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
9. [Events](#9-events)
10. [SSE Transport Protocol](#10-sse-transport-protocol)
11. [Testing](#11-testing)
12. [Complete Example (Production Pattern)](#12-complete-example-production-pattern)

---

## 1. Overview

DS.McpServer implements the Model Context Protocol (MCP) specification using HTTP/SSE transport. It allows you to create servers that expose tools (functions) that AI assistants can discover and execute.

**Key Features:**
- HTTP and HTTPS support
- Server-Sent Events (SSE) for bidirectional communication
- JSON-RPC 2.0 message format
- Two ways to register tools: interface-based (`ITool`) and delegate-based
- Built-in argument extraction utilities
- Configurable logging and error handling

**Endpoints:**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/sse` | GET | SSE stream for session establishment and responses |
| `/messages?sessionId=xxx` | POST | JSON-RPC requests |
| `/health` | GET | Health check |
| `/.well-known/oauth-protected-resource` | GET | OAuth metadata (Phase 2) |

---

## 2. Getting Started

### Project Reference

Add a project reference to DS.McpServer:

```xml
<ItemGroup>
  <ProjectReference Include="..\DS.McpServer\DS.McpServer.csproj" />
</ItemGroup>
```

### Minimal Server (Quick Testing Only)

> **Warning:** The minimal constructor is for quick testing only. For production use, always use the constructor with `ILoggerFactory` (see [Complete Example](#12-complete-example)). Without a logger factory, request/response logging is disabled.

```csharp
using DS.McpServer;
using DS.McpServer.Models;

// Create server with minimal configuration (testing only)
using var server = new GenericMcpServer(port: 43875);

// Register a simple tool
server.RegisterTool(
    name: "hello",
    description: "Says hello",
    schema: new ToolSchema { Type = "object" },
    handler: async (args) => new { message = "Hello, World!" }
);

// Start and wait
await server.StartAsync();
Console.WriteLine($"Server running at {server.ServerUrl}");
Console.ReadLine();
await server.StopAsync();
```

### Production Server (Recommended)

For production use, always create a `LoggerFactory` and pass it to the constructor:

```csharp
using DS.McpServer;
using DS.McpServer.Models;
using Microsoft.Extensions.Logging;

// Setup logging (REQUIRED for production)
var loggerFactory = LoggerFactory.Create(builder =>
{
    builder.AddConsole().SetMinimumLevel(LogLevel.Information);
});

var options = new McpServerOptions
{
    Port = 43875,
    ServerName = "My MCP Server"
};

// Always pass loggerFactory for production use
using var server = new GenericMcpServer(options, loggerFactory);

server.RegisterTool(
    name: "hello",
    description: "Says hello",
    schema: new ToolSchema { Type = "object" },
    handler: async (args) => new { message = "Hello, World!" }
);

await server.StartAsync();
Console.WriteLine($"Server running at {server.ServerUrl}");
Console.ReadLine();
await server.StopAsync();
```

---

## 3. Configuration Options

Use `McpServerOptions` for full configuration:

```csharp
var options = new McpServerOptions
{
    // Network
    Port = 43875,                    // Default: 43875
    BindAddress = "0.0.0.0",         // Default: "0.0.0.0" (all interfaces)

    // HTTPS (optional)
    UseHttps = false,                // Default: false
    PemCertificateFile = null,       // Path to cert.pem
    PemPrivateKeyFile = null,        // Path to privkey.pem
    PfxFile = null,                  // Alternative: path to .pfx file
    PfxPassword = null,              // Password for PFX file

    // Server Info (shown in MCP initialize response)
    ServerName = "My MCP Server",    // Default: "DS.McpServer"
    ServerVersion = "1.0.0",         // Default: "1.0.0"

    // Logging
    LogHeaders = false,              // Log HTTP headers
    LogClientInfo = true,            // Log client IP/port
    LogRequestBody = false,          // Log request JSON
    LogResponseBody = false,         // Log response JSON
    LogToolExecution = true,         // Log tool calls

    // Error Handling
    ToolErrorHandling = ToolErrorHandling.ReturnAsResult,  // or ThrowJsonRpcError

    // Shutdown
    ShutdownTimeout = TimeSpan.Zero  // Instant shutdown
};

using var server = new GenericMcpServer(options);
```

### CORS Configuration

```csharp
options.Cors = new CorsOptions
{
    AllowedOrigins = new[] { "*" },                      // Default: all origins
    AllowedMethods = new[] { "GET", "POST", "OPTIONS" }, // Default
    AllowedHeaders = new[] { "Content-Type", "Authorization" },
    MaxAge = 86400                                       // 24 hours
};
```

---

## 4. Tool Registration

### Method 1: Interface-Based (ITool)

Create a class implementing `ITool`:

```csharp
server.RegisterTool(new MyCustomTool());
```

### Method 2: Delegate-Based

For simple tools, use inline registration:

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
                Description = "DateTime format string (default: ISO 8601)",
                Default = "O"
            }
        }
    },
    handler: async (args) =>
    {
        var format = ArgumentExtractor.GetStringOrDefault(args, "format", "O");
        return new
        {
            timestamp = DateTime.UtcNow.ToString(format),
            unix = DateTimeOffset.UtcNow.ToUnixTimeSeconds()
        };
    }
);
```

### Method 3: Batch Registration

```csharp
server.RegisterTools(new ITool[]
{
    new EchoTool(),
    new CalculatorTool(),
    new FileTool()
});
```

### Unregistering Tools

```csharp
server.UnregisterTool("toolName");
```

---

## 5. Implementing Tools

### ITool Interface

```csharp
using System.Text.Json;
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
            },
            ["uppercase"] = new PropertySchema
            {
                Type = "boolean",
                Description = "Convert message to uppercase"
            }
        },
        Required = new[] { "message" }
    };

    public Task<object> ExecuteAsync(JsonElement? arguments)
    {
        var message = ArgumentExtractor.GetString(arguments, "message");
        var uppercase = ArgumentExtractor.GetBoolOrDefault(arguments, "uppercase", false);

        if (uppercase)
        {
            message = message.ToUpperInvariant();
        }

        return Task.FromResult<object>(new
        {
            echo = message,
            timestamp = DateTime.UtcNow.ToString("O")
        });
    }
}
```

### Schema Definition

Use `PropertySchema` factory methods for cleaner code:

```csharp
public ToolSchema Schema => new()
{
    Type = "object",
    Properties = new Dictionary<string, PropertySchema>
    {
        ["name"] = PropertySchema.String("User's name"),
        ["age"] = PropertySchema.Integer("User's age"),
        ["score"] = PropertySchema.Number("Score value"),
        ["active"] = PropertySchema.Boolean("Is active"),
        ["role"] = PropertySchema.EnumOf(new[] { "admin", "user", "guest" }, "User role"),
        ["tags"] = PropertySchema.ArrayOf(PropertySchema.String(), "List of tags")
    },
    Required = new[] { "name", "age" }
};
```

---

## 6. Argument Extraction

Use `ArgumentExtractor` to safely extract typed values from tool arguments.

### Required Parameters

Throws `ArgumentException` if missing:

```csharp
var name = ArgumentExtractor.GetString(args, "name");
var count = ArgumentExtractor.GetInt(args, "count");
var amount = ArgumentExtractor.GetDouble(args, "amount");
var enabled = ArgumentExtractor.GetBool(args, "enabled");
var config = ArgumentExtractor.GetObject<MyConfig>(args, "config");
```

### Optional Parameters (Returns Null)

```csharp
var name = ArgumentExtractor.GetStringOrNull(args, "name");
var count = ArgumentExtractor.GetIntOrNull(args, "count");
var amount = ArgumentExtractor.GetDoubleOrNull(args, "amount");
var enabled = ArgumentExtractor.GetBoolOrNull(args, "enabled");
var items = ArgumentExtractor.GetArrayOrNull<string>(args, "items");
```

### Optional Parameters (With Default)

```csharp
var name = ArgumentExtractor.GetStringOrDefault(args, "name", "Anonymous");
var count = ArgumentExtractor.GetIntOrDefault(args, "count", 10);
var amount = ArgumentExtractor.GetDoubleOrDefault(args, "amount", 0.0);
var enabled = ArgumentExtractor.GetBoolOrDefault(args, "enabled", false);
```

### Utility Methods

```csharp
// Check if parameter exists
if (ArgumentExtractor.HasParameter(args, "optional"))
{
    // ...
}

// Get raw JsonElement
var raw = ArgumentExtractor.GetRawElement(args, "data");
```

---

## 7. Error Handling

### McpToolException

Throw `McpToolException` for tool-specific errors:

```csharp
public Task<object> ExecuteAsync(JsonElement? arguments)
{
    var divisor = ArgumentExtractor.GetDouble(arguments, "divisor");

    if (divisor == 0)
    {
        throw new McpToolException(
            message: "Division by zero is not allowed",
            code: "DIVISION_BY_ZERO",
            details: new { divisor }
        );
    }

    // ... continue
}
```

### Error Handling Mode

Configure how tool errors are returned:

```csharp
// Return error as tool result with isError: true (default)
options.ToolErrorHandling = ToolErrorHandling.ReturnAsResult;

// Return JSON-RPC error response
options.ToolErrorHandling = ToolErrorHandling.ThrowJsonRpcError;
```

---

## 8. HTTPS Setup

### Using PEM Files (Let's Encrypt, etc.)

```csharp
var options = new McpServerOptions
{
    Port = 43875,
    UseHttps = true,
    PemCertificateFile = "/path/to/cert.pem",
    PemPrivateKeyFile = "/path/to/privkey.pem"
};
```

### Using PFX File

```csharp
var options = new McpServerOptions
{
    Port = 43875,
    UseHttps = true,
    PfxFile = "/path/to/certificate.pfx",
    PfxPassword = "your-password"
};
```

### Command-Line Toggle

For applications that need both HTTP and HTTPS modes:

```csharp
bool useHttps = args.Contains("--https");

var options = new McpServerOptions
{
    Port = 43875,
    UseHttps = useHttps,
    PemCertificateFile = useHttps ? "certs/cert.pem" : null,
    PemPrivateKeyFile = useHttps ? "certs/privkey.pem" : null
};
```

---

## 9. Events

### Available Events

```csharp
// Server started
server.Started += (sender, e) =>
{
    Console.WriteLine("Server started!");
};

// Server stopped
server.Stopped += (sender, e) =>
{
    Console.WriteLine("Server stopped!");
};

// Tool executed
server.ToolExecuted += (sender, e) =>
{
    Console.WriteLine($"Tool '{e.ToolName}' executed");
    Console.WriteLine($"Arguments: {e.Arguments}");
    Console.WriteLine($"Result: {e.Result}");
};
```

---

## 10. SSE Transport Protocol

DS.McpServer uses Server-Sent Events for MCP communication:

### Protocol Flow

```
Client                                Server
  |                                      |
  |  1. GET /sse                         |
  |------------------------------------->|
  |                                      |
  |  2. SSE: event: endpoint             |
  |     data: /messages?sessionId=xxx    |
  |<-------------------------------------|
  |                                      |
  |  3. POST /messages?sessionId=xxx     |
  |     {"jsonrpc":"2.0",...}            |
  |------------------------------------->|
  |                                      |
  |  4. HTTP 202 Accepted                |
  |<-------------------------------------|
  |                                      |
  |  5. SSE: event: message              |
  |     data: {"jsonrpc":"2.0",...}      |
  |<-------------------------------------|
```

**Key Points:**
- POST returns `202 Accepted` immediately
- Actual response is sent via SSE stream
- Session ID links POST requests to SSE connection
- Heartbeat events keep connection alive (every 30 seconds)

---

## 11. Testing

### Health Check

```bash
curl http://localhost:43875/health
```

Response:
```json
{
  "status": "healthy",
  "server": "DS.McpServer Demo",
  "version": "1.0.0",
  "tools": 3
}
```

### SSE Connection Test

```bash
curl -N http://localhost:43875/sse
```

You should see:
```
event: endpoint
data: /messages?sessionId=abc123

:heartbeat
```

### Tool Execution Test

With the session ID from SSE:

```bash
# Initialize
curl -X POST "http://localhost:43875/messages?sessionId=abc123" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}'

# List tools
curl -X POST "http://localhost:43875/messages?sessionId=abc123" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'

# Call a tool
curl -X POST "http://localhost:43875/messages?sessionId=abc123" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"echo","arguments":{"message":"Hello"}}}'
```

### Testing with Claude.ai

1. Start the server
2. Use ngrok or similar to expose the server: `ngrok http 43875`
3. In Claude.ai settings, add MCP server with the ngrok URL
4. Claude can now discover and use your tools

---

## 12. Complete Example (Production Pattern)

This is the recommended pattern for production use. Key points:
- Always create and pass `ILoggerFactory` to enable logging
- Use `McpServerOptions` for full configuration
- Handle `--version` and other command-line flags

### Program.cs

```csharp
using DS.McpServer;
using DS.McpServer.Demo.Tools;
using DS.McpServer.Models;
using Microsoft.Extensions.Logging;

// Handle --version flag
if (args.Contains("--version"))
{
    Console.WriteLine($"MyMcpServer Build {BuildInfo.Number}");
    return 0;
}

// Handle --https flag
bool useHttps = args.Contains("--https");

// Setup logging
var loggerFactory = LoggerFactory.Create(builder =>
{
    builder
        .AddConsole()
        .SetMinimumLevel(LogLevel.Information);
});

var logger = loggerFactory.CreateLogger("Main");
logger.LogInformation("MyMcpServer Build {Build}", BuildInfo.Number);

// Configure server
var options = new McpServerOptions
{
    Port = 43875,
    BindAddress = "0.0.0.0",
    UseHttps = useHttps,
    PemCertificateFile = useHttps ? "certs/cert.pem" : null,
    PemPrivateKeyFile = useHttps ? "certs/privkey.pem" : null,
    ServerName = "My MCP Server",
    ServerVersion = "1.0.0",
    LogToolExecution = true
};

// Create and configure server
using var server = new GenericMcpServer(options, loggerFactory);

// Register tools
server.RegisterTool(new EchoTool());
server.RegisterTool(new CalculatorTool());

// Register inline tool
server.RegisterTool(
    name: "timestamp",
    description: "Returns current timestamp",
    schema: new ToolSchema { Type = "object" },
    handler: async (args) => new { timestamp = DateTime.UtcNow.ToString("O") }
);

// Subscribe to events
server.ToolExecuted += (s, e) =>
    logger.LogInformation("Tool executed: {Tool}", e.ToolName);

// Start server
await server.StartAsync();

Console.WriteLine($"Server: {server.ServerUrl}");
Console.WriteLine($"SSE:    {server.ServerUrl}/sse");
Console.WriteLine($"Health: {server.ServerUrl}/health");
Console.WriteLine("Press Enter to stop...");
Console.ReadLine();

await server.StopAsync();
return 0;
```

### BuildInfo.cs

```csharp
public static class BuildInfo
{
    public const string Number = "2025_12_17__10_00__001";
    public static string PluginDirectory => AppDomain.CurrentDomain.BaseDirectory;
    public static string ProjectDirectory => Directory.GetCurrentDirectory();
}
```

### Build and Run

```bash
# Build
dotnet publish src/MyMcpServer.csproj -c Debug -r win-x64 --self-contained true -p:PublishSingleFile=true

# Copy executable
cp out/bin/Debug/net10.0-windows/win-x64/publish/MyMcpServer.exe .

# Run HTTP mode
./MyMcpServer.exe

# Run HTTPS mode
./MyMcpServer.exe --https
```

---

## Appendix: Namespaces Reference

| Namespace | Purpose |
|-----------|---------|
| `DS.McpServer` | Main classes: `GenericMcpServer`, `ITool`, `IToolRegistry` |
| `DS.McpServer.Models` | Data models: `McpServerOptions`, `ToolSchema`, `PropertySchema` |
| `DS.McpServer.Utilities` | Helpers: `ArgumentExtractor` |
| `DS.McpServer.Handlers` | Internal: `JsonRpcHandler`, `SseHandler`, `McpToolException` |

---

## Version History

| Version | Date | Notes |
|---------|------|-------|
| 1.0.0 | 2025-12-17 | Initial release with HTTP/HTTPS support |

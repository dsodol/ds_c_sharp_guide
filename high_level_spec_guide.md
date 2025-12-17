# High-Level Specification Guide

## 1. Purpose

### 1.1. Why This Guide Exists

This guide defines how to write high-level specifications that Claude can use as session-start checklists. It ensures consistent abstraction levels and prevents mixing implementation details with user-facing requirements.

### 1.2. Problem: Claude Mixes Abstraction Levels

Without clear guidance, Claude tends to:
- Include protocol details (JSON-RPC, SSE, HTTP status codes) in user-facing specs
- List implementation constraints as "configurable options"
- State outcomes as requirements
- Put items in wrong components (e.g., HTTP/HTTPS under OAuth)
- Mix interface elements with internal mechanics

### 1.3. Goal: Consistent High-Level Specs for Session-Start

A high-level spec should serve as a checklist that Claude reads at session start to understand:
- What components exist
- What the user can control (interface)
- What guarantees exist (properties)
- Where to find detailed information

---

## 2. Definition

### 2.1. High-Level Spec = Interface + Properties the User Cares About

This is the core definition. Every item in a high-level spec must be either:
- **Interface:** Something the user interacts with or configures
- **Property:** Something the user cares about (guarantee, behavior, constraint)

### 2.2. Contrast with Detailed Spec

| High-Level Spec | Detailed Spec |
|-----------------|---------------|
| What user controls | How it works internally |
| What user cares about | Implementation mechanics |
| Session-start checklist | Reference during development |
| Answers "what can I do?" | Answers "how does it work?" |

### 2.3. The "User" Differs by Component Type

Critical insight: "user" means different things for different components.

| Component Type | User Is | Example |
|----------------|---------|---------|
| Library | Developer consuming the API | DS.McpServer user = developer calling RegisterTool() |
| Application | End user running the app | DS.McpServer.Demo user = person at command line |

This affects what counts as "interface" and "properties."

---

## 3. Interface — For Libraries

### 3.1. Definition

For a library, interface means the **API surface exposed to consuming code**:
- Classes the developer instantiates
- Methods the developer calls
- Configuration options the developer passes in
- Extension points the developer uses

### 3.2. What Belongs

**Configuration options (what can user pass in):**
- Port number
- Token expiration time
- List of allowed clients

**Methods available to call:**
- Start/Stop server
- Register tools
- Set log level

**Extension points:**
- Register custom tools
- Provide custom storage implementation

### 3.3. What Does NOT Belong

**Internal implementation:**
- How requests are processed internally
- Which middleware runs in what order
- Internal data structures

**Required inputs disguised as "configurable":**
- If it's required, it's not a configuration choice
- Example: "JWT signing key" is required — listing it as "configurable" is misleading

**Protocol mechanics:**
- Wire format details
- Status codes
- Handshake sequences

### 3.4. Examples from DS.McpServer.OAuth

**YES — belongs in high-level spec:**
- "Configurable list of allowed client IDs and secrets" — developer chooses what clients to allow
- "Configurable token expiration" — developer chooses how long tokens last

**NO — does not belong:**
- "JWT signing key" — required input, not optional configuration
- "PKCE S256 required" — protocol constraint, developer doesn't choose this
- "Uses HS256 algorithm" — implementation detail
- "HTTP/HTTPS with PEM certificates" — transport concern, not OAuth

---

## 4. Interface — For Applications

### 4.1. Definition

For an application, interface means the **user interface**:
- CLI flags and arguments
- Interactive commands
- GUI screens, panels, controls
- Output format and display

### 4.2. What Belongs

**CLI flags and arguments:**
- `--version` shows build number
- `--noauth` disables OAuth
- `--https` enables TLS

**Interactive commands:**
- `status` shows server state
- `tools` lists registered tools
- `quit` stops server

**Screens/panels/controls (for GUI apps):**
- Main window layout
- Settings dialog options
- Log panel

### 4.3. What Does NOT Belong

**Internal processing:**
- How commands are parsed
- How state is managed internally

**Implementation of features:**
- Which logging framework is used
- How rotation is implemented

### 4.4. Examples from DS.McpServer.Demo

**YES — belongs in high-level spec:**
- "`--version` flag shows build number" — user invokes this
- "Interactive console commands: status, tools, quit" — user types these
- "OAuth ON by default, `--noauth` to disable" — user choice

**NO — does not belong:**
- "Uses LoggerFactory internally" — implementation detail
- "Parses args with switch statement" — how it works, not what user sees

---

## 5. Properties — What the User Cares About

### 5.1. Definition

Properties are **guarantees and behaviors that matter to the user**, whether or not the user directly interacts with them.

### 5.2. Key Insight

The test is **"Does user care?"** — not **"Does user touch it?"**

User doesn't touch log rotation, but user cares that disk won't fill up.
User doesn't touch CORS headers, but user cares that browser requests work.

### 5.3. Categories

**What's handled for them (don't have to build):**
- "No login UI required" — library handles OAuth auto-approve
- "Tool dispatch handled automatically" — just register tools, library routes calls

**What's guaranteed (won't break, won't fill disk):**
- "Log rotation keeps 3 files" — disk space protected
- "Graceful shutdown on quit" — no orphan processes

**Compatibility:**
- "Works with Claude.ai" — target integration works
- "Works behind ngrok/reverse proxy" — deployment scenario supported

**Constraints that affect their design:**
- "Auto-approve only (no login UI support)" — don't plan to build login flow
- "Single port for MCP + OAuth" — architecture constraint

### 5.4. Examples

**YES — user cares:**
- "No login UI required" — user doesn't have to build OAuth consent screen
- "Logs to `logs/`, rotation keeps 3 files" — user can debug, disk is safe
- "Works behind ngrok" — user's deployment scenario is supported
- "Single-file self-contained executable" — user can deploy easily

**NO — user doesn't care:**
- "Uses HS256 for JWT" — internal algorithm choice
- "POST returns 202, response via SSE" — protocol mechanics
- "ConcurrentDictionary for session storage" — internal data structure
- "Middleware pipeline order" — internal processing

---

## 6. Test Questions

Apply these questions to every item before including in high-level spec:

### 6.1. "Would I ask this before using the library/app?"

Before using DS.McpServer.OAuth, would I ask:
- "Do I need to build a login page?" — YES, include it
- "What JWT algorithm is used?" — NO, exclude it

### 6.2. "Does the user care about this?"

- Log rotation: User cares (disk space) — include
- Internal buffer size: User doesn't care — exclude

### 6.3. "Can this be expressed as a requirement?"

- "Works with Claude.ai out of the box" — NO, this is an outcome/target, not a requirement
- "Configurable list of allowed clients" — YES, this is a requirement

Outcomes go in "Target:" line, not in requirements list.

### 6.4. "Is this a choice or a constraint?"

- Choice: User decides → Interface item
- Constraint user cares about → Property item
- Internal constraint → Detailed spec only

### 6.5. "Does this belong to this component?"

- HTTP/HTTPS is transport → belongs to Server, not OAuth
- Token expiration is auth → belongs to OAuth, not Server
- CLI flags → belong to Demo, not Library

---

## 7. Common Mistakes

### 7.1. Implementation Details as Requirements

**Wrong:**
```
3.1. [ ] PKCE mandatory (S256)
3.2. [ ] JWT tokens (HMAC-SHA256)
```

**Problem:** These are how the library implements OAuth internally. The user doesn't choose these — they're fixed.

**Right:** Don't include, or if relevant, state as property:
```
**Note:** Uses PKCE S256 (required by MCP spec)
```

### 7.2. Protocol Details

**Wrong:**
```
3.1. [ ] MCP spec 2024-11-05, JSON-RPC 2.0
3.2. [ ] SSE transport only
3.3. [ ] POST returns 202, response via SSE stream
```

**Problem:** Wire protocol details. User doesn't control these, and mostly doesn't care.

**Right:** Remove entirely, or reference detailed spec:
```
See docs_detailed/DS_MCP_SERVER_SPEC.md for protocol details.
```

### 7.3. Required Inputs Listed as Configurable

**Wrong:**
```
4.1. [ ] Configurable JWT signing key
```

**Problem:** Signing key is REQUIRED. Calling it "configurable" implies it's optional.

**Right:** Either don't list (it's just an input), or be honest:
```
4.1. [ ] Requires JWT signing key (32+ characters)
```

But even this may be too detailed for high-level spec.

### 7.4. Outcomes Stated as Requirements

**Wrong:**
```
4.1. [ ] Works with Claude.ai out of the box
```

**Problem:** This is a desired outcome, not a requirement. You can't "check off" that it works — you verify after building.

**Right:** State as target:
```
## 4. OAuth Library Requirements

**Target:** Claude.ai MCP integration

4.1. [ ] No login UI required (auto-approve flow)
```

### 7.5. Wrong Component

**Wrong:**
```
## 4. OAuth Library Requirements

4.1. [ ] HTTP/HTTPS with PEM certificates
```

**Problem:** HTTP/HTTPS is transport layer, not OAuth. OAuth works over whatever transport is configured.

**Right:** Put in server component:
```
## 3. Library Requirements (DS.McpServer)

3.1. [ ] Configurable choice between HTTP and HTTPS
```

### 7.6. Mixing Abstraction Levels in Same List

**Wrong:**
```
3.1. [ ] Configurable port
3.2. [ ] PKCE S256 required
3.3. [ ] Extensible with custom tools
3.4. [ ] POST /messages returns 202
```

**Problem:** Mixes user choices (3.1, 3.3) with protocol details (3.2, 3.4).

**Right:** Only user-facing items:
```
3.1. [ ] Configurable port
3.2. [ ] Extensible with custom tools
```

---

## 8. Document Structure

### 8.1. Purpose Statement

First line explains what this spec is for:
```
**Purpose:** Session-start checklist for Claude Code. Read this first, then detailed docs as needed.
```

### 8.2. Reference Documents

One section listing detailed docs with one-sentence descriptions:
```
## 1. Reference Documents

1.1. `docs_detailed/DS_MCP_SERVER_SPEC.md` — Full design spec with architecture and API
1.2. `docs_detailed/HTTP_HTTPS_TECHNICAL_DESIGN.md` — HTTP/HTTPS and SSE implementation
```

### 8.3. Components List

What makes up the solution:
```
## 2. Solution Components

2.1. **DS.McpServer** (Library) — Generic MCP server
2.2. **DS.McpServer.OAuth** (Library) — OAuth 2.0 authorization
2.3. **DS.McpServer.Demo** (Application) — Console app with example tools
```

### 8.4. Per-Component Sections

Each component gets its own section with:

**Target (if applicable):**
```
**Target:** Claude.ai MCP integration
```

**Interface items (numbered checklist):**
```
4.1. [ ] Configurable list of allowed client IDs and secrets
4.2. [ ] Configurable token expiration
```

**Properties (can be mixed with interface or separate):**
```
4.3. [ ] No login UI required (auto-approve flow)
```

### 8.5. Numbered Chapters and Items Throughout

Every chapter and item numbered for easy reference:
- Chapter: `## 3. Library Requirements`
- Item: `3.1. [ ] Configurable port`

### 8.6. Checklist Format for Session-Start Verification

Use `[ ]` checkbox format so Claude can mentally verify each item:
```
3.1. [ ] Configurable choice between HTTP and HTTPS
3.2. [ ] Configurable port
```

---

## 9. Process

### 9.1. Start by Identifying the User for Each Component

Before writing anything, ask: "Who is the user of this component?"

| Component | User |
|-----------|------|
| DS.McpServer | Developer using library |
| DS.McpServer.Demo | Person running the app |

### 9.2. List Interface Elements (What They Control)

For each component, list what the user can:
- Configure (options)
- Call (methods, commands)
- Extend (plugins, custom implementations)

### 9.3. List Properties (What They Care About)

For each component, list:
- What's handled for them
- What's guaranteed
- Compatibility promises
- Constraints affecting their design

### 9.4. Apply Test Questions to Each Item

For each item, ask:
- Would user ask this before starting?
- Does user care?
- Is it a requirement or outcome?
- Is it a choice or constraint?
- Is it in the right component?

### 9.5. Remove Anything That Fails Tests

Be aggressive. When in doubt, leave it out. Detailed specs exist for implementation details.

### 9.6. Verify Each Item Is in Correct Component

Final pass: Is each item in the component where it belongs?

---

## 10. Example: Before and After

### 10.1. Bad Example (First Draft)

```
## 3. User Requirements

3.1. [ ] Single-file self-contained executable
3.2. [ ] OAuth ON by default, `--noauth` flag to disable
3.3. [ ] HTTP by default, `--https` flag to enable TLS
3.4. [ ] `--version` flag shows build number
3.5. [ ] File logging to `logs/`, rotation (keep 3 files)
3.6. [ ] Interactive console: change log level, show status, list tools, quit
3.7. [ ] Works behind ngrok (respects `X-Forwarded-*` headers)

## 4. Tool Registration

4.1. [ ] Delegate-based: `server.RegisterTool(name, description, schema, handler)`
4.2. [ ] Interface-based: implement `ITool` and register instance

## 5. Protocol

5.1. [ ] MCP spec 2024-11-05, JSON-RPC 2.0
5.2. [ ] SSE transport only (`GET /sse` → `POST /messages`)
5.3. [ ] POST returns 202, response delivered via SSE stream
5.4. [ ] PKCE mandatory (S256), JWT tokens (HMAC-SHA256)
```

### 10.2. What Was Wrong with Each Item

| Item | Problem |
|------|---------|
| 3.1-3.6 | Mixed library and demo concerns |
| 3.7 | Implementation detail (HTTP headers) |
| 4.1-4.2 | API details, too low-level |
| 5.1-5.4 | Protocol details, user doesn't care |

### 10.3. Good Example (Final Version)

```
## 3. Library Requirements (DS.McpServer)

3.1. [ ] Configurable choice between HTTP and HTTPS
3.2. [ ] Configurable port
3.3. [ ] Optional OAuth protection (can be disabled)
3.4. [ ] Extensible with custom tools
3.5. [ ] Configurable logging level
3.6. [ ] Reverse proxy compatible (ngrok, Cloudflare, nginx)

## 4. OAuth Library Requirements (DS.McpServer.OAuth)

**Target:** Claude.ai MCP integration

4.1. [ ] No login UI required (auto-approve flow)
4.2. [ ] Configurable list of allowed client IDs and secrets
4.3. [ ] Configurable token expiration

## 5. Demo Requirements (DS.McpServer.Demo)

5.1. [ ] Single-file self-contained executable
5.2. [ ] OAuth ON by default, `--noauth` flag to disable
5.3. [ ] HTTP by default, `--https` flag to enable TLS
5.4. [ ] `--version` flag shows build number
5.5. [ ] File logging to `logs/`, rotation (keep 3 files)
5.6. [ ] Interactive console: change log level, show status, list tools, quit
```

### 10.4. Why Each Item Belongs

| Item | Why It Belongs |
|------|----------------|
| 3.1 | Developer choice — HTTP or HTTPS |
| 3.2 | Developer choice — which port |
| 3.3 | Developer choice — auth or not |
| 3.4 | Developer capability — add tools |
| 3.5 | Developer choice — verbosity |
| 3.6 | Property — deployment scenario works |
| 4.1 | Property — no UI to build |
| 4.2 | Developer choice — which clients allowed |
| 4.3 | Developer choice — token lifetime |
| 5.1 | Property — easy deployment |
| 5.2 | User choice — CLI flag |
| 5.3 | User choice — CLI flag |
| 5.4 | User interface — CLI flag |
| 5.5 | Property — debugging, disk safety |
| 5.6 | User interface — commands available |

---

## Document Metadata

**Author:** Design session with Claude
**Date:** 2025-12-17
**Version:** 1.0
**Purpose:** Guide for writing high-level specifications

# How To: Find Exe Directory in .NET

## For Single-File Apps (.NET 5+)

Use `AppContext.BaseDirectory`:

```csharp
var exeDir = AppContext.BaseDirectory;
var logDir = Path.Combine(exeDir, "logs");
```

This returns the directory containing the exe, not a temp folder.

## Why Not Use Other Methods?

| Method | Problem |
|--------|---------|
| `Assembly.GetExecutingAssembly().Location` | Returns empty string for single-file apps |
| `Environment.CurrentDirectory` | Returns working directory, not exe location |
| `Directory.GetCurrentDirectory()` | Same as above |

## When Exe Location Matters

- Log files relative to exe
- Config files next to exe
- Resource files bundled with exe

## Remember

`build.ps1` copies the exe to project root. Design paths relative to that location, not the publish folder.

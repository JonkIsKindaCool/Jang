# Jang Programming Language

Jang is a dynamically-typed scripting language implemented in Haxe, designed with simplicity and extensibility in mind. It features a custom lexer, parser, interpreter, and a standard library with built-in types and I/O functionality.

## Features

- **Dynamic Typing** – Variables can hold values of any type without explicit declaration.
- **Standard Library** – Includes built-in types: `String`, `Int`, `IO` (for input/output).
- **Custom Lexer & Parser** – Handles Jang's syntax and builds an abstract syntax tree (AST).
- **Interpreter** – Executes Jang code with support for operators, function calls, and variable scoping.
- **Extensible** – Easy to add new native functions and types via Haxe.
- **Cross-Platform** – Runs on both JavaScript (via Haxe/JS) and native targets (via Sys).

## Syntax Example

```jang
let message = "Hello, Jang!";
IO.println(message);

let num = 42;
let result = num + 8;
IO.println(result);
```

## Language Constructs

- **Variables**: `let` (mutable) and `const` (immutable)
- **Functions**: Defined with `fn name(args) { ... }`
- **Control Flow**: `while` loops
- **Operators**: Arithmetic (`+`, `-`, `*`, `/`, `%`), comparison (`==`, `!=`, `<`, `>`, `<=`, `>=`)
- **Comments**: Not yet implemented in current lexer/parser.
- **Imports**: `import module.path` (syntax supported, but module system is minimal).

## How to Run

1. **Compile with Haxe** (target example):
   ```bash
   haxe -main Main -js bin/jang.js
   ```
   or for native:
   ```bash
   haxe -main Main -cpp bin
   ```

2. **Execute**:
   - JS: `node bin/jang.js`
   - Native: Run the compiled binary.

## Example Execution Flow

```haxe
var code = 'IO.println("Hello from Jang!");';
var tokens = Lexer.tokenize(code);
var ast = new Parser().parse(tokens);
var result = new Interpreter().execute(ast);
```

## Extending Jang

To add a new built-in type:

1. Create a class extending `JangClass<T>` and `JangInstance`.
2. Implement `createInstance()` and `getVariable()`.
3. Register it in `Interpreter.GLOBALS`.

Example:
```haxe
GLOBALS["MyType"] = {
    constant: true,
    value: VClass(new MyClass()),
    type: TCustom("MyType")
};
```

## Known Limitations

- No garbage collection (relies on Haxe runtime).
- Limited error messages.
- No modules or namespaces beyond simple imports.
- No classes or objects beyond built-in types.

## License

This project is provided as-is for educational and experimental purposes. Modify and distribute as needed.

---

*Jang – A small, embeddable scripting language written in Haxe.*
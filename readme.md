# Jang

**Jang** is a small interpreted programming language written in **Haxe**,
designed for learning language implementation, scripting, and experimentation.
It features a hand-written lexer, parser, AST walker, runtime interpreter, and a
growing standard library.

The language focuses on **clarity**, **simplicity**, and **explicit runtime
behavior** rather than heavy abstractions.

---

## ✨ Features

- Interpreted, AST-walker based execution
- Static-like type annotations (checked at runtime)
- First-class functions and closures
- Classes and instances for primitives
- Custom standard library (STD)
- Clear error reporting with source locations
- Written entirely in Haxe (multi-target friendly)

---

## 🧠 Language Overview

### Variables

```jang
let x = 10;
const y = 5;
```

Optional type annotations:

```jang
let count: int = 3;
let name: string = "Jang";
```

---

### Types

Built-in types:

- `int`
- `float`
- `string`
- `boolean`
- `array`
- `object`
- `any`
- `callable`

Example:

```jang
let nums: array = [1, 2, 3];
let user: object = { name: "Alex", age: 16 };
```

---

### Functions

Functions are first-class values and support closures.

```jang
func add(a: int, b: int): int {
    return a + b;
}

print(add(2, 3));
```

Anonymous functions:

```jang
let mul = func(a, b) {
    return a * b;
};
```

---

### Control Flow

#### If / Else

```jang
if (x > 10) {
    print("big");
} else {
    print("small");
}
```

#### While Loop

```jang
let i = 0;

while (i < 5) {
    print(i);
    i += 1;
}
```

Supports `break` and `continue`.

---

### Arrays

```jang
let arr = [1, 2, 3];
print(arr[0]);

arr[1] = 10;
```

Arrays support index access through runtime methods.

---

### Objects

```jang
let obj = {
    name: "Jang",
    version: 1
};

print(obj.name);
obj.version = 2;
```

Objects are dynamic key–value maps.

---

### Classes and `new`

Primitive types are backed by classes in the STD:

```jang
let s = new String("hello");
print(s.length);
```

---

## ➕ Operators

Supported operators:

### Arithmetic

- `+` `-` `*` `/` `%`

### Comparison

- `==` `!=` `<` `<=` `>` `>=`

### Logical

- `&&` `||`

### Assignment

- `=` `+=` `-=` `*=` `/=`
- `++` `--` (postfix)

Operator behavior is type-aware and validated at runtime.

---

## 📦 Standard Library (STD)

Available globally:

### IO

```jang
IO.print("Hello");
IO.println("World");

print("Shortcut println");
```

---

### Math

```jang
print(Math.PI);
```

(Designed to be expanded with more math functions.)

---

### String

```jang
let s = new String("hello world");

print(s.length);
print(s.split(" "));
print(s.toString());
```

---

### Int

```jang
let n = new Int(10);
print(n.toString());
print(n.toBool());
```

---

### Array

```jang
let a = new Array([1, 2, 3]);
print(a.toString());
```

Supports index access and mutation.

---

### Object

```jang
let o = new Object();
o.name = "Jang";
print(o.toString());
```

---

## ⚙️ Runtime Architecture

- **Lexer** → Tokenizes source code
- **Parser** → Produces an AST (`Expr`)
- **Interpreter** → Walks AST and executes nodes
- **Scope** → Lexical scoping with closures
- **JangValue** → Unified runtime value system
- **JangClass / JangInstance** → STD-backed objects

The interpreter is fully deterministic and explicit—no hidden magic.

---

## ❌ Error Handling

Jang provides structured runtime and syntax errors with:

- Source code reference
- Line and position info
- Error type (`SYNTAX_ERROR`, `RUNTIME_ERROR`)
- Optional hints

---

## 🎯 Project Goals

- Learn how real interpreters work
- Keep the language small but expressive
- Avoid unnecessary complexity
- Make behavior explicit and debuggable
- Grow the STD organically

---

## 🚧 Status

Jang is **actively evolving**.

Planned improvements:

- More STD utilities (Array, Object, JSON, Time)
- Better short-circuit evaluation
- Improved error stack traces
- Module system improvements

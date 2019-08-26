# Monadic

The goal of this repository if to probide a set of modules to work with common monads. It is based partly on [Rust](https://www.rust-lang.org) programming language, and partly on [dry-monads](https://dry-rb.org/gems/dry-monads/) for Ruby. So far it includes:

**Monads:**

* Option

**Wrappers:**

* JSON

## Monads

### Option

```d
auto some = Some(4);
auto doubleMe = (int x) => x * 2;
auto result = some.map!doubleMe;
assert(!result.isNone());
assert(result.unwrap!int() == 8);
```

## Wrappers

### JSON

This is a wrapper on `std.json` to make querying JSONs easier. It is designed for programmers comfort, not for performance, and you should use it on schemaless JSONs. If you know the structure and want to map it into a `struct`, use `asdf`.

```d
string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
auto mjson = parseJSON(s);
auto result = mjson.dig("applications", 0, "name");
assert(!result.isNone());
assert(result.unwrap!string() == "cool programming");
assert(result == Some("cool programming"));

result = mjson.dig("applications", 1, "examples", 1);
assert(result == Some(2));

result = mjson.dig("applications", 1, "examples", "test");
assert(result.isNone());
```


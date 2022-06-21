/***********************************
 * Basic Option monad, also known as Maybe monad
 * 
 * See <a href="https://en.wikipedia.org/wiki/Option_type">Option Type</a> on Wikipedia
 */
module monadic.option;

import std.sumtype, std.variant;

class Some {
  Variant value;

  this(T)(T value) {
    this.value = value;
  }

  static Option opCall(T)(T value) {
    Option option = new Some(value);
    return option;
  }

  bool isNone() {
    return false;
  }

  unittest {
    auto some = Some(1);
    assert(some.isNone() == false);
  }

  override string toString() {
    return "Some(" ~ this.value.toString() ~ ")";
  }

  T unwrapOr(T)(T defaultValue) {
    if(this.value.convertsTo!(T)) {
      return Option(this).unwrap!T();
    } else {
      return defaultValue;
    }
  }

  alias opEquals = Object.opEquals;
  bool opEquals(Some some) {
    return this.value == some.value;
  }
}

class None {
  static Option opCall() {
    Option option = new None();
    return option;
  }

  bool isNone() {
    return true;
  }

  unittest {
    auto none = None();
    assert(none.isNone() == true);
  }

  override string toString() {
    return "None";
  }

  T throwCannotUnwrap(T)() {
    throw new CannotUnwrapNone;
  }
}

alias Option = SumType!(Some, None);

/** Exception thrown when `unwrap` is called on None */
class CannotUnwrapNone : Exception {
  this(string file = __FILE__, size_t line = __LINE__) {
    super("Cannot unwrap none", file, line);
  }
}

/** Takes a value out of Some and casts it into a T type. Raises CannotUnwrapNone
  * exception if called on None.
  * Returns: value of type T
  * Throws: CannotUnwrapNone if called on None, VariantException if cannot be casted to T
*/
T unwrap(T)(Option option) {
  return option.match!(
    (Some s) => s.value.get!(T),
    (None n) => n.throwCannotUnwrap!(T)
  );
}

///
unittest {
  auto someInt = Some(13);
  assert(someInt.unwrap!int == 13);
  assert(someInt.unwrap!long == 13);
  assert(someInt.unwrap!double == 13.0);
}

unittest {
  Option optInt = Some(13);
  assert(optInt.unwrap!int == 13);
  assert(optInt.unwrap!long == 13);
  assert(optInt.unwrap!double == 13.0);

  Option optStr = Some("abc");
  assert(optStr.unwrap!string == "abc");
}

///
unittest {
  import std.exception : assertThrown;
  import std.variant : VariantException;

  auto someStr = Some("abc");
  assertThrown!VariantException(someStr.unwrap!int());
}

///
unittest {
  import std.exception : assertThrown;

  auto none = None();
  assertThrown!CannotUnwrapNone(none.unwrap!int());
}

/** Checks if object is None.

* Returns: bool
* Example:
* ---
* None().isNone()   // => true
* Some(15).isNone() // => false
* ---
*/
bool isNone(Option option) {
  return option.match!(
    (Some s) => false,
    (None n) => true
  );
}

unittest {
  auto some = Some(1);
  assert(some.isNone() == false);
}

unittest {
  auto none = None();
  assert(none.isNone() == true);
}

/** Checks if object is None.

* Returns: bool
* Example:
* ---
* None().isNone()   // => true
* Some(15).isNone() // => false
* ---
*/
bool isSome(Option option) {
  return !isNone(option);
}

unittest {
  auto some = Some(1);
  assert(some.isSome() == true);
}

unittest {
  auto none = None();
  assert(none.isSome() == false);
}

/** Same as unwrap, but returns defaultValue if unwrap is not possible (called on None or type mismatch).
* Returns: value of type T
*/
auto unwrapOr(T)(Option option, T defaultValue) {
  return option.match!(
    (Some s) => s.unwrapOr!T(defaultValue),
    (None n) => defaultValue
  );
}

///
unittest {
  auto someInt = Some(42);
  assert(someInt.unwrapOr!string("abc") == "abc");
  assert(someInt.unwrapOr!int(15) == 42);
}

unittest {
  auto optInt = Some(42);
  assert(optInt.unwrapOr!string("abc") == "abc");
  assert(optInt.unwrapOr!int(15) == 42);
}

///
unittest {
  auto none = None();
  assert(none.unwrapOr!int(15) == 15);
}

unittest {
  auto none = Some(null);
  assert(none.unwrapOr!int(15) == 15);
}

/** Calls fun on value of Some or returns self if called on None.
* This is used to create chains of transformations, which might be stopped at any point
* when None is returned.
* Returns: Option
*/
Option map(alias fun)(Option option) {
  return option.match!(
    (Some s) => s._mapSome!fun(),
    (None _) => option
  );
}

private Option _mapSome(alias fun)(Some s) {
  import std.traits : Parameters;
  auto value = s.value.get!(Parameters!fun[0]);
  return Some(fun(value));
}

/// map on Some
unittest {
  auto some = Some(4);
  auto doubleMe = (int x) => x * 2;
  auto decrement = (int x) => x - 1;
  auto result = some.map!(doubleMe).map!(decrement);
  assert(!result.isNone());
  assert(result.unwrap!int() == 7);
}

/// map with lambda
unittest {
  auto some = Some(4);
  auto result = some.map!((int a) => a * 3);
  assert(!result.isNone());
  assert(result.unwrap!int() == 12);
}

/// map on None
unittest {
  auto none = None();
  auto doubleMe = (int x) => x * 2;
  auto decrement = (int x) => x - 1;
  auto result = none.map!(doubleMe).map!(decrement);
  assert(result.isNone());
}

bool opEquals(Option o1, Option o2) {
  if(o1.isNone == o2.isNone) return true;
  if(o1.isNone != o2.isNone) return false;
  return Some(o1) == Some(o2);
}

Option flatmap(alias fun)(Option option) {
  return option.map!(fun).match!(
    (Some s) => Option(s).unwrap!Option(),
    (None _) => option
  );
}
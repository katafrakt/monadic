/***********************************
 * Basic Option monad, also known as Maybe monad
 * 
 * See <a href="https://en.wikipedia.org/wiki/Option_type">Option Type</a> on Wikipedia
 */
module monadic.option;

import std.variant;

/***********************************
 * Interface over Some and None.
 */
class Option {
  Variant value;
  bool is_some;

  /** Wraps a value in an Option. If the value is null, returns None. Otherwise returns Some(value)
  * Returns: None or Some(value)
  */
  static auto opCall(S)(S value) {
    static if(is(typeof(value) == typeof(null))) {
      return None();
    } else {
      return Some(value);
    }
  }

  /// Wraping a value
  unittest {
    auto some = Option(1);
    assert(!some.isNone());
  }

  /// Wrapping null
  unittest {
    auto some = Option(null);
    assert(some.isNone());
  }

  /** Constructor for Option having a value (Some) */
  this(T)(T value) {
    this.value = value;
    this.is_some = true;
  }

  /** Constructor for Option without a value (None) */
  this() {
    this.is_some = false;
  }

  /** Checks if object is None.

  * Returns: bool
  * Example:
  * ---
  * None().isNone()   // => true
  * Some(15).isNone() // => false
  * ---
  */
  bool isNone() {
    return !this.is_some;
  }

  unittest {
    auto some = Some(1);
    assert(some.isNone() == false);
  }

  unittest {
    auto none = None();
    assert(none.isNone() == true);
  }

  /** Takes a value out of Some and casts it into a T type. Raises CannotUnwrapNone
   * exception if called on None.
   * Returns: value of type T
   * Throws: CannotUnwrapNone if called on None, VariantException if cannot be casted to T
  */
  T unwrap(T)() {
    if(this.is_some) {
      return this.value.get!(T);
    } else {
      throw new CannotUnwrapNone;
    }
  }

  /** Takes a value out of Some. If it's impossible to cast, returns defaultValue.
   * Always returns defaultValue for None
   * Returns: value of type T
  */

  ///
  unittest {
    auto someInt = Some(13);
    assert(someInt.unwrap!int == 13);
    assert(someInt.unwrap!long == 13);
    assert(someInt.unwrap!double == 13.0);
  }

  unittest {
    Option optInt = Option(13);
    assert(optInt.unwrap!int == 13);
    assert(optInt.unwrap!long == 13);
    assert(optInt.unwrap!double == 13.0);

    Option optStr = Option("abc");
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

  /** Same as unwrap, but returns defaultValue if unwrap is not possible (called on None or type mismatch).
  * Returns: value of type T
  */
  auto unwrapOr(T)(T defaultValue) {
    if(this.is_some) {
      if(this.value.convertsTo!(T)) {
        return this.unwrap!T();
      } else {
        return defaultValue;
      }
    } else {
      return defaultValue;
    }
  }

  ///
  unittest {
    auto someInt = Some(42);
    assert(someInt.unwrapOr!string("abc") == "abc");
    assert(someInt.unwrapOr!int(15) == 42);
  }

  unittest {
    auto optInt = Option(42);
    assert(optInt.unwrapOr!string("abc") == "abc");
    assert(optInt.unwrapOr!int(15) == 42);
  }

  ///
  unittest {
    auto none = None();
    assert(none.unwrapOr!int(15) == 15);
  }

  unittest {
    auto none = Option(null);
    assert(none.unwrapOr!int(15) == 15);
  }

  /** Calls fun on value of Some or returns self if called on None.
  * This is used to create chains of transformations, which might be stopped at any point
  * when None is returned.
  * Returns: Option
  */
  Option map(alias fun)() {
    if(this.is_some) {
      import std.traits : Parameters;
      auto value = this.value.get!(Parameters!fun[0]);
      return Some(fun(value));
    } else {
      return this;
    }
  }

  /// map on Some
  unittest {
    auto some = Some(4);
    auto doubleMe = (int x) => x * 2;
    auto result = some.map!doubleMe;
    assert(!result.isNone());
    assert(result.unwrap!int() == 8);
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
    auto result = none.map!doubleMe;
    assert(result.isNone());
  }

  Option flatmap(alias fun)() {
    if(this.is_some) {
      import std.traits : Parameters;
      auto value = this.value.get!(Parameters!fun[0]);
      return fun(value);
    } else {
      return this;
    }
  }

  /** Equality on Option.
  * None is never equal to anything.
  * Some is equal when its value is equal.
  * Returns: bool
  */
  override bool opEquals(Object o) {
    if(this.is_some) {
      auto some = cast(Option) o;
      if(some is null) { return false; }
      return this.value == some.value;
    } else {
      return false;
    }
  }

  ///
  unittest {
    auto some = Some(13);
    assert(some == Some(13));
    assert(some != Some(14));
    assert(some != Some("abc"));
    assert(some != None());
  }

  ///
  unittest {
    assert(None() != None());
  }
}

/** Represents an Option having a value (sometimes know as Just)
*/
class Some : Option {
  static Option opCall(T)(T value) {
    return new Option(value);
  }

  override string toString() {
    return "Some(" ~ this.value.toString() ~ ")";
  }
}

/** Exception thrown when trying to unwrap None
*/
class CannotUnwrapNone : Exception {
  this(string file = __FILE__, size_t line = __LINE__) {
    super("Cannot unwrap none", file, line);
  }
}

/** Represents Option without value
*/
class None : Option {
  static Option opCall() {
    return new Option();
  }
}


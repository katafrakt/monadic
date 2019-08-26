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
interface Option {
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
    assert(is(typeof(some) == Some));
    assert(!some.isNone());
  }

  /// Wrapping null
  unittest {
    auto some = Option(null);
    assert(is(typeof(some) == None));
    assert(some.isNone());
  }

  /** Checks if object is None.

  * Returns: bool
  * Example:
  * ---
  * None().isNone()   // => true
  * Some(15).isNone() // => false
  * ---
  */
  bool isNone();

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
    if(cast(Some) this) { return (cast(Some) this).unwrap!T(); }
    if(cast(None) this) { return (cast(None) this).unwrap!T(); }
    throw new Exception("Unknown subclass - do not implement Option in your own classes!");
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
    if(cast(Some) this) { return (cast(Some) this).unwrapOr!T(defaultValue); }
    return (cast(None) this).unwrapOr!T(defaultValue);
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
    if(cast(Some) this) { return (cast(Some) this).map!fun; }
    if(cast(None) this) { return (cast(None) this).map!fun; }
    throw new Exception("Unknown subclass - do not implement Option in your own classes!");
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
    if(cast(Some) this) { return (cast(Some) this).flatmap!fun; }
    if(cast(None) this) { return None(); }
    throw new Exception("Unknown subclass - do not implement Option in your own classes!");
  }

  /** Equality on Option.
  * None is never equal to anything.
  * Some is equal when its value is equal.
  * Returns: bool
  */
  bool opEquals(Object o);

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
  Variant value;

  this(T)(T value) {
    this.value = value;
  }

  static Some opCall(T)(T value) {
    return new Some(value);
  }

  bool isNone() {
    return false;
  }

  T unwrap(T)() {
    return this.value.get!(T);
  }

  auto unwrapOr(T)(T defaultValue) {
    if(this.value.convertsTo!(T)) {
      return this.unwrap!T();
    } else {
      return defaultValue;
    }
  }

  override bool opEquals(Object o) {
    auto some = cast(Some) o;
    if(some is null) { return false; }
    return this.value == some.value;
  }

  auto map(alias fun)() {
    import std.traits : Parameters;
    auto value = this.value.get!(Parameters!fun[0]);
    return Some(fun(value));
  }

  Option flatmap(alias fun)() {
    import std.traits : Parameters;
    auto value = this.value.get!(Parameters!fun[0]);
    return fun(value);
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
  static None opCall() {
    return new None();
  }

  bool isNone() {
    return true;
  }

  T unwrap(T)() {
    throw new CannotUnwrapNone;
  }

  auto unwrapOr(T)(T defaultValue) {
    return defaultValue;
  }

  override bool opEquals(Object _x) {
    return false;
  }

  auto map(alias _fun)() {
    return this;
  }
}


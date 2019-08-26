/**
* This is a wrapper on `std.json` to make querying JSONs easier. It is designed for programmers comfort, not for performance, 
* and you should use it on schemaless JSONs. If you know the structure and want to map it into a `struct`, use `asdf`.
*/
module monadic.json;

import std.json;
import std.stdio : writeln;
import monadic.option;

MonadicJSON parseJSON(string s) {
  JSONValue jv = std.json.parseJSON(s);
  return new MonadicJSON(jv);
}

/** JSON object powered by option monad when traversing
*/
class MonadicJSON {
  private JSONValue json;

  this(JSONValue j) {
    this.json = j;
  }

  /** Traverse the JSON get what's unders the list of elements
  */
  Option dig(A...)(A a) {
    Option curValue = Some(this.json);
    Option delegate(JSONValue jv) func;

    foreach(elem; a) {
      func = delegate(JSONValue jv) { return this.digElem(elem, jv); };
      
      curValue = curValue.flatmap!func;
    }

    return curValue;
  }

  ///
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.dig("applications", 0, "name");
    assert(!result.isNone());
    assert(result.unwrap!JSONValue().str == "cool programming");

    result = mjson.dig("applications", 1, "examples", 1);
    assert(result.unwrap!JSONValue().integer == 2);
  }

  /// array out of bounds
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.dig("applications", 6);
    assert(result.isNone());
  }

  ///
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.dig("applications", -1, "test", "even more", 8);
    assert(result.isNone());
  }

  ///
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.dig("applications", 1);
    assert(!result.isNone());
    assert(result.unwrap!JSONValue.type == JSONType.object);
  }

  ///
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.dig("applications");
    assert(!result.isNone());
    assert(result.unwrap!JSONValue.type == JSONType.array);
  }

  /// mismatched types
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.dig("applications", "test");
    assert(result.isNone());
  }

  ///
  unittest {
    string s = `{ "nada": null, "bools": [true, false], "float": 10.7 }`;
    auto mjson = parseJSON(s);
    auto result = mjson.dig("nada");
    assert(!result.isNone());
  }

  /**
  * The same as `dig`, but attempts to return a correct type, not JSONValue (if possible)
  */
  Option digWithCast(A...)(A a) {
    Option delegate(JSONValue jv) func;
    Option retVal = this.dig(a);
    func = delegate(JSONValue jv) { return this.unjson(jv); };
    return retVal.flatmap!func;
  }

  ///
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.digWithCast("applications", 0, "name");
    assert(!result.isNone());
    assert(result.unwrap!string() == "cool programming");
    assert(result == Some("cool programming"));

    result = mjson.digWithCast("applications", 1, "examples", 1);
    assert(result == Some(2));
  }

  /// array out of bounds
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.digWithCast("applications", 6);
    assert(result.isNone());
  }

  ///
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.digWithCast("applications", -1, "test", "even more", 8);
    assert(result.isNone());
  }

  ///
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.digWithCast("applications", 1);
    assert(!result.isNone());
    assert(result.unwrap!JSONValue.type == JSONType.object);
  }

  ///
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.digWithCast("applications");
    assert(!result.isNone());
    assert(result.unwrap!JSONValue.type == JSONType.array);
  }

  /// mismatched types
  unittest {
    string s = `{ "language": "D", "applications": [{"name": "cool programming"}, {"name": "doing stuff", "examples": [1, 2, 3]}] }`;
    auto mjson = parseJSON(s);
    auto result = mjson.digWithCast("applications", "test");
    assert(result.isNone());
  }

  ///
  unittest {
    string s = `{ "nada": null, "bools": [true, false], "float": 10.7 }`;
    auto mjson = parseJSON(s);
    auto result = mjson.digWithCast("nada");
    assert(!result.isNone());
    assert(result.unwrap!(typeof(null)) is null);

    result = mjson.digWithCast("bools", 0);
    assert(result.unwrap!bool == true);
    result = mjson.digWithCast("bools", 1);
    assert(result.unwrap!bool == false);
    result = mjson.digWithCast("float");
    assert(result.unwrap!double == 10.7);
  }

  private Option digElem(int elem, JSONValue jv) {
    if(jv.type() == JSONType.array && elem >= 0 && elem < jv.array.length) {
      return cast(Option) Some(jv.array[elem]);
    }
    return cast(Option) None();
  }

  private Option digElem(string elem, JSONValue jv) {
    
    if(jv.type() != JSONType.object) return None();

    if(elem in jv) {
      return cast(Option) Some(jv[elem]);
    }
    return cast(Option) None();
  }

  private bool hasKey(string key) {
    return !!(key in this.json);
  }

  private Some unjson(JSONValue jv) {
    switch(jv.type()) {
      case JSONType.string:
        return Some(jv.str);
      case JSONType.integer:
        return Some(jv.integer);
      case JSONType.uinteger:
        return Some(jv.uinteger);
      case JSONType.float_:
        return Some(jv.floating);
      case JSONType.true_:
        return Some(true);
      case JSONType.false_:
        return Some(false);
      case JSONType.null_:
        return Some(null);
      default:
        return Some(jv);
    }
  }
}

unittest {
  string s = `{ "language": "D", "rating": 3.5, "code": "42" }`;
  MonadicJSON j = parseJSON(s);
}
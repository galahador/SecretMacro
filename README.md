# 🚧 Still in progress 🚧
(Need to test on device with jailbreak)

# SecretMacro

Hide your API keys from `strings`. At compile time, not runtime.

Hardcoding a secret in Swift means anyone with Hopper, IDA, or a plain
`strings` call on your `.ipa` can read it in seconds. SecretMacro splits
your string into random bytes at build time and reassembles it only when
your code calls it.

```swift
let apiKey = #obfuscate("sk_live_51H8xyz...")
```

That's the whole API. `#obfuscate` takes a string literal and expands into
two byte arrays plus a `.reveal()` call. No plaintext ends up in the binary.

## Install

```swift
dependencies: [
    .package(url: "https://github.com/yourname/SecretMacro.git", from: "1.0.0")
]
```

Add `"SecretMacro"` to your target's dependencies.

## How it works

`#obfuscate("literal")` runs as a compiler plugin, not at runtime:

1. Converts the literal to UTF-8 bytes.
2. Generates a random key the same length as the string.
3. XORs them together and writes both arrays into your binary as source.

Neither array is printable text, so there's nothing for `strings` to find.
At runtime, `Obfuscated.reveal()` XORs them back together and hands you
the original `String`.

**Be honest about what this buys you.** It stops casual `strings`-and-grep
attacks. It does not stop someone actually debugging or instrumenting your
app; they can just call `reveal()` themselves. A secret worth attacking
properly belongs on your server, not in the app.

## Scanning for secrets nobody obfuscated

`SecretMacroScanTool` runs `strings` on a binary and flags likely leaked
credentials: AWS keys, JWTs, PEM private key blocks, bearer tokens, and
generic high-entropy strings. It's a safety net for secrets that never got
wrapped in `#obfuscate`.

Pure SwiftPM executable? Use the SPM plugin:

```sh
swift package secret-scan
```

Xcode app that just depends on this package via SPM (the common iOS case)?
The plugin can't see your app's `.xcodeproj` target, so it can't scan it.
Use a Run Script build phase against your real compiled binary instead:

```sh
# Build Phases → + New Run Script Phase, after "Link Binary"

if [ "$CONFIGURATION" = "Release" ]; then
  swift build -c release --package-path /path/to/SecretMacro --product SecretMacroScanTool
  /path/to/SecretMacro/.build/release/SecretMacroScanTool - "$TARGET_BUILD_DIR/$EXECUTABLE_PATH"
fi
```

This checks the binary that's actually shipping. Nonzero exit fails the build.

False positive (a license key, a hash)? Add it to `.secretmacroignore`,
one entry per line.

Detection is heuristic: pattern matching plus entropy, tuned to ignore
ordinary Swift/ObjC symbol names. It will miss formats it doesn't
recognize and can still flag legitimate random-looking strings. A clean
run means "nothing obvious," not a guarantee.

## Argument rules

The argument must be a literal the compiler can see: no interpolation, no
variables, no runtime values. Enforced at compile time:

```swift
#obfuscate(someVariable) // ❌ compile error
#obfuscate("abc\(x)")    // ❌ compile error
#obfuscate("abc")        // ✅
```

## License

MIT.

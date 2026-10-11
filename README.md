# 🚧 Still in progress 🚧
(Need to test on device with jailbreak )  

# SecretMacro

Hide your API keys from `strings`. At compile time, not runtime.

Hardcoding a secret in Swift means anyone with Hopper, IDA, or a plain
`strings` call on your `.ipa` can read it in about five seconds. SecretMacro
fixes the easy version of that problem: it splits your string into random
bytes at build time and reassembles it only when your code actually calls it.

```swift
let apiKey = #obfuscate("sk_live_51H8xyz...")
```

That's the whole API. `#obfuscate` takes a string literal and expands into
two byte arrays plus a `.reveal()` call — no plaintext left anywhere in the
binary.

## Install

```swift
dependencies: [
    .package(url: "https://github.com/yourname/SecretMacro.git", from: "1.0.0")
]
```

Then add `"SecretMacro"` to your target's dependencies.

## How it works

`#obfuscate("literal")` runs as a compiler plugin, not at runtime:

1. Converts the literal to UTF-8 bytes.
2. Generates a random key the same length as the string.
3. XORs them together and writes both arrays into your binary as source.

Neither array is printable text, so there's no contiguous readable string
for `strings` to find. At runtime, `Obfuscated.reveal()` XORs them back
together and hands you the original `String`.

**Be honest with yourself about what this buys you.** It stops someone from
casually `strings`-ing your binary and grepping for `sk_live`. It does *not*
stop someone who's actually debugging or instrumenting your app — they can
just call `reveal()` themselves. If a secret is valuable enough to attack
properly, it belongs on your server, not in the app at all.

## The build plugin

There's also an SPM command plugin that scans your built binaries for
things that look like secrets — AWS keys, JWTs, bearer tokens, private key
blocks — and fails if it finds any. Good as a CI guardrail for the secrets
nobody obfuscated.

```sh
swift package secret-scan
```

Got a long string that's a false positive (a license key, a hash, whatever)?
Add it to a `.secretmacroignore` file at your package root, one entry per
line.

## Argument rules

The argument has to be a literal the compiler can see — no interpolation,
no variables, no runtime values. This is enforced at compile time, so if
you get it wrong, you'll know immediately:

```swift
#obfuscate(someVariable) // ❌ compile error
#obfuscate("abc\(x)")    // ❌ compile error
#obfuscate("abc")        // ✅
```

## License

MIT.

# GrammarFSA

A Swift package providing a complete **Finite State Automaton** (FSA) library designed for use as a lexer in parser pipelines. It supports both Nondeterministic (NFA) and Deterministic (DFA) automata, regular expression compilation via two construction algorithms, DFA minimization, Graphviz visualization, and — currently in active development — extended state with **Token Class Tracking** for direct integration into lexer frontends.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)  
[![Platforms](https://img.shields.io/badge/platforms-macOS%2011%20%7C%20iOS%2012-blue.svg)](https://developer.apple.com/swift/)  
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)  

---

## Features

- **NFA and DFA** — first-class, type-safe representations backed by a single `State<T>` enum
- **Regular expressions** — compile regex strings to automata via Thompson's construction or Berry-Sethi's position automaton
- **Powerset (subset) construction** — determinize any NFA into an equivalent DFA
- **DFA minimization** — token-class-aware Hopcroft's algorithm (in progress)
- **Token tracking** — extended state maps final states to `TokenClass` values; designed for multi-pattern lexers
- **DAWG / trie union** — build a minimal DFA from a set of literal strings using a Directed Acyclic Word Graph
- **Alphabet intervals** — transitions carry compact character ranges, not flat character sets
- **Graphviz rendering** — every automaton exposes a `graphviz` property for DOT-format visualization
- **Random automaton generation** — `GenerateOptions`-driven NFA/DFA generators for testing and benchmarking
- **Support ADTs** — `Stack`, `Queue`, `LinkedList`, `BitArray`, and `BinarySearch` bundled in the package

---

## Quick Start

### 1 — Compile a regular expression and recognize strings

```swift
import Automaton

// Compile using Thompson's construction (default)
let re = try Regex("[a-zA-Z][a-zA-Z0-9_]*")

// Recognize a string against the NFA
print(re.recognize(string: "myVar"))    // true
print(re.recognize(string: "3bad"))    // false
```

### 2 — Work with an NFA directly

```swift
var nfa = NondeterministicFiniteState(
    initial: 0,
    finals: [2],
    transitions: [
        Transition(from: 0, AlphabetRange.char("a"), to: 1),
        Transition(from: 1, AlphabetRange.epsilon,   to: 2),
        Transition(from: 1, AlphabetRange.char("b"), to: 1),
    ]
)

print(nfa.run(string: "a"))    // true
print(nfa.run(string: "ab"))   // true
print(nfa.run(string: "b"))    // false
```

### 3 — Determinize an NFA into a DFA

```swift
nfa.determinize()   // mutates nfa.state from .nfa to .dfa
print(nfa.isDeterministic)  // true
```

### 4 — Wrap an automaton in the generic Automaton container

```swift
let regex = try Regex("(a|b)*abb")
let automaton = Automaton(regex)
print(automaton.recognize(string: "babb"))   // true
```

### 5 — Token-class tracking (extended state)

```swift
let identToken = TokenClass(id: 1, name: "IDENTIFIER", priority: 10)
let kwToken    = TokenClass(id: 2, name: "KEYWORD",    priority: 1)

// Build NFA with token map on its final states
var nfa = NondeterministicFiniteState(
    initial: 0,
    finals: [3, 5],
    transitions: [ /* ... */ ]
)
nfa.state.setTokenMap([3: identToken, 5: kwToken])

// Query which token class an input matches
if let tok = nfa.state.recognizeWithToken(string: "if") {
    print(tok.name)  // KEYWORD
}
```

### 6 — Build a minimal DFA from a word list (DAWG)

```swift
let keywords = ["if", "else", "while", "for", "return"]
let dfa = Automaton<DeterministicFiniteState>.stringUnion(words: keywords)
print(dfa.run(string: "while"))   // true
print(dfa.run(string: "whirl"))   // false
```

### 7 — Visualize with Graphviz

```swift
let re = try Regex("ab*c")
let dot = re.graphviz   // GraphViz.Graph
// Render to SVG, PNG, etc. using the GraphViz library
```

---

## Package Structure

```
Sources/Automaton/
├── Automaton.swift              # Generic Automaton<Type> container
├── AutomatonProtocol.swift      # AutomataOperation protocol (union, stringUnion)
├── Operations.swift             # Concrete union / DAWG operations
├── FSA/
│   ├── FIniteStateProtocol.swift   # FSA, Nondeterministic, Deterministic, Regular protocols + TokenClass
│   ├── DeterministicFSA.swift      # DeterministicFiniteState struct
│   ├── NondeterministicFSA.swift   # NondeterministicFiniteState struct
│   ├── State/
│   │   ├── State.swift             # Core State<T> enum — NFA/DFA + token map
│   │   ├── Invariant.swift         # Dead-state removal, reduce, zombie cleanup
│   │   └── Graphvizable.swift      # DOT/Graphviz rendering
│   ├── Transitions/
│   │   ├── AlphabetRange.swift     # .epsilon / .char / .range cases + AlphabetEpsRange
│   │   ├── Transition.swift        # Transition struct (source, range, target)
│   │   └── Alphabet.swift          # Interval-based alphabet representation
│   ├── Determinize/
│   │   └── Determinize.swift       # Powerset construction with token-map propagation
│   ├── Minimize/
│   │   └── Minimize.swift          # Token-class-aware Hopcroft minimization
│   └── Generators/
│       ├── DeterministicGenerator.swift
│       ├── NondeterministicGenerator.swift
│       ├── Options.swift
│       └── SymbolGenerator.swift
├── Regex/
│   ├── Regex.swift              # Regex struct — main entry point for pattern compilation
│   ├── RegularLanguage.swift    # RegularLanguage / RegularLanguageBuilder protocols
│   ├── RegexPowerset.swift      # Powerset construction for Regex type
│   ├── RegexRecognize.swift     # Recognition helpers
│   ├── RegexSyntaxOptions.swift # SyntaxOptions flags
│   ├── Expression.swift         # AST node types
│   ├── Construction/
│   │   ├── RegexThompson.swift      # Thompson's NFA construction
│   │   └── RegexBerrySehti.swift    # Berry-Sethi position automaton
│   └── Parsing/
│       ├── RegexParser.swift        # Recursive-descent regex parser
│       └── ParseTree.swift          # Parse tree support
├── DAWG/
│   └── TrieBuilder.swift        # Trie-to-DAWG minimization
├── ADTs/
│   ├── Stack.swift
│   ├── Queue.swift
│   ├── LinkedList.swift
│   ├── BitArray.swift
│   ├── BinarySearch.swift
│   └── Tuple.swift
└── Utils/
    ├── Array+Extensions.swift
    ├── Character+Extensions.swift
    ├── Coding+Extensions.swift
    ├── Counter.swift
    ├── Dictionary+Extensions.swift
    ├── PrettyPrint.swift
    ├── StatePair.swift
    ├── String+Extensions.swift
    └── StringProtocol+Extensions.swift
```

---

## Regex Syntax

| Construct | Syntax | Example |  
|---|---|---|  
| Literal character | `a` | `a` matches `"a"` |  
| Concatenation | `ab` | `ab` matches `"ab"` |  
| Alternation | `a\|b` | `a\|b` matches `"a"` or `"b"` |  
| Kleene star | `a*` | `a*` matches `""`, `"a"`, `"aa"`, … |  
| One or more | `a+` | `a+` matches `"a"`, `"aa"`, … |  
| Grouping | `(ab)*` | `(ab)*` matches `""`, `"ab"`, `"abab"`, … |  
| Character class | `[a-z]` | `[a-z]` matches any lowercase letter |  
| Character union | `[aeiou]` | matches any vowel |  
| Escape | `\\.` | matches a literal `.` |  

---

## Architecture Notes

The central abstraction is `State<T>`, a generic enum with two cases (`.nfa` and `.dfa`) parameterized by a phantom type `T` that constrains which protocol extensions are visible on a given instance. `NondeterministicFiniteState`, `DeterministicFiniteState`, and `Regex` each carry a `State<Self>` as their stored property and expose the full NFA or DFA API through conditional extensions.

The token tracking migration adds a `tokenMap: [Int: TokenClass]` field to both enum cases. When the powerset construction runs, it propagates the highest-priority token class from the set of NFA accepting states that map to each new DFA state — directly implementing the **longest match / maximal munch** rule used in scanner generators.

---

## Installation

### Swift Package Manager

Add the dependency to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/hakkabon/GrammarFSA.git", branch: "main"),
],
targets: [
    .target(
        name: "YourTarget", 
        dependencies: [
            .product(name: "grammar-fsa", package: "Automaton"),
        ]
    ),
]
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.  

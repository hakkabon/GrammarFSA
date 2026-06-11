//
//  Determinize.swift
//  Grammar-fsa
//
//  Created by Ulf Akerstedt-Inoue on 2026/06/11.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

// MARK: - Determinization with Token Tracking

extension State where T == NondeterministicFiniteState {
    
    /// Determinize NFA while preserving token class information
    public mutating func determinize() {
        guard case .nfa(let initial, let finals, let transitions, let tokenMap) = self else {
            return  // Already deterministic
        }
        
        // Subset construction (powerset construction)
        typealias StateSet = Set<Int>
        
        var dfaStates: [StateSet: Int] = [:]
        var dfaFinals = Set<Int>()
        var dfaTransitions = Set<Transition>()
        var dfaTokenMap: [Int: TokenClass] = [:]
        var nextDfaState = 0
        var workList: [StateSet] = []
        
        // Initial DFA state is epsilon closure of NFA initial state
        let initialClosure = epsilonClosure(Set([initial]), over: transitions)
        dfaStates[initialClosure] = nextDfaState
        let dfaInitial = nextDfaState
        nextDfaState += 1
        workList.append(initialClosure)
        
        // Check if initial state is accepting and assign token
        if let acceptingState = findHighestPriorityAcceptingState(in: initialClosure, finals: finals, tokenMap: tokenMap) {
            dfaFinals.insert(dfaInitial)
            if let token = tokenMap[acceptingState] {
                dfaTokenMap[dfaInitial] = token
            }
        }
        
        // Build DFA states
        while let nfaStateSet = workList.popLast() {
            let currentDfaState = dfaStates[nfaStateSet]!
            
            // For each symbol in alphabet
            let alphabet = transitions.alphabet().characters
            for symbol in alphabet {
                // Compute move and epsilon closure
                var nextNfaStates = Set<Int>()
                for nfaState in nfaStateSet {
                    let moves = move(state: nfaState, symbol: symbol, over: transitions)
                    nextNfaStates.formUnion(moves)
                }
                
                if nextNfaStates.isEmpty {
                    continue
                }
                
                let nextClosure = epsilonClosure(nextNfaStates, over: transitions)
                
                // Get or create DFA state for this set
                let nextDfaState: Int
                if let existing = dfaStates[nextClosure] {
                    nextDfaState = existing
                } else {
                    nextDfaState = nextDfaState
                    dfaStates[nextClosure] = nextDfaState
                    nextDfaState += 1
                    workList.append(nextClosure)
                    
                    // Check if this is an accepting state
                    if let acceptingState = findHighestPriorityAcceptingState(in: nextClosure, finals: finals, tokenMap: tokenMap) {
                        dfaFinals.insert(nextDfaState)
                        if let token = tokenMap[acceptingState] {
                            dfaTokenMap[nextDfaState] = token
                        }
                    }
                }
                
                // Add transition
                dfaTransitions.insert(Transition(
                    from: currentDfaState,
                    AlphabetRange.char(symbol),
                    to: nextDfaState
                ))
            }
        }
        
        // Update state to DFA
        self = .dfa(
            initial: dfaInitial,
            finals: dfaFinals,
            transitions: dfaTransitions,
            minimal: false,
            tokenMap: dfaTokenMap
        )
    }
    
    /// Find the accepting state with highest priority (lowest priority number) in a set
    private func findHighestPriorityAcceptingState(
        in stateSet: Set<Int>,
        finals: Set<Int>,
        tokenMap: [Int: TokenClass]
    ) -> Int? {
        let acceptingStates = stateSet.intersection(finals)
        
        return acceptingStates.min { state1, state2 in
            let priority1 = tokenMap[state1]?.priority ?? Int.max
            let priority2 = tokenMap[state2]?.priority ?? Int.max
            return priority1 < priority2
        }
    }
}

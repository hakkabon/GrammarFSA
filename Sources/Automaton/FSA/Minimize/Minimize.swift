//
//  Minimization.swift
//  Grammar-fsa
//
//  Created by Ulf Akerstedt-Inoue on 2026/02/16.
//

import Foundation

///```
/// Finite Automata (DFAs), aim to reduce the number of states while preserving the language accepted by the automaton.
/// These methods can be combined into a cohesive unit within a library or toolkit.
///
///```

extension DeterministicFiniteState {
    
    /// Minimize DFA while preserving token class distinctions
    /// States with different token classes are never merged
    public mutating func minimize() {
        guard case .dfa(let initial, let finals, let transitions, _, let tokenMap) = state else {
            return  // Only minimize DFAs
        }
        
        // Hopcroft's algorithm with token class awareness
        let allStates = Set(transitions.flatMap { [$0.source, $0.target] }).union([initial])
        let alphabet = transitions.alphabet().characters
        
        // Initial partition: separate by (accepting/non-accepting) AND token class
        var partitions: Set<Set<Int>> = []
        
        // Non-accepting states form one partition
        let nonAccepting = allStates.subtracting(finals)
        if !nonAccepting.isEmpty {
            partitions.insert(nonAccepting)
        }
        
        // Group accepting states by token class
        var tokenGroups: [TokenClass: Set<Int>] = [:]
        for finalState in finals {
            if let token = tokenMap[finalState] {
                if tokenGroups[token] == nil {
                    tokenGroups[token] = []
                }
                tokenGroups[token]!.insert(finalState)
            } else {
                // Accepting state with no token class (shouldn't happen in tagged automaton)
                // Put in separate partition
                partitions.insert([finalState])
            }
        }
        
        // Add token-based partitions
        for (_, states) in tokenGroups {
            partitions.insert(states)
        }
        
        // Refine partitions
        var workList = Array(partitions)
        
        while let splitter = workList.popLast() {
            for symbol in alphabet {
                // Find states that transition into splitter with this symbol
                var predecessors = Set<Int>()
                for state in splitter {
                    let preds = getPredecessors(of: state, with: symbol, in: transitions)
                    predecessors.formUnion(preds)
                }
                
                // Try to split each partition
                var newPartitions: Set<Set<Int>> = []
                for partition in partitions {
                    let inPredecessors = partition.intersection(predecessors)
                    let notInPredecessors = partition.subtracting(predecessors)
                    
                    if !inPredecessors.isEmpty && !notInPredecessors.isEmpty {
                        // Partition splits
                        newPartitions.insert(inPredecessors)
                        newPartitions.insert(notInPredecessors)
                        
                        // Update work list
                        if workList.contains(partition) {
                            workList.removeAll { $0 == partition }
                            workList.append(inPredecessors)
                            workList.append(notInPredecessors)
                        } else {
                            // Add smaller set to work list
                            if inPredecessors.count <= notInPredecessors.count {
                                workList.append(inPredecessors)
                            } else {
                                workList.append(notInPredecessors)
                            }
                        }
                    } else {
                        newPartitions.insert(partition)
                    }
                }
                
                partitions = newPartitions
            }
        }
        
        // Build minimized DFA
        var stateMap: [Int: Int] = [:]
        var newStateId = 0
        
        for partition in partitions {
            let representative = partition.first!
            for state in partition {
                stateMap[state] = newStateId
            }
            newStateId += 1
        }
        
        let newInitial = stateMap[initial]!
        var newFinals = Set<Int>()
        var newTransitions = Set<Transition>()
        var newTokenMap: [Int: TokenClass] = [:]
        
        // Map finals and token classes
        for finalState in finals {
            let newState = stateMap[finalState]!
            newFinals.insert(newState)
            if let token = tokenMap[finalState] {
                newTokenMap[newState] = token
            }
        }
        
        // Map transitions (avoid duplicates)
        var seenTransitions = Set<(Int, Character, Int)>()
        for transition in transitions {
            let newSource = stateMap[transition.source]!
            let newTarget = stateMap[transition.target]!
            
            if case .char(let c) = transition.range {
                let key = (newSource, c, newTarget)
                if !seenTransitions.contains(key) {
                    seenTransitions.insert(key)
                    newTransitions.insert(Transition(
                        from: newSource,
                        AlphabetRange.char(c),
                        to: newTarget
                    ))
                }
            }
        }
        
        // Update state
        state = State(
            initial: newInitial,
            finals: newFinals,
            transitions: newTransitions,
            minimal: true,
            tokenMap: newTokenMap
        )
    }
    
    // Helper: get predecessors
    private func getPredecessors(of target: Int, with symbol: Character, in transitions: Set<Transition>) -> Set<Int> {
        var result = Set<Int>()
        for transition in transitions where transition.target == target {
            if case .char(let c) = transition.range, c == symbol {
                result.insert(transition.source)
            }
        }
        return result
    }
}

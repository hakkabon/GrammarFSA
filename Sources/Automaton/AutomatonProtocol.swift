//
//  AutomatonProtocol.swift
//  Automaton
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/16.
//  Copyright © 2019 hakkabon software. All rights reserved.
//

import Foundation

/// This is Work In Progress
protocol AutomataOperation {

    /// Actual type value of the Finite State Automaton.
    associatedtype Subtype

    // static functions 
    static func union(a: Automaton<Subtype>, b: Automaton<Subtype>) -> Automaton<Subtype>
    static func union(list: [Automaton<Subtype>]) -> Automaton<Subtype>

    // Directed Acyclic Word Graph - DAWG interface
    static func stringUnion(words: [String]) -> Automaton<Subtype>
}

//
//  Operators.swift
//  SwiftSTM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

precedencegroup ReferencePrecedence {
    lowerThan: ComparisonPrecedence
    higherThan: AssignmentPrecedence
}

infix operator =| : ReferencePrecedence

@discardableResult public func =|<V>(lhs: inout Ref<V>, rhs: Ref<V>) throws -> Ref<V> {
    try lhs.set(rhs.get())
    return lhs
}

public func <<V: Comparable>(lhs: Ref<V>, rhs: Ref<V>) throws -> Bool {
    return try lhs.get() < rhs.get()
}

public func <<V: Comparable>(lhs: V, rhs: Ref<V>) throws -> Bool {
    return try lhs < rhs.get()
}

public func <<V: Comparable>(lhs: Ref<V>, rhs: V) throws -> Bool {
    return try lhs.get() < rhs
}

public func <=<V: Comparable>(lhs: Ref<V>, rhs: Ref<V>) throws -> Bool {
    return try lhs.get() <= rhs.get()
}

public func <=<V: Comparable>(lhs: V, rhs: Ref<V>) throws -> Bool {
    return try lhs <= rhs.get()
}

public func <=<V: Comparable>(lhs: Ref<V>, rhs: V) throws -> Bool {
    return try lhs.get() <= rhs
}

public func ==<V: Comparable>(lhs: Ref<V>, rhs: Ref<V>) throws -> Bool {
    return try lhs.get() == rhs.get()
}

public func ==<V: Comparable>(lhs: V, rhs: Ref<V>) throws -> Bool {
    return try lhs == rhs.get()
}

public func ==<V: Comparable>(lhs: Ref<V>, rhs: V) throws -> Bool {
    return try lhs.get() == rhs
}

public func >=<V: Comparable>(lhs: Ref<V>, rhs: Ref<V>) throws -> Bool {
    return try lhs.get() >= rhs.get()
}

public func >=<V: Comparable>(lhs: V, rhs: Ref<V>) throws -> Bool {
    return try lhs >= rhs.get()
}

public func >=<V: Comparable>(lhs: Ref<V>, rhs: V) throws -> Bool {
    return try lhs.get() >= rhs
}

public func ><V: Comparable>(lhs: Ref<V>, rhs: Ref<V>) throws -> Bool {
    return try lhs.get() > rhs.get()
}

public func ><V: Comparable>(lhs: V, rhs: Ref<V>) throws -> Bool {
    return try lhs > rhs.get()
}

public func ><V: Comparable>(lhs: Ref<V>, rhs: V) throws -> Bool {
    return try lhs.get() > rhs
}

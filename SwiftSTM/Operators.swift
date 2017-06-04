//
//  Operators.swift
//  SwiftSTM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

infix operator =| : ReferencePriorityPrecedence

@discardableResult public func =|<V>(lhs: inout Ref<V>, rhs: Ref<V>) -> Ref<V> {
    lhs.set(rhs.get())
    return lhs
}

public func <<V: Comparable>(lhs: Ref<V>, rhs: Ref<V>) -> Bool {
    return lhs.get() < rhs.get()
}

public func <<V: Comparable>(lhs: V, rhs: Ref<V>) -> Bool {
    return lhs < rhs.get()
}

public func <<V: Comparable>(lhs: Ref<V>, rhs: V) -> Bool {
    return lhs.get() < rhs
}

public func <=<V: Comparable>(lhs: Ref<V>, rhs: Ref<V>) -> Bool {
    return lhs.get() <= rhs.get()
}

public func <=<V: Comparable>(lhs: V, rhs: Ref<V>) -> Bool {
    return lhs <= rhs.get()
}

public func <=<V: Comparable>(lhs: Ref<V>, rhs: V) -> Bool {
    return lhs.get() <= rhs
}

public func ==<V: Comparable>(lhs: Ref<V>, rhs: Ref<V>) -> Bool {
    return lhs.get() == rhs.get()
}

public func ==<V: Comparable>(lhs: V, rhs: Ref<V>) -> Bool {
    return lhs == rhs.get()
}

public func ==<V: Comparable>(lhs: Ref<V>, rhs: V) -> Bool {
    return lhs.get() == rhs
}

public func >=<V: Comparable>(lhs: Ref<V>, rhs: Ref<V>) -> Bool {
    return lhs.get() >= rhs.get()
}

public func >=<V: Comparable>(lhs: V, rhs: Ref<V>) -> Bool {
    return lhs >= rhs.get()
}

public func >=<V: Comparable>(lhs: Ref<V>, rhs: V) -> Bool {
    return lhs.get() >= rhs
}

public func ><V: Comparable>(lhs: Ref<V>, rhs: Ref<V>) -> Bool {
    return lhs.get() > rhs.get()
}

public func ><V: Comparable>(lhs: V, rhs: Ref<V>) -> Bool {
    return lhs > rhs.get()
}

public func ><V: Comparable>(lhs: Ref<V>, rhs: V) -> Bool {
    return lhs.get() > rhs
}

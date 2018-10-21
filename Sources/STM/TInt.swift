//
//  TInt.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

public typealias TInt = Ref<Int>

public func +(lhs: Ref<Int>, rhs: Ref<Int>) -> Ref<Int> {
    return Ref(lhs.get() + rhs.get())
}

public func +(lhs: Int, rhs: Ref<Int>) -> Ref<Int> {
    return Ref(lhs + rhs.get())
}

public func +(lhs: Ref<Int>, rhs: Int) -> Ref<Int> {
    return Ref(lhs.get() + rhs)
}

public func -(lhs: Ref<Int>, rhs: Ref<Int>) -> Ref<Int> {
    return Ref(lhs.get() - rhs.get())
}

public func -(lhs: Int, rhs: Ref<Int>) -> Ref<Int> {
    return Ref(lhs - rhs.get())
}

public func -(lhs: Ref<Int>, rhs: Int) -> Ref<Int> {
    return Ref(lhs.get() - rhs)
}

public func +(lhs: Ref<Int>, rhs: Ref<Int>) -> Int {
    return lhs.get() + rhs.get()
}

public func +(lhs: Int, rhs: Ref<Int>) -> Int {
    return lhs + rhs.get()
}

public func +(lhs: Ref<Int>, rhs: Int) -> Int {
    return lhs.get() + rhs
}

public func -(lhs: Ref<Int>, rhs: Ref<Int>) -> Int {
    return lhs.get() - rhs.get()
}

public func -(lhs: Int, rhs: Ref<Int>) -> Int {
    return lhs - rhs.get()
}

public func -(lhs: Ref<Int>, rhs: Int) -> Int {
    return lhs.get() - rhs
}

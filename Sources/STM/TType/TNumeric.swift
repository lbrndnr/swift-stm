//
//  TNumeric.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

public typealias TInt = Ref<Int>
public typealias TFloat = Ref<Float>

public func +<T: Numeric>(lhs: Ref<T>, rhs: Ref<T>) -> Ref<T> {
    return Ref(lhs.get() + rhs.get())
}

public func +<T: Numeric>(lhs: T, rhs: Ref<T>) -> Ref<T> {
    return Ref(lhs + rhs.get())
}

public func +<T: Numeric>(lhs: Ref<T>, rhs: T) -> Ref<T> {
    return Ref(lhs.get() + rhs)
}

public func -<T: Numeric>(lhs: Ref<T>, rhs: Ref<T>) -> Ref<T> {
    return Ref(lhs.get() - rhs.get())
}

public func -<T: Numeric>(lhs: T, rhs: Ref<T>) -> Ref<T> {
    return Ref(lhs - rhs.get())
}

public func -<T: Numeric>(lhs: Ref<T>, rhs: T) -> Ref<T> {
    return Ref(lhs.get() - rhs)
}

public func +<T: Numeric>(lhs: Ref<T>, rhs: Ref<T>) -> T {
    return lhs.get() + rhs.get()
}

public func +<T: Numeric>(lhs: T, rhs: Ref<T>) -> T {
    return lhs + rhs.get()
}

public func +<T: Numeric>(lhs: Ref<T>, rhs: T) -> T {
    return lhs.get() + rhs
}

public func -<T: Numeric>(lhs: Ref<T>, rhs: Ref<T>) -> T {
    return lhs.get() - rhs.get()
}

public func -<T: Numeric>(lhs: T, rhs: Ref<T>) -> T {
    return lhs - rhs.get()
}

public func -<T: Numeric>(lhs: Ref<T>, rhs: T) -> T {
    return lhs.get() - rhs
}

//
//  TNumeric.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

public typealias TInt = Ref<Int>
public typealias TInt8 = Ref<Int8>
public typealias TInt16 = Ref<Int16>
public typealias TInt32 = Ref<Int32>
public typealias TInt64 = Ref<Int64>
public typealias TUInt8 = Ref<UInt8>
public typealias TUInt16 = Ref<UInt16>
public typealias TUInt32 = Ref<UInt32>
public typealias TUInt64 = Ref<UInt64>

public typealias TFloat = Ref<Float>
public typealias TDouble = Ref<Double>

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

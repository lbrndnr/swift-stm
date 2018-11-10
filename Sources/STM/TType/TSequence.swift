//
//  TSequence.swift
//  STM
//
//  Created by Laurin Brandner on 10.11.18.
//

import Foundation

public typealias TArray<E> = Ref<Array<E>>

extension Reference: Sequence where Value: Sequence {
    
    public typealias Element = Value.Element
    public typealias Iterator = Value.Iterator
    
    
    public func makeIterator() -> Value.Iterator {
        return get().makeIterator()
    }
    
}

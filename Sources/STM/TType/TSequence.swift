//
//  TSequence.swift
//  STM
//
//  Created by Laurin Brandner on 10.11.18.
//

import Foundation

public typealias TArray<E> = Ref<Array<E>>
public typealias TSet<E> = Ref<Set<E>> where E: Hashable
public typealias TDictionary<K, E> = Ref<Dictionary<K, E>> where K: Hashable, E: Hashable

extension Reference: Sequence where Value: Sequence {
    
    public typealias Element = Value.Element
    public typealias Iterator = Value.Iterator
    
    public func makeIterator() -> Iterator {
        return get().makeIterator()
    }
    
}

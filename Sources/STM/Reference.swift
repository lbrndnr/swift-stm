//
//  Reference.swift
//  STM
//
//  Created by Laurin Brandner on 29.05.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//
import Foundation
import Atomics
import AtomicLinkedList

protocol Referenceable: AnyObject {
    
    func commit()
    func reset(reads: Bool, writes: Bool)
    
}

public typealias Ref<V> = Reference<V>

public final class Reference<V> : Referenceable {
    
    var signature = Signature()
    
    private var value: V
    
    private var barrier: Barrier {
        return Thread.current.barrier!
    }
    
    private var readers = AtomicLinkedList<Barrier>()
    private var writers = AtomicLinkedList<Barrier>()
    
    // MARK: - Initialization
    
    public init(_ v: V) {
        value = v
        signature.reference = self
    }
    
    // MARK: -
    
    public func get() -> V {
        if !barrier.isReading(signature) {
            readers.append(barrier)
        }
        
        return barrier.read(signature) as? V ?? value
    }
    
    public func set(_ newValue: V) {
        if !barrier.isWriting(signature) {
            writers.append(barrier)
        }
        
        barrier.write(newValue, to: signature)
    }
    
    func commit() {
        guard let newValue = barrier.read(signature) as? V? else {
            abort()
        }
            
        value = newValue!
        reset(reads: true, writes: true)
    }
    
    func reset(reads: Bool, writes: Bool) {
        if reads && barrier.isReading(signature) {
            readers.remove(barrier)
        }
        if writes && barrier.isWriting(signature) {
            writers.remove(barrier)
        }
    }
        
}

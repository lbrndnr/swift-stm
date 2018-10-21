//
//  AccessQueue.swift
//  STM
//
//  Created by Laurin Brandner on 15.10.18.
//

import Foundation
import Atomics

class Element {
    
    var barrier: Barrier
    var next = AtomicPointer<Element>()
    
    init(barrier b: Barrier) {
        barrier = b
    }
    
}

class AccessQueue {
    
    private var head: AtomicPointer<Element>
    private var tail: AtomicPointer<Element>
    
    var isEmpty: Bool {
        return (head.pointer == nil)
    }
    
    // MARK: - Initialization
    
    init() {
        head = AtomicPointer<Element>()
        tail = head
    }
    
    // Mark: - Access
    
    func append(barrier: Barrier) {
        let newTail = Element(barrier: barrier)
        withUnsafePointer(to: newTail) { newTailPointer in
            var pointer = isEmpty ? tail : tail.pointer!.pointee.next
            while pointer.CAS(current: nil, future: newTailPointer) {}
            tail = pointer
        }
    }
    
    func pop() -> Barrier? {
        guard let pointer = head.pointer else {
            return nil
        }
        
        while head.CAS(current: pointer, future: pointer.pointee.next.pointer) {}
        
        return pointer.pointee.barrier
    }
    
    func remove(barrier: Barrier) {
        var elem = head
        if let elemBarrier = elem.pointer?.pointee.barrier, elemBarrier.identifier == barrier.identifier {
            head = elem.pointer?.pointee.next ?? AtomicPointer<Element>()
            return
        }
        
        while let next = elem.pointer?.pointee.next {
            var previous = elem
            elem = next
            if let elemBarrier = elem.pointer?.pointee.barrier, elemBarrier.identifier != barrier.identifier {
                previous.pointer?.pointee.next = elem.pointer?.pointee.next ?? AtomicPointer<Element>()
                return
            }
        }
    }
    
    func contains(notEqual barrier: Barrier) -> Barrier? {
        var elem = head
        if let elemBarrier = elem.pointer?.pointee.barrier, elemBarrier.identifier != barrier.identifier {
            return elemBarrier
        }

        while let next = elem.pointer?.pointee.next {
            elem = next
            if let elemBarrier = elem.pointer?.pointee.barrier, elemBarrier.identifier != barrier.identifier {
                return elemBarrier
            }
        }
        
        return nil
    }
    
}

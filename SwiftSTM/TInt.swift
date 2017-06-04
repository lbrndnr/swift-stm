//
//  TInt.swift
//  SwiftSTM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

public typealias TInt = Ref<Int>

//@discardableResult public func =|(lhs: inout Ref<Int>, rhs: Int) -> Ref<Int> {
//    lhs.set(rhs)
//    return lhs
//}
//
//public func +(lhs: Ref<Int>, rhs: Ref<Int>) -> Ref<Int> {
//    return Ref(lhs.get() + rhs.get())
//}
//
//public func +(lhs: Int, rhs: Ref<Int>) -> Ref<Int> {
//    return Ref(lhs + rhs.get())
//}
//
//public func +(lhs: Ref<Int>, rhs: Int) -> Ref<Int> {
//    return Ref(lhs.get() + rhs)
//}
//
//public func -(lhs: Ref<Int>, rhs: Ref<Int>) -> Ref<Int> {
//    return Ref(lhs.get() - rhs.get())
//}
//
//public func -(lhs: Int, rhs: Ref<Int>) -> Ref<Int> {
//    return Ref(lhs - rhs.get())
//}
//
//public func -(lhs: Ref<Int>, rhs: Int) -> Ref<Int> {
//    return Ref(lhs.get() - rhs)
//}

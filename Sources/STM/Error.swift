//
//  Error.swift
//  STM
//
//  Created by Laurin Brandner on 04.06.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import Foundation

enum TransactionError: Error {
    case collision
    case aborted
    case noBarrier
    case overflow
}
//
//  Backgroundable+Operation.swift
//  Example
//
//  Created by André Campana on 02/08/2020.
//  Copyright © 2020 Bell App Lab. All rights reserved.
//

import Foundation


@nonobjc
extension Operation {
    /**
     Compares two `Operation`s and returns the one which should be cancelled.

     - parameters:
        - operation: The second operation to be compared to the receiver.

     - returns:
        - The operation that should be cancelled between the received and the other operation, according to the receiver's `uniquenessPolicy` flag. If the receiver is not an instance of `AsyncOperation`, `nil` is returned.

     ## See Also:
     - `AsyncOperationUniquenessPolicy`
     */
    func operationToCancel(_ operation: Operation) -> Operation?
    {
        guard let policy = (self as? AsyncOperation)?.uniquenessPolicy else { return nil }
        guard let name = name, let otherName = operation.name, name == otherName else { return nil }
        guard isFinished == false, operation.isFinished == false else { return nil }
        guard isCancelled == false, operation.isCancelled == false else { return nil }
        guard isExecuting == false else { return nil }

        switch policy {
        case .drop, .ignore: return nil
        case .replace: return operation
        }
    }

    /**
    Compares two `Operation`s and returns the one which should be added to a queue.

    - parameters:
       - operation: The second operation to be compared to the receiver.

    - returns:
       - The operation that should be added between the received and the other operation, according to the receiver's `uniquenessPolicy` flag. If the receiver is not an instance of `AsyncOperation`, `self` is returned.

    ## See Also:
    - `AsyncOperationUniquenessPolicy`
    */
    func operationToAdd(_ operation: Operation) -> Operation?
    {
        guard let policy = (self as? AsyncOperation)?.uniquenessPolicy else { return self }
        guard let name = name, let otherName = operation.name, name == otherName else { return self }
        guard isFinished == false else { return nil }
        guard operation.isFinished == false else { return self }
        guard isCancelled == false else { return nil }
        guard operation.isCancelled == false else { return self }
        guard isExecuting == false else { return nil }


        switch policy {
        case .drop, .ignore: return nil
        case .replace: return self
        }
    }
}

import UIKit

// MARK: Style guide for functions with closure parameters

// Literal translation
func fetchImageWithSuccess(successBlock : (UIImage! -> ())!, failure failureBlock : (NSError! -> ())!) {}

// Better clarity and usability
func fetchImage(failure fail : (NSError -> ())? = nil, success succeed: (UIImage -> ())? = nil) {
    print("Hello")
}

// MARK: Parameter order

class SuccessFirst {

    func fetchImage(success succeed: (UIImage -> ())? = nil, failure fail : (NSError -> ())? = nil) {}
    
}

// Success first
SuccessFirst().fetchImage(success: { image in
    // Success
}) { error in
    // Failure
}

// Failure first
fetchImage(failure: { error in
    // Failure
}) { image in
    // Success
}

// Failure first, default failure
fetchImage { image in
    // Success
}

// MARK: Default values

// Default success
fetchImage(failure: { error in
    // Failure
})

// Default failure
fetchImage { image in
    // Success
}

// Default failure and success
fetchImage()

class EmptyClosureDefault {
    
func fetchImage(success succeed: UIImage -> () = { image in }, failure fail : NSError -> () = {error in }) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
        let didSucceed = self.expensiveWorkWithoutSideEffects()
        dispatch_async(dispatch_get_main_queue()) {
            if didSucceed {
                succeed(UIImage())
            } else {
                fail(NSError())
            }
        }
    }
}
    
    func expensiveWorkWithoutSideEffects() -> Bool { return true }
    
}

class NilClosureDefault {
    
func fetchImage(failure fail : (NSError -> ())? = nil, success succeed: (UIImage -> ())? = nil) {
    if fail == nil && succeed == nil { return }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
        let didSucceed = self.expensiveWorkWithoutSideEffects()
        if didSucceed {
            if let succeed = succeed {
                dispatch_async(dispatch_get_main_queue()) {
                    succeed(UIImage())
                }
            }
        } else if let fail = fail {
            dispatch_async(dispatch_get_main_queue()) {
                fail(NSError())
            }
        }
    }
}
    
    func expensiveWorkWithoutSideEffects() -> Bool { return true }
    
}

// MARK: Function name

class LegacyNaming {
    func fetchImageWithFailure(failure fail : (NSError -> ())? = nil, success succeed: (UIImage -> ())? = nil) {
        print("Legacy naming")
    }
}

LegacyNaming().fetchImageWithFailure(success: { image in
    // Success?
})

LegacyNaming().fetchImageWithFailure { image in
    // Success?
}


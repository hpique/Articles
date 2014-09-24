import UIKit

// MARK: Style guide for functions with closure parameters

// Literal translation
func fetchImageWithSuccess(successBlock : (UIImage! -> ())!, failure failureBlock : (NSError! -> ())!) {}

// Better clarity and usability
func fetchImage(failure doFailure : (NSError -> ())? = nil, success doSuccess: (UIImage -> ())? = nil) {
    print("Hello")
}

// MARK: Parameter order

class SuccessFirst {

    func fetchImage(success doSuccess: (UIImage -> ())? = nil, failure doFailure : (NSError -> ())? = nil) {}
    
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
    
func fetchImage(success doSuccess: UIImage -> () = { image in }, failure doFailure : NSError -> () = {error in }) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
        let didSucceed = self.expensiveWorkWithoutSideEffects()
        dispatch_async(dispatch_get_main_queue()) {
            if didSucceed {
                doSuccess(UIImage())
            } else {
                doFailure(NSError())
            }
        }
    }
}
    
    func expensiveWorkWithoutSideEffects() -> Bool { return true }
    
}

class NilClosureDefault {
    
func fetchImage(failure doFailure : (NSError -> ())? = nil, success doSuccess: (UIImage -> ())? = nil) {
    if doFailure == nil && doSuccess == nil { return }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
        let didSucceed = self.expensiveWorkWithoutSideEffects()
        if didSucceed {
            if let doSuccess = doSuccess {
                dispatch_async(dispatch_get_main_queue()) {
                    doSuccess(UIImage())
                }
            }
        } else if let doFailure = doFailure {
            dispatch_async(dispatch_get_main_queue()) {
                doFailure(NSError())
            }
        }
    }
}
    
    func expensiveWorkWithoutSideEffects() -> Bool { return true }
    
}

// MARK: Function name

class LegacyNaming {
    func fetchImageWithFailure(failure doFailure : (NSError -> ())? = nil, success doSuccess: (UIImage -> ())? = nil) {
        print("Legacy naming")
    }
}

LegacyNaming().fetchImageWithFailure(success: { image in
    // Success?
})

LegacyNaming().fetchImageWithFailure { image in
    // Success?
}


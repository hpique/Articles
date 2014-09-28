import UIKit

// MARK: Style guide for functions with closure parameters

// Literal translation
func fetchImageWithSuccess(successBlock : (UIImage! -> ())!, failure failureBlock : (NSError! -> ())!) {}

// Better clarity and usability
func fetchImage(failure fail : (NSError -> ())? = nil, success succeed: (UIImage -> ())? = nil) {
    println("Hello")
}

// MARK: Parameter order

class SuccessFirst {

    func fetchImage(success succeed: (UIImage -> ())? = nil, failure fail : (NSError -> ())? = nil) {}
    
}

let example1 = SuccessFirst()

// Success first
example1.fetchImage(success: { image in
    // Success
}) { error in
    // Failure
}

// Success first, default success.
example1.fetchImage { _ in
    // Is this success or failure?
    // If we declared the success closure first, this is the failure closure!
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

// When using extra parameters trailing closures doesn't work as expected.
// This appears to be a Swift compiler bug.

class SuccessLastWithExtraParameter {
    
    func fetchImage(retry : Bool = true, failure fail : (NSError -> ())? = nil, success succeed: (UIImage -> ())? = nil) {
        println("Extra paramater")
    }
    
}

let example2 = SuccessLastWithExtraParameter()

// Doesn't compile! Swift bug?
/* example2.fetchImage { image in
    // Success
} */

example2.fetchImage(failure:nil) { image in
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
        println("Legacy naming")
    }
}

let example3 = LegacyNaming()

example3.fetchImageWithFailure(success: { _ in
    // Success
    // Though you might think otherwise if you read it quickly.
})

example3.fetchImageWithFailure { _ in
    // Success or failure?
    // It's success.
}

// MARK: Method chaining

class MethodChainig {
    
    func fetchImage() -> Fetch<UIImage> {
        let fetch = Fetch<UIImage>()
        return fetch
    }
    
}

class Fetch<T> {
    
    func onSuccess(succeed : T -> ()) -> Self {
        return self
    }
    
    func onFailure(fail : NSError? -> ()) -> Self {
        return self
    }
}

let example4 = MethodChainig()

example4.fetchImage().onSuccess { image in
    // Success
}

example4.fetchImage().onFailure { error in
    // Failure
}.onSuccess { image in
    // Success
}


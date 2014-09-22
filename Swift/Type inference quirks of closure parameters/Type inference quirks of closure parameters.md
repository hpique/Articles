#Type inference quirks of closures as parameters

Swift can infer the type of closures when used as parameters. As shown in the official Swift [documentation](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html#//apple_ref/doc/uid/TP40014097-CH11-XID_152), this means that we don't need to write code like this:

```Swift
let reversed = sorted(names) { (s1: String, s2: String) -> Bool in
    return s1 > s2
}
```

Instead, we can simply write:

```Swift
let reversed = sorted(names) { s1, s2 in
    return s1 > s2
}
```

Because single-expression closures can implicitly return the value of the expression, the code above can be shortened to:

```Swift
let reversed = sorted(names) { s1, s2 in
    s1 > s2
}
```

Or even more succintly by using shorthand argument names:

```Swift
let reversed = sorted(names) { $0 > $1 }
```

So far so good. However, the documentation leaves out some cases in which Swift fails to infer the closure type properly (as of Xcode 6.0). During the development of [Haneke](https://github.com/Haneke/HanekeSwift) we discovered the two below. You can follow along the code examples with [this playground](https://github.com/hpique/Articles/tree/master/Swift/Type%20inference%20quirks%20of%20closure%20parameters/Type%20inference%20quirks%20of%20closure%20parameters.playground).

## Quirk 1: Single-expression closures with unused return value

The first involves single-expression closures. Say we want to set the modification date of a file in background, without much care for errors. Intuitively, we would write something like this:

```Swift
dispatch_async(someBackgroundQueue) {
    NSFileManager.defaultManager().setAttributes([NSFileModificationDate : someDate], ofItemAtPath: path, error: nil)
}
```

Unfortunately the above code fails to compile with error `Cannot convert the expression's type '(dispatch_queue_t!, () -> () -> $T5)' to type 'Bool'`.

The reason is that `NSFileManager.setAttributes` returns a `Bool`, and because the closure has a single-expression, the Swift compiler mistakenly infers that its return type is `Bool`. 

The workaround? We guide the Swift compiler by ignoring the result value with an underscore:

```Swift
dispatch_async(someBackgroundQueue) {
    let _ = NSFileManager.defaultManager().setAttributes([NSFileModificationDate : someDate], ofItemAtPath: path, error: nil)
}
```

##Quirk 2: Unused parameters in closures

Another quirk involves unused parameters in closures. Consider a function that fetches some data and can succeed or fail.

```Swift
func fetchDataWithSuccess(success doSuccess : (NSData) -> (), failure doFailure : ((NSError?) -> ()))
```

When writing unit tests for this function we should test both the success case and the failure case. For the failure case, we should fail the test if the success closure gets called. The test could look something like this:

```Swift
func testFailure() {
    // Simulate a failure condition

    let expectation = self.expectationWithDescription("fetch")
    fetchDataWithSuccess(success: {
        XCTFail("expected failure")
        expectation.fulfill()
    }, failure : { e in
        XCTAssertNotNil(e)
        expectation.fulfill()
    })
    self.waitForExpectationsWithTimeout(1, handler: nil)
}
```

Surprisingly this doesn't compile. The error message is not very helpful: `'NSData' is not a subtype of '()'`.

The problem lies in the unused parameter of the success block. The Swift compiler assumes that the success closure does not have any parameters, and fails to match this with the expected type of the success closure.

What to do? Again the amazing underscore comes to our rescue:

```Swift
func testFailure() {
    // Simulate a failure condition

    let expectation = self.expectationWithDescription("fetch")
    fetchDataWithSuccess(success: {let _ in
        XCTFail("expected failure")
        expectation.fulfill()
    }, failure : { e in
        XCTAssertNotNil(e)
        expectation.fulfill()
    })
    self.waitForExpectationsWithTimeout(1, handler: nil)
}
```

Telling Swift that the success closure has a parameter, even if we ignore it, is enough help to let it infer the type correctly.

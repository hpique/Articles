# Style guide for functions with closure parameters in Swift

Methods with success and failure block parameters are fairly common in Objective-C. Take this method from [Haneke for Objective-C](https://github.com/Haneke/Haneke/) as an example:

```objective-c
- (void)fetchImageWithSuccess:(void (^)(UIImage *image))successBlock 
                      failure:(void (^)(NSError *error))failureBlock;
```

A literal translation of the above signature in Swift would be:

```swift
func fetchImageWithSuccess(successBlock : (UIImage! -> ())!, 
                           failure failureBlock : (NSError! -> ())!)
```

In Swift blocks are closures and methods are functions, and the latter offer features such as default values and trailing closures. This article is an attempt to leverage these new features to improve clarity and simplify usage of functions with closures. Here's how we could improve the previous translation:

```swift
func fetchImage(failure fail : (NSError -> ())? = nil, 
                success succeed: (UIImage -> ())? = nil) {}
```

Let's examine the changes one by one and finish with a [style guide](#style-guide). I highly recommend following along with this [playground](https://github.com/hpique/Articles/tree/master/Swift/Style%20guide%20for%20functions%20with%20closure%20parameters/Style%20guide%20for%20functions%20with%20closure%20parameters.playground).

## Parameter order

You might have noticed that the order of the parameters has been inverted, with the success closure last. This is to take advantage of trailing closures.

> A trailing closure is a closure expression that is written outside of (and after) the parentheses of the function call it supports.

If the order remained like in the literal translation, the trailing closure would be the failure closure. This would result in code like this:

```swift
fetchImage(success: { image in
    // Success
}) { error in
    // Failure
}
```

If the success closure has a default value, we can even write misleading code like:

```swift
fetchImage { _ in
    // Is this success or failure? 
    // If we declared the success closure first, this is the failure closure!
}
```

Trailing closures have no associated semantics. Yet, one could expect developers to pay special attention to trailing closures, perhaps as a side effect of using them with functions such as `map` or `sort`. I would go so far to say that the _trailing closure is the main closure of a function_. If so, do we want developers to be focusing on the failure closure?

Let's look at how our function could be called if we put the success closure last.

```swift
fetchImage(failure: { error in
    // Failure
}) { image in
    // Success
}
```

Wether the above call is better than the previous is up to personal taste. However, if we get slightly ahead and use the default failure value, it becomes clear why the success closure should be last.

```swift
fetchImage { image in
    // Success
}
```

This call is undisputedly short and clear. The only way to be able to use the function like this is to let the success closure be the trailing closure. 

### Swift compiler limitations

There are some compiler limitations for trailing closures in functions with additional parameters. To illustrate, let's add one parameter to the `fetch` function:

```swift
func fetchImage(retry : Bool = true, failure fail : (NSError -> ())? = nil, success succeed: (UIImage -> ())? = nil) {}
```

Given that all parameters have default values, one would expect the following to be valid Swift.

```swift
fetchImage { image in
    // Success
}
```

However, as of Xcode 6.1 Beta 2, the above code fails to compile with the rather unhelpful error: `cannot convert the expression's type '(($T3) -> ($T3) -> $T2) -> (($T3) -> $T2) -> $T2' to type '(retry: Bool, failure: (NSError -> ())?, success: (UIImage -> ())?) -> ()'`.

A workaround is to explictly add the other closure.

```swift
fetchImage(failure:nil) { image in
    // Success
}
```

## Default values

Providing a success and failure closure is verbose, and not always required by the function user. She might only care about the success case. When writing unit tests, the success case might be ignored altogether. Or neither closure might be needed if the function has side-effects or returns a value.

In Objective-C we could always set the block parameter to `nil`. In Swift, we might be able to do it or not depending on if the closure parameter has been marked as optional. A better approach is to _always provide a default value for closure parameters_.

The are two clear options for default values of closure parameters. An empty closure or `nil`. No matter which one we use, the calls would look like this:

```swift
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
```

### Empty closures as default value

Empty closures are the most intuitive default value for a closure parameter. The function signature would look like this:

```swift
func fetchImage(success succeed: UIImage -> () = { image in }, failure fail : NSError -> () = {error in })
```

The work of the function developer couldn't be easier. If the function user doesn't specify a closure, then we do nothing by calling a closure that does nothing. The function implementation is the same no matter if the function user provides values or not.

Yet, there are some cases in which this might not be desirable. Consider this implementation for `fetchImage`.

```swift
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
```

The above implementation does some background work and then calls the success or failure closure in the main queue accordingly. Note that if the function user doesn't provide closures, we're making the function do all this work for nothing. 

If avoiding this matters then we must use `nil` as a default instead.

### `nil` as default value

Using `nil` as default value looks like this:

```swift
func fetchImage(failure fail : (NSError -> ())? = nil, success succeed: (UIImage -> ())? = nil)
```

In this case the work of the function developer is slightly more complicated and error prone. The closures are now optional, so she must check if they have a value before calling them. 

Returning to our previous example, this is how the implementation would look like if we wanted the function to do as litte work as possible.

```swift
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
```

This implementation does nothing if both closures are `nil`. It also avoids the main queue dispatch after the background work if the one to be called is `nil`.

_When performance is a concern, better to use `nil` as a default value._

## Method name

In Objective-C the method name acts as the external name of the first parameter because said first parameter doesn't have an external name. This is why the Objective-C version of our function is called `fetchImageWithSuccess`.

_There's no reason to mantain this style in Swift_ other than compatibility with Objective-C. In fact, doing so would decrease clarity if we apply the previous two recommendations. See for yourself: 

```swift
fetchImageWithFailure(success: { image in
    // Success
    // Though you might think otherwise if you read it quickly.
})

fetchImageWithFailure { _ in
    // Success or failure?
    // It's success, but you have to know the function signature to know.
}
```

## Parameter names

The final and perhaps most subjective difference are the parameters names. 

Typically, block parameters in Objective-C are called `somethingBlock`. In Swift we could use `somethingClosure`, but that would make the parameter name even longer. Loosing the qualifier is not an option, as it makes the parameter type less clear (e.g., Is `success` a closure or a `Bool`? Does  `failure` represent a reason or a closure?)

For lack of an official style guide, I propose using verbs for internal parameter names of closures (as suggested by Legolas-the-elf). If not possible to find a verb, prefixing the name with `on` should do (as suggested by @radex). Let's take an excerpt from previous examples and see if this feels right.

```
if didSucceed {
    succeed(image) // onSuccess(image)
} else {
    fail(error) // onfailure(error)
}
```

At the very least the `on` prefix is short and clearly indicates a closure. While it might not become the standard, it beats calling these parameters `somethingBlock`.

## Method chaining as an alternative to multiple closure parameters

As shown in the previous examples multiple closure parameters can be misleading if not treated with care. One could avoid them altogether by using other techniques such as delegates or method chaining. In particularly, the latter works great in Swift:

```swift
fetchImage().onSuccess { image in
	// Success
}

fetchImage().onFailure { error in
	// Failure
}.onSuccess { image in
	// Success
}
```

For this we would need a completely different signature:

```swift
func fetchImage() -> Fetch<UIImage>
```

Where `Fetch` is a generic class that can accept the success and failure closures and call them accordingly. Its implementation will depend on the specific requirements of the operation (e.g., is `fetchImage` fully asynchronous or can it finish synchronously in some scenarios?) and as such is left out of the scope of this article.

It's worth noting that this was also possible in Objective-C. However, thanks to generics and a refined closure syntax, the Swift code is much easier to read and write.

## Style guide

* In functions with more than one closure, treat the trailing closure as the most important closure of the function.
* Set the default value of closure parameters to an empty closure or `nil`. `nil` is preferred when performance is a concern and optimizations can be implemented by knowning that the function user didn't provide a closure.
* Avoid suffixing the method name with the first parameter name when said parameter is a closure (e.g., `fetchImageWithFailure`).
* User verbs for internal closure parameter names or prefix them with `on`.
* Consider method chaining as an alternative for multiple closure parameters.

Agree? Disagree? Please don't hesitate to post an issue or submit pull requests with feedback or corrections.


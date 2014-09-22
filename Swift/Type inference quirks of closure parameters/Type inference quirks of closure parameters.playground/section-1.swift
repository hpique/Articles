import Foundation
import XCTest

// Type inference quirks of closures as parameters

// What the documentation tells us

var names = ["Ares", "Artemis", "Chewbacca"]
var reversed : [String]

reversed = sorted(names) { (s1: String, s2: String) -> Bool in
    return s1 > s2
}

reversed = sorted(names) { s1, s2 in
    return s1 > s2
}

// Single-expression closures with unused return value

let someDate = NSDate.distantPast() as NSDate
let path = NSHomeDirectory()
let fileManager = NSFileManager.defaultManager()
let someQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)

// Bad

/*
dispatch_async(someQueue) {
fileManager.setAttributes([NSFileModificationDate : someDate], ofItemAtPath: path, error: nil)
}
*/

// Good

dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
    let _ = NSFileManager.defaultManager().setAttributes([NSFileModificationDate : someDate], ofItemAtPath: path, error: nil)
}

// Unused parameters in closures

func fetchDataWithSuccess(success doSuccess : (NSData) -> (), failure doFailure : ((NSError?) -> ())) {
    doFailure(NSError.errorWithDomain("com.hpique", code: 0, userInfo: nil))
}

class SomeTests : XCTestCase {
    
    // Bad
    
    /*
    func testFailure() {
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
    */
    
    // Good
    
    func testFailure() {
        let expectation = self.expectationWithDescription("fetch")
        fetchDataWithSuccess(success: {_ in
            XCTFail("expected failure")
            expectation.fulfill()
            }, failure : { e in
                XCTAssertNotNil(e)
                expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
}

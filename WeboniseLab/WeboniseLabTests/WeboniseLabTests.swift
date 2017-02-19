//
//  WeboniseLabTests.swift
//  WeboniseLabTests
//
//  Created by Netstratum on 2/19/17.
//  Copyright © 2017 irfan. All rights reserved.
//

import XCTest
import CoreLocation
import OHHTTPStubs

class WeboniseLabTests: XCTestCase {
    
    let kGooglePlacesSuccessFileName = "GooglePlaces_Success.json"
    let kGooglePlacesEmptyFileName = "GooglePlaces_Empty.json"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGoogleAPISucces() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let expectation = self.expectation(description: "wait")
        let location = CLLocation(latitude: CLLocationDegrees(9.96665), longitude: CLLocationDegrees(76.31681))
        let name = "Vyttila"
        stubWithJSONResponse(kGooglePlacesSuccessFileName)
        ServiceManager.sharedInstance.getNearPlaces(name, location) { (places, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(places)
            
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGoogleAPIEmpty() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let expectation = self.expectation(description: "wait")
        let location = CLLocation(latitude: CLLocationDegrees(9.96665), longitude: CLLocationDegrees(76.31681))
        let name = "MyPlace"
        stubWithJSONResponse(kGooglePlacesEmptyFileName)
        ServiceManager.sharedInstance.getNearPlaces(name, location) { (places, error) in
            XCTAssertNil(error)
            XCTAssertEqual(places?.count, 0)
            
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func stubWithJSONResponse(_ file: String) {
        
        OHHTTPStubs.removeAllStubs()
        
        let path = Bundle(for: WeboniseLabTests.self).path(forResource: file, ofType: "json")
        guard let resourcePath = path else {
            return
        }
        let response = OHHTTPStubsResponse(fileAtPath: resourcePath, statusCode: 200, headers: ["Content-Type": "application/json"])
        
        OHHTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return true
        }) { (request) -> OHHTTPStubsResponse in
            return response
        }
    }
}

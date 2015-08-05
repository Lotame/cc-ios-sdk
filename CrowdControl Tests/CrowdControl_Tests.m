//
//  CrowdControl_Tests.m
//  CrowdControl Tests
//
//  Created by Dan Rusk on 4/16/15.
//  Copyright (c) 2015 Lotame. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "CrowdControl.h"

@interface CrowdControl_Tests : XCTestCase
    @property CrowdControl *cc;
@end

@implementation CrowdControl_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    cc = [[CrowdControl alloc] initWithClientId:25 andDomain:nil andProtocol:@"http"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testUrlEncode {
    // This is an example of a functional test case.
    
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

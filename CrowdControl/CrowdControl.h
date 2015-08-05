// The MIT License (MIT)
//
// Copyright (c) 2015 Lotame
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import <Foundation/Foundation.h>

typedef void (^JsonCallback)(BOOL success, NSString *response, NSError *error);

@interface CrowdControl : NSObject

@property(readonly) int clientId;
@property NSString* protocol;
@property BOOL newSession;

/**
 Set this to true to write log messages to NSLog, false to hide them.  Defaults to false.
 */
@property BOOL enableLog;

/**
 This property (acceptAnySSSLCert) should only be set to true for debugging purposes.  Having it set to true
 in production may lead to rejection from the app store due to possible man-in-the-middle ssl attacks. Defaults to false.
 */
@property (nonatomic, assign) BOOL acceptAnySSLCert;

- (id) initWithClientId:(int) idForClient;

- (id) initWithClientId:(int) idForClient andDomain:(NSString *)domain;

- (id) initWithClientId:(int) idForClient andDomain:(NSString*)domain andProtocol:(NSString*) protocolInArg;

- (NSString*) id;

- (void) add:(NSString*) type withValue:(NSString*) value;

- (void) addBehavior: (long) value;

- (void) addOpportunity: (long) value;

/**
 An asynchronous call to send tracking data to the server.
 */
- (void) bcp;

/**
 An asynchronous call to send tracking data to the server with a completion callback to indicate success or error
 */
- (void) bcpWithCallBack:(JsonCallback)callback;

/**
 Gets audience json data in a synchronous manner.  Should not be called on the main thread.
 */
- (NSString *) getAudienceJSON: (long) timeoutInSeconds __deprecated_msg("Use the asynchronous getAudienceJsonWithTimeout andCallback: instead.");

/**
 Gets audience json data in an asynchronous manner.  Can be called on the main thread.
 The callback has a success parameter (true if succesful, false if error),
 an NSString containing the json data encoded in NSUTF8StringEncoding,
 and an NSError object that is nil on success or contains an error if success is false (generally due to NSURLConnection errors).
 */
- (void) getAudienceJsonWithTimeout:(long) timeoutInSeconds andCallback:(JsonCallback)callback;

- (void) startNewSession;

@end
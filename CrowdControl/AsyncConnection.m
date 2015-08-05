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

#import "AsyncConnection.h"

@implementation AsyncConnection{
    
    BOOL acceptAnySSLCert;
    BOOL showLog;
    BOOL calledCallback;
    JsonCallback _callback;
    NSMutableData * _responseData;
}

- (id)initWithLogEnabled:(BOOL)logEnabled andAcceptAnySSLCert:(BOOL)acceptAnyCert {
    self = [super init];
    acceptAnySSLCert = acceptAnyCert;
    showLog = logEnabled;
    calledCallback = false;
    _callback = nil;
    _responseData = [[NSMutableData alloc] init];
    return self;
}



//Data is sent in url query string parameters via get
-(void)sendRequestWithUrl:(NSString *)url{
    [self sendRequestWithUrl:url andTimeout:60.0 andCallback:nil];
}

-(void)sendRequestWithUrl:(NSString *)url andTimeout:(long)timeOutInSeconds andCallback:(JsonCallback)callback{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString: url]
                                                  cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeOutInSeconds];
    _callback = [callback copy];
    
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (!connection && showLog) {
        NSLog(@"CrowdControl connection failed");
    }
}

NSString * kAsyncConnectionErrorDomain = @"CCAsyncConnectionError";
NSInteger kUnexpectedResponse = 400;


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    if(_callback != nil && !calledCallback && (int)[httpResponse statusCode] != 200){
        //response is not ok
        NSString *description= [NSString stringWithFormat:@"Server did not send 200 OK response: response was %d",(int)[httpResponse statusCode]];
        
        //description = NSLocalizedString(@"Server did not send 200 OK response", @"");
        NSInteger errCode = kUnexpectedResponse;
        
        // Create and return the custom domain error.
        NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : description };
        
        _callback(false, @"{}", [[NSError alloc] initWithDomain:kAsyncConnectionErrorDomain code:errCode userInfo:errorDictionary]);
        calledCallback = true;
    }
    
    if(showLog){
        NSLog(@"CrowdControl GET Response Code: %d", (int)[httpResponse statusCode]);
    }
}

// Called when data has been received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(showLog){
        NSLog(@"CrowdControl GET Connection received data");
    }
    
    [_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(showLog){
        NSLog(@"CrowdControl GET Connection finished loading");
    }
    
    if(_callback != nil && !calledCallback){
        NSString *jsonData = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
        _callback(true, jsonData, nil);
        calledCallback = true;
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    if(showLog){
        NSLog(@"CrowdControl Async GET failed: %@",[error localizedDescription]);
    }
    if(_callback != nil && !calledCallback){
        _callback(false, nil, error);
        calledCallback = true;
    }
}

- (void) connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    if(acceptAnySSLCert){
        //For debugging purposes
        if(showLog){
            NSLog(@"Authentication request received and ignored");
        }
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }else{
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

@end

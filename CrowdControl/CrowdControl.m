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

#import "CrowdControl.h"
#import "Id.h"
#import "AsyncConnection.h"
#import "AtomParameter.h"

static NSString *const  KEY_BEHAVIOR_ID = @"b";
static NSString *const  KEY_PLACEMENT_ID = @"p";
static NSString *const  KEY_PAGE_VIEW = @"pv";
static NSString *const  KEY_COUNT_PLACEMENTS = @"dp";
static NSString *const  KEY_CLIENT_ID = @"c";
static NSString *const  KEY_RANDOM_NUMBER = @"rand";
static NSString *const  KEY_ID = @"mid";
static NSString *const  KEY_ENV_ID = @"e";
static NSString *const  KEY_DEVICE_TYPE = @"dt";
static NSString *const  KEY_SDK_VERSION = @"sdk";

static NSString *const  VALUE_SDK_VERSION = @"2.0";
static NSString *const  VALUE_IDFA = @"IDFA";
static NSString *const  VALUE_YES = @"y";
static NSString *const  VALUE_APP = @"app";
static NSString *const DEFAULT_BCP_DOMAIN = @"bcp.crwdcntrl.net";
static NSString *const DEFAULT_API_DOMAIN = @"ad.crwdcntrl.net";
static NSString *const CUSTOM_DOMAIN_BCP_PREPEND = @"bcp.";
static NSString *const CUSTOM_DOMAIN_API_PREPEND = @"ad.";
static NSString *const EQUAL = @"=";
static NSString *const SLASH = @"/";
static NSString *const ZERO_ID = @"00000000-0000-0000-0000-000000000000";

@implementation CrowdControl
{
    @private
    NSMutableArray* queue;
    NSMutableString* baseURL;
    NSString* domainOverride;
    NSString* protocol;
}

@synthesize clientId;
@synthesize newSession;
@synthesize protocol;
@synthesize acceptAnySSLCert;
@synthesize enableLog;

- (NSString*) id{
    
    NSString* uuid = [Id value];
    
    if([uuid length] > 0){
        if ([ZERO_ID isEqualToString:uuid]) {
            NSLog(@"bad id of %@ present, use nil instead to prevent transfer", ZERO_ID);
            return nil;
        }
        return uuid;
    } else{
        return nil;
    }
    
}

- (id) initWithClientId:(int) idForClient {
    self = [self initWithClientId:idForClient andDomain:nil andProtocol:nil];
    return self;
}

- (id) initWithClientId:(int) idForClient andDomain:(NSString *)domain {
    self = [self initWithClientId:idForClient andDomain:domain andProtocol:nil];
    return self;
}

- (id) initWithClientId:(int) idForClient andDomain:(NSString*)domain andProtocol:(NSString*) protocolInArg {
    if (self = [super init]) {
        queue = [[NSMutableArray alloc] init];
        newSession = NO;
        clientId = idForClient;
        acceptAnySSLCert = false;
        enableLog = false;
        
        if (domain != nil) {
            domainOverride = domain;
        }
        
        if (protocolInArg != nil) {
            [self setProtocol:protocolInArg];
        } else {
            [self setProtocol:@"http"];
        }
        
        [self resetUrl];
        [self startNewSession];
    }
    return self;
}

- (void) add:(NSString*) type withValue:(NSString*) value {
    if ([self id] == nil){
        NSLog(@"Advertising ID is disabled in Settings. Ignoring track requests.");
    } else {
        //make queue threadsafe
        @synchronized(self) {
            if ([type isEqualToString: KEY_PLACEMENT_ID]) {
                [queue addObject:[[AtomParameter alloc ] initWithKey:type value:value atomType:PLACEMENT_OPPS]];
            }else{
                [queue addObject:[[AtomParameter alloc ] initWithKey:type value:value]];
            }
        }
        
        NSLog(@"CrowdControl add type: %@ and value: %@",type,value);
    }
}


- (void) addBehavior: (long) id {
    [self add:KEY_BEHAVIOR_ID withValue:[[NSString alloc] initWithFormat:@"%ld", id]];
}

- (void) addOpportunity: (long) id {
    [self add:KEY_PLACEMENT_ID withValue:[[NSString alloc] initWithFormat:@"%ld", id]];
}


- (void) startNewSession{
    newSession = YES;
}

- (void)  bcp{
    [self bcpWithCallBack:nil];
}

- (void) bcpWithCallBack:(JsonCallback)callback{
    if ([self id] == nil){
        NSLog(@"Advertising ID is disabled in Settings. Ignoring track requests.");
    } else {
        [self sendDataToServerWithCallback:callback];
    }
}

- (void) append:(AtomParameter*)param toBase:(NSMutableString*)base {
    NSString * encodedKey = [self urlEncode:param.key];
    NSString * encodedValue = [self urlEncode:param.value];
    if(encodedKey != nil){
        [base appendString:encodedKey];
        [base appendString: EQUAL];
        if (encodedValue != nil) {
            [base appendString:encodedValue];
        }
        [base appendString: SLASH];
    }
}

- (void) appendParameterToBase :(AtomParameter*) elem {
    [self append:elem toBase:baseURL];
}

- (void) resetUrl {
    //synchronize access to baseUrl
    @synchronized(self){
        baseURL = [NSMutableString stringWithCapacity:10];
        
        [baseURL setString: protocol];
        [baseURL appendString: @"://"];
        
        if (domainOverride != nil) {
            [baseURL appendString: CUSTOM_DOMAIN_BCP_PREPEND];
            [baseURL appendString: domainOverride];
        } else {
            [baseURL appendString: DEFAULT_BCP_DOMAIN];
        }
        [baseURL appendString:@"/5/"];
        [self appendParameterToBase:[[AtomParameter alloc ] initWithKey:KEY_CLIENT_ID value:[[NSString alloc] initWithFormat:@"%d", [self clientId]]]];
        [self appendParameterToBase:[[AtomParameter alloc] initWithKey:KEY_ID value:[self id]]];
        [self appendParameterToBase:[[AtomParameter alloc] initWithKey:KEY_ENV_ID value:VALUE_APP]];
        [self appendParameterToBase:[[AtomParameter alloc] initWithKey:KEY_DEVICE_TYPE value:VALUE_IDFA]];
        [self appendParameterToBase:[[AtomParameter alloc] initWithKey:KEY_SDK_VERSION value:VALUE_SDK_VERSION]];
    }
}

//Sends data asynchronously to server via url
- (void) sendDataToServerWithCallback: (JsonCallback)callback {
    
    //synchronize access to the Nsmutablearray of queue and NSMutable String of base
    @synchronized(self) {
        // construct a new url starting from baseUrl, and append any queued data to it
        NSMutableString* url = [NSMutableString stringWithCapacity:10];
        [url setString:baseURL];
        
        [self append:[[AtomParameter alloc] initWithKey:KEY_RANDOM_NUMBER value:[NSString stringWithFormat: @"%d", arc4random() % 999999999]] toBase:url];
        
        if(newSession) {
            [self append:[[AtomParameter alloc] initWithKey:KEY_PAGE_VIEW value:VALUE_YES] toBase:url];
            newSession = NO;
        }

        bool placementIncluded = NO;
        if([queue count] > 0){
            //Add queued parameters
            for(int i = 0; i < [queue count]; i++){
                AtomParameter* param = [queue objectAtIndex:i];
                [self append:param toBase:url];
                if (!placementIncluded && param.key == KEY_PLACEMENT_ID) {
                    [self append:[[AtomParameter alloc] initWithKey:KEY_COUNT_PLACEMENTS value:VALUE_YES] toBase:url];
                    placementIncluded = YES;
                }
            }
            
            //Clear queue
            [queue removeAllObjects];
        }
        
        if(enableLog){
            NSLog(@"CrowdControl GET: %@",url);
        }
        
        AsyncConnection* conn = [[AsyncConnection alloc] init];
        [conn sendRequestWithUrl:url andTimeout:60.0 andCallback:callback];
    
        [self resetUrl];
    }

}

//Gets json data from server in a synchronous manner.  Should not be run in the main thread!
- (NSString *) getAudienceJSON:(long) timeoutInSeconds {
    if ([self id] == nil){
        if(enableLog){
            NSLog(@"Advertising ID is disabled in Settings. Returning blank data as per apple developer guidelines.");
        }
        return @"{}";
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: [self buildAudienceURLString]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeoutInSeconds];
    
    [request setHTTPMethod: @"GET"];
   
    if(enableLog){
        NSLog(@"CrowdControl GET: %@", request.URL.absoluteString);
    }
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    return [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
}

- (void) getAudienceJsonWithTimeout:(long) timeoutInSeconds andCallback:(JsonCallback)callback{
    if (callback == nil){
        [NSException raise:@"Callback missing" format:@"callback must be provided that has success, nsstring, nserror arguments."];
        return;
    }
    
    if ([self id] == nil){
        if(enableLog){
            NSLog(@"Advertising ID is disabled in Settings. Returning blank data as per apple developer guidelines.");
        }
        callback(true, @"{}", nil);
        return;
    }
    
    NSString * urlString = [self buildAudienceURLString];
    if(enableLog){
        NSLog(@"CrowdControl GET: %@", urlString);
    }
    
    AsyncConnection* conn = [[AsyncConnection alloc] initWithLogEnabled:enableLog andAcceptAnySSLCert:acceptAnySSLCert];
    [conn sendRequestWithUrl:urlString andTimeout:timeoutInSeconds andCallback:callback];
}

-(NSString *) buildAudienceURLString{
    NSMutableString* url = [[NSMutableString alloc] init];
    
    [url setString: protocol];
    [url appendString: @"://"];
    
    if (domainOverride != nil) {
        [url appendString: CUSTOM_DOMAIN_API_PREPEND];
        [url appendString: domainOverride];
    } else {
        [url appendString: DEFAULT_API_DOMAIN];
    }
    [url appendString:@"/5/pe=y/"];
    
    [self append:[[AtomParameter alloc] initWithKey:KEY_CLIENT_ID value:[[NSString alloc] initWithFormat:@"%d", [self clientId]]] toBase:url];
    [self append:[[AtomParameter alloc] initWithKey:KEY_ID value:[self id]] toBase:url];
    
    return [NSString stringWithString:url];
}

- (NSString*) urlEncode:(NSString*)string
{
    if(string == nil){
        return string;
    }
    //return [string stringByAddingPercentEncodingWithAllowedCharacters:nil];
    //CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`")
    NSString * encoded =  (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                  (CFStringRef) string,
                                                                                  NULL,
                                                                                  (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                  kCFStringEncodingUTF8));
    
    if(enableLog && encoded == nil){
        NSLog(@"CrowdControl attempt to encode %@ resulted in error", string);
    }
    return encoded;
}

@end

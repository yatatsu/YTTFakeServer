//
//  YTTFakeServer.m
//  Pods
//
//  Created by KITAGAWA Tatsuya on 2014/11/25.
//
//

#import "YTTFakeServer.h"
#import <Reachability/Reachability.h>

static NSInteger const YTTProvisionHTTPStatusCodeOK = 200;
static NSInteger const YTTProvisionHTTPStatusCodeNoContent = 204;
static NSInteger const YTTProvisionHTTPStatusCodeRedirectionFound = 302;
static NSInteger const YTTProvisionHTTPStatusCodeNotFound = 404;

#pragma mark - YTTFakeServerConfiguration

@interface YTTFakeServerConfiguration ()

@end

@implementation YTTFakeServerConfiguration

- (void)resetConfiguration
{
    _hosts = [NSArray array];
    _schemes = @[@"http", @"https"];
    _ignoringFileExtentions = @[@"jpg", @"png", @"css", @"js"];
    _cacheStoragePolicy = NSURLCacheStorageNotAllowed;
    _delay = 0;
    _resourceBundle = nil;
    _resourceFileExtension = @"json";
    _enableReachabilityCheck = YES;
}

+ (instancetype)sharedConfiguration
{
    static dispatch_once_t onceToken;
    static YTTFakeServerConfiguration *__instance = nil;
    dispatch_once(&onceToken, ^{
        __instance = [YTTFakeServerConfiguration new];
        [__instance resetConfiguration];
    });
    return __instance;
}

@end

#pragma mark - YTTFakeServerResponse

@implementation YTTFakeServerResponse

- (instancetype)initWithURL:(NSURL *)url
                    headers:(NSDictionary *)headers
                     status:(NSInteger)status
               responseData:(NSData *)data
{
    self = [super init];
    if (self) {
        _url = url;
        _headers = [headers copy];
        _status = status;
        _responseData = data;
        _response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:headers];
    }
    return self;
}

@end

#pragma mark - YTTFakeServer

@interface YTTFakeServer () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation YTTFakeServer

+ (void)configure:(void (^)(YTTFakeServerConfiguration *configuration))configurationBlock
{
    YTTFakeServerConfiguration *sharedConfiguration = [YTTFakeServerConfiguration sharedConfiguration];
    if (configurationBlock) {
        configurationBlock(sharedConfiguration);
    }
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    YTTFakeServerConfiguration *sharedConfiguration = [YTTFakeServerConfiguration sharedConfiguration];
    if (!sharedConfiguration.schemes || ![sharedConfiguration.schemes containsObject:request.URL.scheme]) {
        return NO;
    }
    if (sharedConfiguration.hosts) {
        BOOL supportedHost = NO;
        for (NSString *hostName in sharedConfiguration.hosts) {
            if ([request.URL.absoluteString hasPrefix:hostName]) {
                supportedHost = YES;
                break;
            }
        }
        if (!supportedHost) {
            return NO;
        }
    }
    if (sharedConfiguration.ignoringFileExtentions
        && [sharedConfiguration.ignoringFileExtentions containsObject:request.URL.pathExtension]) {
        return NO;
    }
    
    if ([sharedConfiguration.delegate respondsToSelector:@selector(YTTFakeServerShouldInitWithRequest:)]) {
        if (![sharedConfiguration.delegate YTTFakeServerShouldInitWithRequest:request]) {
            return NO;
        }
    }

    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    YTTFakeServerConfiguration *sharedConfiguration = [YTTFakeServerConfiguration sharedConfiguration];
    if ([sharedConfiguration.delegate respondsToSelector:@selector(YTTFakeServerCanonicalRequestForRequest:)]) {
        return [sharedConfiguration.delegate YTTFakeServerCanonicalRequestForRequest:request];
    }
    return request;
}

#pragma mark -

- (void)startLoading
{
    id<NSURLProtocolClient> client = self.client;
    
    NSMutableURLRequest *req = [self.request mutableCopy];
    if (!req.HTTPBody) {
        NSData *data = [NSURLProtocol propertyForKey:@"HTTPBody" inRequest:req];
        req.HTTPBody = data;
    }
    NSURLRequest *request = [[self class] canonicalRequestForRequest:req];

    YTTFakeServerConfiguration *sharedConfiguration = [YTTFakeServerConfiguration sharedConfiguration];
    
    // start loading
    if ([sharedConfiguration.delegate respondsToSelector:@selector(YTTFakeServerClient:didStartRequest:)]) {
        [sharedConfiguration.delegate YTTFakeServerClient:client didStartRequest:request];
    }
    
    if ([sharedConfiguration.delegate respondsToSelector:@selector(YTTFakeServerShouldOnlyPassProxyWithRequest:)]
        && [sharedConfiguration.delegate YTTFakeServerShouldOnlyPassProxyWithRequest:request]) {
        // start request
        self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
        return;
    }
    
    // reachability
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    if (reachability.currentReachabilityStatus == NotReachable) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"The connection failed because the device is not connected to the internet.",
                                   NSURLErrorFailingURLErrorKey:request.URL};
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:userInfo];
        [client URLProtocol:self didFailWithError:error];
        return;
    }
    
    // custom error
    if ([sharedConfiguration.delegate respondsToSelector:@selector(YTTFakeServerClient:errorForRequest:)]) {
        NSError *error = [sharedConfiguration.delegate YTTFakeServerClient:client errorForRequest:request];
        if (error) {
            [client URLProtocol:self didFailWithError:error];
            return;
        }
    }
    
    // delay timeInterval
    [NSThread sleepForTimeInterval:sharedConfiguration.delay];

    // redirect
    if ([sharedConfiguration.delegate respondsToSelector:@selector(YTTFakeServerClient:redirectURLForRequest:)]) {
        NSURL *redirectURL = [sharedConfiguration.delegate YTTFakeServerClient:client redirectURLForRequest:request];
        if (redirectURL) {
            NSHTTPURLResponse *redirectResponse = [[NSHTTPURLResponse alloc] initWithURL:redirectURL
                                                                              statusCode:YTTProvisionHTTPStatusCodeRedirectionFound
                                                                             HTTPVersion:@"HTTP/1.1"
                                                                            headerFields:@{@"Location":redirectURL.absoluteString}];
            NSURLRequest *redirectRequest = [NSURLRequest requestWithURL:redirectURL
                                                             cachePolicy:request.cachePolicy
                                                         timeoutInterval:request.timeoutInterval];
            [client URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:redirectResponse];
            return;
        }        
    }
    
    NSData *responseData;
    NSMutableDictionary *headers = [request.allHTTPHeaderFields mutableCopy];
    NSInteger statusCode = YTTProvisionHTTPStatusCodeOK;
    NSHTTPURLResponse *response;
    
    // responseData from bundle
    if (sharedConfiguration.resourceBundle) {
        NSString *path = request.URL.path;
        NSString *filePath = [sharedConfiguration.resourceBundle pathForResource:path.lastPathComponent
                                                                          ofType:sharedConfiguration.resourceFileExtension
                                                                     inDirectory:[path stringByDeletingLastPathComponent]];
        responseData = [[NSData alloc] initWithContentsOfFile:filePath];
        if ([sharedConfiguration.resourceFileExtension isEqualToString:@"json"]) {
            headers[@"Content-Type"] = @"application/json";
        }
    }

    // responseData from delegate
    if (!responseData
        && [sharedConfiguration.delegate respondsToSelector:@selector(YTTFakeServerClient:responseDataForRequest:)]) {
        responseData = [sharedConfiguration.delegate YTTFakeServerClient:client responseDataForRequest:request];
    }
    
    if (!responseData || !responseData.length) {
        if ([request.HTTPMethod isEqualToString:@"GET"]) {
            statusCode = YTTProvisionHTTPStatusCodeNotFound;
        } else {
            statusCode = YTTProvisionHTTPStatusCodeNoContent;
        }
    }
    
    // response
    if ([sharedConfiguration.delegate respondsToSelector:@selector(YTTFakeServerClient:responseForRequest:)]) {
        YTTFakeServerResponse *res = [sharedConfiguration.delegate YTTFakeServerClient:client responseForRequest:request];
        response = res.response;
        if (res.responseData) {
            responseData = res.responseData;
        }
    }

    // response with statusCode and headers
    if (!response) {
        response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                               statusCode:statusCode
                                              HTTPVersion:@"HTTP/1.1"
                                             headerFields:headers];
    }
    
    [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:sharedConfiguration.cacheStoragePolicy];
    [client URLProtocol:self didLoadData:responseData];
    [client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading
{
    [self.connection cancel];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    [self.client URLProtocol:self didFailWithError:error];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    return YES;
}

- (void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self.client URLProtocol:self didReceiveAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection
didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self.client URLProtocol:self didCancelAuthenticationChallenge:challenge];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    YTTFakeServerConfiguration *sharedConfiguration = [YTTFakeServerConfiguration sharedConfiguration];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:sharedConfiguration.cacheStoragePolicy];
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

@end
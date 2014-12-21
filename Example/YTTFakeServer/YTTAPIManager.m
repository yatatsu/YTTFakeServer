//
//  YTTAPIManager.m
//  YTTFakeServer
//
//  Created by KITAGAWA Tatsuya on 2014/12/12.
//  Copyright (c) 2014年 yatatsu. All rights reserved.
//

#import "YTTAPIManager.h"
#import <YTTFakeServer/YTTFakeServer.h>

@implementation YTTJSONRequestSerializer
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(NSDictionary *)parameters
                                     error:(NSError * __autoreleasing *)error
{
    NSMutableURLRequest* req = [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
    [NSURLProtocol setProperty:req.HTTPBody forKey:@"HTTPBody" inRequest:req];
    [NSURLProtocol setProperty:parameters forKey:@"parameters" inRequest:req];
    return req;
}
@end

@interface YTTAPIManager () <YTTFakeServerDelegate>

@end

@implementation YTTAPIManager

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static id __instance = nil;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfiguration.protocolClasses = @[[YTTFakeServer class]];
        __instance = [[YTTAPIManager alloc] initWithBaseURL:[NSURL URLWithString:YTTAPIHost]
                              sessionConfiguration:sessionConfiguration];
        [YTTFakeServer configure:^(YTTFakeServerConfiguration *configuration) {
            configuration.hosts = @[YTTAPIHost];
            configuration.delegate = __instance;
            configuration.delay = 1.0;
            configuration.resourceBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"YTTFakeServer" ofType:@"bundle"]];
            configuration.resourceFileExtension = @"json";
        }];
    });
    return __instance;
}

- (instancetype)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    self.responseSerializer = [AFJSONResponseSerializer serializer];
    self.requestSerializer = [YTTJSONRequestSerializer serializer];
    return self;
}

#pragma mark - Cancel

- (void)cancelAllTask
{
    for (NSURLSessionTask *task in [self tasks]) {
        [task cancel];
    }
}

- (void)cancelTaskWithMethod:(NSString *)method path:(NSString *)path
{
    for (NSURLSessionTask *task in [self tasks]) {
        NSURLRequest *request = [task currentRequest];
        NSString *taskMethod = [request HTTPMethod];
        NSString *taskPath   = [[request URL] path];
        NSLog(@"cancel (method) operationPath : path = (%@) %@ : %@", taskMethod, taskPath, path);
        if ([taskMethod isEqualToString:method]
            && [taskPath isEqualToString:path]) {
            [task cancel];
        }
    }
}

#pragma mark - YTTFakeServerDelegate

- (NSURLRequest *)YTTFakeServerCanonicalRequestForRequest:(NSURLRequest *)request
{
    NSLog(@">>>> request %@", request.HTTPBody);
    return request;
}

- (void)YTTFakeServerClient:(id<NSURLProtocolClient>)client didStartRequest:(NSURLRequest *)reqeust
{
    NSLog(@"didStartRequest >>> %@", reqeust.URL.absoluteString);
}

- (BOOL)YTTFakeServerShouldOnlyPassProxyWithRequest:(NSURLRequest *)request
{
    if ([request.URL.path isEqualToString:@"/get"]) {
        NSLog(@"YTTFakeServerShouldOnlyPassProxyWithRequest >> YES");
        return YES;
    }
    NSLog(@"YTTFakeServerShouldOnlyPassProxyWithRequest >> NO");
    return NO;
}

- (YTTFakeServerResponse *)YTTFakeServerClient:(id<NSURLProtocolClient>)client responseForRequest:(NSURLRequest *)request
{
    NSString *path = request.URL.path;
    if ([path isEqualToString:@"/api/auth"]) {
        NSDictionary *param = [NSURLProtocol propertyForKey:@"parameters" inRequest:request];
        if (![param[@"password"] isEqualToString:@"1234"]) {
            NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"YTTFakeServer" ofType:@"bundle"]];
            NSData *responseData = [[NSData alloc] initWithContentsOfFile:[bundle pathForResource:@"auth_error" ofType:@"json" inDirectory:@"api"]];
            return [[YTTFakeServerResponse alloc] initWithURL:request.URL headers:request.allHTTPHeaderFields status:400 responseData:responseData];
        }
    }
    return nil;
}

@end

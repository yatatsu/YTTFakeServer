//
//  YTTFakeServer.h
//  Pods
//
//  Created by KITAGAWA Tatsuya on 2014/11/25.
//
//

#import <Foundation/Foundation.h>

@interface YTTFakeServerResponse : NSObject

@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSDictionary *headers;
@property (nonatomic, assign, readonly) NSInteger status;
@property (nonatomic, strong, readonly) NSData *responseData;

- (instancetype)initWithURL:(NSURL *)url
                    headers:(NSDictionary *)headers
                     status:(NSInteger)status
               responseData:(NSData *)data;

@end

@protocol YTTFakeServerDelegate <NSObject>

@optional
- (BOOL)YTTFakeServerShouldInitWithRequest:(NSURLRequest *)request;
- (BOOL)YTTFakeServerShouldOnlyPassProxyWithRequest:(NSURLRequest *)request;
- (NSURLRequest *)YTTFakeServerCanonicalRequestForRequest:(NSURLRequest *)request;
- (void)YTTFakeServerClient:(id<NSURLProtocolClient>)client didStartRequest:(NSURLRequest *)reqeust;

- (YTTFakeServerResponse *)YTTFakeServerClient:(id<NSURLProtocolClient>)client responseForRequest:(NSURLRequest *)request;
- (NSURL *)YTTFakeServerClient:(id<NSURLProtocolClient>)client redirectURLForRequest:(NSURLRequest *)request;
- (NSDictionary *)YTTFakeServerClient:(id<NSURLProtocolClient>)client responseHeaderForRequest:(NSURLRequest *)request;
- (NSInteger)YTTFakeServerClient:(id<NSURLProtocolClient>)client responseStatusForRequest:(NSURLRequest *)request;
- (NSData *)YTTFakeServerClient:(id<NSURLProtocolClient>)client responseDataForRequest:(NSURLRequest *)request;
- (NSError *)YTTFakeServerClient:(id<NSURLProtocolClient>)client errorForRequest:(NSURLRequest *)request;
- (NSHTTPURLResponse *)YTTFakeServerClient:(id<NSURLProtocolClient>)client responseForRequest:(NSURLRequest *)request customProperty:(id)customProperty;

@end

@interface YTTFakeServerConfiguration : NSObject

@property (nonatomic, weak) id<YTTFakeServerDelegate> delegate;
@property (nonatomic, copy) NSArray *hosts;
@property (nonatomic, copy) NSArray *schemes;
@property (nonatomic, copy) NSArray *ignoringFileExtentions;
@property (nonatomic, assign) NSURLCacheStoragePolicy cacheStoragePolicy;
@property (nonatomic, assign) NSTimeInterval delay;
@property (nonatomic, strong) NSBundle *resourceBundle;
@property (nonatomic, copy) NSString *resourceFileExtension;
@property (nonatomic, assign) BOOL enableReachabilityCheck;

+ (instancetype)sharedConfiguration;
- (void)resetConfiguration;

@end

@interface YTTFakeServer : NSURLProtocol

+ (void)configure:(void (^)(YTTFakeServerConfiguration *configuration))configurationBlock;

@end
//
//  YTTFakeServer.h
//  Pods
//
//  Created by KITAGAWA Tatsuya on 2014/11/25.
//
//

#import <Foundation/Foundation.h>

/**
 * YTTFakeServerResponse
 *
 * a wrapper of NSHTTPURLResponse
 */
@interface YTTFakeServerResponse : NSObject

@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSDictionary *headers;
@property (nonatomic, assign, readonly) NSInteger status;
@property (nonatomic, strong, readonly) NSData *responseData;

/**
 * build NSHTTPURLResponse
 *
 * @param `NSURL` url
 * @param `NSDictionary` headers
 * @param `NSInteger` status
 * @param `NSData` data
 */
- (instancetype)initWithURL:(NSURL *)url
                    headers:(NSDictionary *)headers
                     status:(NSInteger)status
               responseData:(NSData *)data;

@end

/**
 * YTTFakeServerDelegate
 *
 * all delegate methods are optional.
 */
@protocol YTTFakeServerDelegate <NSObject>

@optional

/**
 * Whether to start YTTFakeServer in request.
 *
 * It returns NO, and YTTFakeServer will not start even if host are supported.
 */
- (BOOL)YTTFakeServerShouldInitWithRequest:(NSURLRequest *)request;

/**
 * Whether to go through request.
 *
 * It returns YES, YTTFakeServer will not provide fake response, start real connection.
 */
- (BOOL)YTTFakeServerShouldOnlyPassProxyWithRequest:(NSURLRequest *)request;

/**
 * Customise request from original.
 *
 * For example, add HTTPHeader
 */
- (NSURLRequest *)YTTFakeServerCanonicalRequestForRequest:(NSURLRequest *)request;

/**
 * It will be called after `YTTFakeServer:startLoading` start.
 */
- (void)YTTFakeServerClient:(id<NSURLProtocolClient>)client didStartRequest:(NSURLRequest *)reqeust;

/**
 * Response for request
 *
 * Build YTTFakeServerResponse from NSURL, headers, status, responseData
 * @see `YTTFakeServerResponse`
 *
 * return nil if not needed.
 */
- (YTTFakeServerResponse *)YTTFakeServerClient:(id<NSURLProtocolClient>)client responseForRequest:(NSURLRequest *)request;

/**
 * Redirect URL for request.
 *
 * return URL If needed.
 */
- (NSURL *)YTTFakeServerClient:(id<NSURLProtocolClient>)client redirectURLForRequest:(NSURLRequest *)request;

/**
 * Custom responseData for request.
 * 
 * @note resposeData from bundle prior to this except for nil.
 */
- (NSData *)YTTFakeServerClient:(id<NSURLProtocolClient>)client responseDataForRequest:(NSURLRequest *)request;

/**
 * Custom error for request.
 */
- (NSError *)YTTFakeServerClient:(id<NSURLProtocolClient>)client errorForRequest:(NSURLRequest *)request;

@end

#pragma mark - YTTFakeServerConfiguration

@interface YTTFakeServerConfiguration : NSObject

/**
 * YTTFakeServerDelegate
 *
 * APIManager is recommended.
 */
@property (nonatomic, weak) id<YTTFakeServerDelegate> delegate;

/**
 * FakeServer's host names.
 *
 * It supports multiple hosts.
 */
@property (nonatomic, copy) NSArray *hosts;

/**
 * supported schemes
 *
 * default value is http, https
 */
@property (nonatomic, copy) NSArray *schemes;

/**
 * ignoring resource option.
 *
 * defalut value is jpg, png, css, js.
 */
@property (nonatomic, copy) NSArray *ignoringFileExtentions;

/**
 * response cacheStoragePolicy.
 * defalt value is `NSURLCacheStorageNotAllowed`
 */
@property (nonatomic, assign) NSURLCacheStoragePolicy cacheStoragePolicy;

/**
 * delayed response.
 */
@property (nonatomic, assign) NSTimeInterval delay;

/**
 * NSBundle which contains fake response data.
 */
@property (nonatomic, strong) NSBundle *resourceBundle;

/**
 * default value is json.
 */
@property (nonatomic, copy) NSString *resourceFileExtension;

/**
 * enabled Reachability option.
 *
 * defalut is YES
 */
@property (nonatomic, assign) BOOL enableReachabilityCheck;

+ (instancetype)sharedConfiguration;
- (void)resetConfiguration;

@end

#pragma mark - YTTFakeServer

@interface YTTFakeServer : NSURLProtocol

/**
 * configure options in configurationBlock.
 *
 */
+ (void)configure:(void (^)(YTTFakeServerConfiguration *configuration))configurationBlock;

@end
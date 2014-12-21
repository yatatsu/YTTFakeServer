//
//  YTTAPIManager.h
//  YTTFakeServer
//
//  Created by KITAGAWA Tatsuya on 2014/12/12.
//  Copyright (c) 2014年 yatatsu. All rights reserved.
//

#import "AFHTTPSessionManager.h"

#define YTTAPIHost  @"http://httpbin.org/"

@interface YTTAPIManager : AFHTTPSessionManager

+ (instancetype)sharedManager;

- (void)cancelAllTask;

@end

@interface YTTJSONRequestSerializer : AFJSONRequestSerializer

@end

# YTTFakeServer

[![CI Status](http://img.shields.io/travis/yatatsu/YTTFakeServer.svg?style=flat)](https://travis-ci.org/yatatsu/YTTFakeServer)
[![Version](https://img.shields.io/cocoapods/v/YTTFakeServer.svg?style=flat)](http://cocoadocs.org/docsets/YTTFakeServer)
[![License](https://img.shields.io/cocoapods/l/YTTFakeServer.svg?style=flat)](http://cocoadocs.org/docsets/YTTFakeServer)
[![Platform](https://img.shields.io/cocoapods/p/YTTFakeServer.svg?style=flat)](http://cocoadocs.org/docsets/YTTFakeServer)

YTTFakeServer is subClass for ``NSURLProtocol``. It returns stub HTTP response for ``NSURLConnection`` or ``NSURLSession`` request.

## Description

### Provides stub response

YTTFakeServer provides fake response for HTTP request. 
In most simple way to use, you will put bundle in your project, and set configuration with ``YTTFakeServerConfiguration``.
YTTFakeServer find the response data from bundle by request path, and return response with the data.
You can also set HTTPHeader, HTTPstatus with ``YTTFakeServerDelegate``.

### For test or mock development

YTTFakeServer is helper for not only test code.
Because it does not need to change the code of request part whether for test or for production, 
it helps you with mock development of HTTP request.

### Real connection

YTTFakeServer is subClass of ``NSURLProtocol``. You can alse use it for just mitmProxy with real connection.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### Basic

#### configure

First, configure with ``YTTFakeServerConfiguration``. You can set custom bundle.

```
[YTTFakeServer configure:^(YTTFakeServerConfiguration *configuration) {
    configuration.hosts = @["http://your.host/"];
    configuration.delegate = self; // delegate 
    configuration.delay = 1.0; // delay interval
    configuration.resourceBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"YourCustomBundle" ofType:@"bundle"]];
    configuration.resourceFileExtension = @"json"; // resource type
}];
``

For example, if you want to set response json with path like ``api/foo/bar``,
you just set bundle which has ``api/foo/bar.json``. It's very simple.

``YTTFakeServerConfiguration`` has other some options.

- ``schemes`` (default are http, https)
- ``ignoringFileExtentions`` (default are .jpg, .png, .css, .js)
- ``cacheStoragePolicy`` (default is ``NSURLCacheStorageNotAllowed``)
- ``enableReachabilityCheck`` (default is YES)

#### register Protocol

If you use ``NSURLConnection``, you need to register ``NSURLProtocol`` like this.

```
[NSURLProtocol registerClass:[YTTFakeServer class]];
``

If you use ``NSURLSession``, use ``NSURLSessionConfiguration``.

```
NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
sessionConfiguration.protocolClasses = @[[YTTFakeServer class]];
``

### Advanced 

``YTTFakeServerDelegate`` provides API for several usage.
For Example, ``YTTFakeServerClient:responseDataForRequest``, define different response data with each request.
Please check example project.

#### NOTE:

If you use NSURLSession, and you want to check HTTPBody, use ``NSURLProtocol:setProperty:forKey:inRequest``.
Please check the issue of [AliSoftware/OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs), [issue52](https://github.com/AliSoftware/OHHTTPStubs/issues/52)

## Requirements

It depends on [Reachability](https://github.com/tonymillion/Reachability) with a option.
So if you want to enable it, you also add ``SystemConfiguration.framework``.

## Installation

YTTFakeServer is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "YTTFakeServer"

## Contributing

1. Fork it!
2. Create your feature branch: ``git checkout -b my-new-feature``
3. Commit your changes: ``git commit -am 'Add some feature'``
4. Push to the branch: ``git push origin my-new-feature``
5. Submit a pull request :D

## Acknowledgment

YTTFakeServer inspired with these articles and libraries.

- [Infinite Blog - Using NSURLProtocol for Injecting Test Data](http://www.infinite-loop.dk/blog/2011/09/using-nsurlprotocol-for-injecting-test-data/)
- [InfiniteLoopDK/ILTesting](https://github.com/InfiniteLoopDK/ILTesting)
- [Effective web API testing on iOS](http://hackazach.net/code/2013/03/09/effective-web-API-testing-on-iOS/)
- [AliSoftware/OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs)

## Author

yatatsu, yatatsukitagawa@gmail.com

## License

YTTFakeServer is available under the MIT license. See the LICENSE file for more info.


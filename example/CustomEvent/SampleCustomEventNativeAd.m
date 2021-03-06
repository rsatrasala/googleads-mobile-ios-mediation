//
// Copyright (C) 2015 Google, Inc.
//
// SampleCustomEventNative.m
// Sample Ad Network Custom Event
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@import GoogleMobileAds;

#import "../SDK/SampleNativeAdLoader.h"
#import "../SDK/SampleNativeAdRequest.h"
#import "SampleCustomEventNativeAd.h"
#import "SampleMediatedNativeAppInstallAd.h"
#import "SampleMediatedNativeContentAd.h"

/// Constant for Sample Ad Network custom event error domain.
static NSString *const customEventErrorDomain = @"com.google.CustomEvent";

@interface SampleCustomEventNativeAd () <SampleNativeAdLoaderDelegate> {
  /// Native ad view options.
  GADNativeAdViewAdOptions *_nativeAdViewAdOptions;
}

@end

@implementation SampleCustomEventNativeAd

@synthesize delegate;

- (void)requestNativeAdWithParameter:(NSString *)serverParameter
                             request:(GADCustomEventRequest *)request
                             adTypes:(NSArray *)adTypes
                             options:(NSArray *)options
                  rootViewController:(UIViewController *)rootViewController {
  SampleNativeAdLoader *adLoader = [[SampleNativeAdLoader alloc] init];
  SampleNativeAdRequest *sampleRequest = [[SampleNativeAdRequest alloc] init];

  // Part of the custom event's job is to examine the properties of the GADCustomEventRequest and
  // create a request for the mediated network's SDK that matches them.
  //
  // Care needs to be taken to make sure the custom event respects the publisher's wishes in regard
  // to native ad formats. For example, if the mediated ad network only provides app install ads,
  // and the publisher requests content ads alone, the custom event must report an error by calling
  // the delegate's customEventNativeAd:didReceiveMediatedNativeAd: method with an error code set to
  // kGADErrorInvalidRequest. It should *not* request an app install ad anyway, and then attempt to
  // map it to the content ad format.
  for (NSString *adType in adTypes) {
    if ([adType isEqual:kGADAdLoaderAdTypeNativeContent]) {
      sampleRequest.contentAdsRequested = YES;
    } else if ([adType isEqual:kGADAdLoaderAdTypeNativeAppInstall]) {
      sampleRequest.appInstallAdsRequested = YES;
    }
  }

  // The Google Mobile Ads SDK requires the image assets to be downloaded automatically unless
  // the publisher specifies otherwise by using the GADNativeAdImageAdLoaderOptions object's
  // disableImageLoading property. If your network doesn't have an option like this and instead only
  // ever returns URLs for images (rather than the images themselves), your adapter should download
  // image assets on behalf of the publisher. This should be done after receiving the native ad
  // object from your network's SDK, and before calling the connector's
  // adapter:didReceiveMediatedNativeAd: method.
  sampleRequest.shouldDownloadImages = YES;

  sampleRequest.preferredImageOrientation = NativeAdImageOrientationAny;
  sampleRequest.shouldRequestMultipleImages = NO;

  for (GADAdLoaderOptions *loaderOptions in options) {
    if ([loaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
      GADNativeAdImageAdLoaderOptions *imageOptions =
          (GADNativeAdImageAdLoaderOptions *)loaderOptions;
      switch (imageOptions.preferredImageOrientation) {
        case GADNativeAdImageAdLoaderOptionsOrientationLandscape:
          sampleRequest.preferredImageOrientation = NativeAdImageOrientationLandscape;
          break;
        case GADNativeAdImageAdLoaderOptionsOrientationPortrait:
          sampleRequest.preferredImageOrientation = NativeAdImageOrientationPortrait;
          break;
        case GADNativeAdImageAdLoaderOptionsOrientationAny:
        default:
          sampleRequest.preferredImageOrientation = NativeAdImageOrientationAny;
          break;
      }

      sampleRequest.shouldRequestMultipleImages = imageOptions.shouldRequestMultipleImages;

      // If the GADNativeAdImageAdLoaderOptions' disableImageLoading property is YES, the adapter
      // should send just the URLs for the images.
      sampleRequest.shouldDownloadImages = !imageOptions.disableImageLoading;
    } else if ([loaderOptions isKindOfClass:[GADNativeAdViewAdOptions class]]) {
      _nativeAdViewAdOptions = (GADNativeAdViewAdOptions *)loaderOptions;
    }
  }

  // This custom event uses the server parameter to carry an ad unit ID, which is the most common
  // use case.
  adLoader.adUnitID = serverParameter;
  adLoader.delegate = self;

  [adLoader fetchAd:sampleRequest];
}

// Indicates if the custom event handles user clicks. Return YES if the custom event should handle
// user clicks.
- (BOOL)handlesUserClicks {
  return YES;
}

#pragma mark SampleNativeAdLoaderDelegate implementation

- (void)adLoader:(SampleNativeAdLoader *)adLoader
    didReceiveNativeAppInstallAd:(SampleNativeAppInstallAd *)nativeAppInstallAd {
  SampleMediatedNativeAppInstallAd *mediatedAd = [[SampleMediatedNativeAppInstallAd alloc]
      initWithSampleNativeAppInstallAd:nativeAppInstallAd
                                                  nativeAdViewAdOptions:_nativeAdViewAdOptions];
  [self.delegate customEventNativeAd:self didReceiveMediatedNativeAd:mediatedAd];
}

- (void)adLoader:(SampleNativeAdLoader *)adLoader
    didReceiveNativeContentAd:(SampleNativeContentAd *)nativeContentAd {
  SampleMediatedNativeContentAd *mediatedAd =
      [[SampleMediatedNativeContentAd alloc] initWithSampleNativeContentAd:nativeContentAd
                                                     nativeAdViewAdOptions:_nativeAdViewAdOptions];
  [self.delegate customEventNativeAd:self didReceiveMediatedNativeAd:mediatedAd];
}

- (void)adLoader:(SampleNativeAdLoader *)adLoader
    didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *error = [NSError errorWithDomain:customEventErrorDomain code:errorCode userInfo:nil];
  [self.delegate customEventNativeAd:self didFailToLoadWithError:error];
}

@end

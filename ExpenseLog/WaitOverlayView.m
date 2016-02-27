/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "WaitOverlayView.h"

@interface WaitOverlayView ()
@end

@implementation WaitOverlayView

+(instancetype) waitOverlayViewInView:(UIView *)parentView {
    WaitOverlayView *overlayView = [[WaitOverlayView alloc] initWithFrame:parentView.bounds];
    overlayView.opaque = NO;
    overlayView.userInteractionEnabled = NO;
    overlayView.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:0.7];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] init];
    activityIndicator.color = [UIColor blackColor];
    activityIndicator.center = CGPointMake(overlayView.bounds.size.width/2, overlayView.bounds.size.height/2);
    [overlayView addSubview:activityIndicator];
    [activityIndicator startAnimating];
    
    [parentView addSubview:overlayView];
    return overlayView;
}

@end

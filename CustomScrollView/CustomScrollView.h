//
//  CustomScrollView.h
//  ContinuousScrollingViewer
//
//  Created by USER on 12/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CustomScrollView;

@protocol CustomScrollViewDelegate
- (NSInteger)numberOfRowsInCustomScrollView:(CustomScrollView *)scrollView;
- (NSString *)customScrollView:(CustomScrollView *)scrollView contentForRow:(NSInteger)row;
- (BOOL)customScrollView:(CustomScrollView *)scrollView ClickOnRow:(NSInteger) row Url:(NSURL *) url;
@end


@interface CustomScrollView : UIScrollView <UIScrollViewDelegate, UIWebViewDelegate>
{
    UIView         *_containerView;
    NSInteger       _numberOfRow;
    NSMutableArray *_visibleUIWebViews;
    NSMutableArray *_visibleRows;
    NSInteger       _verticalGap;
    NSInteger       _horizontalGap;
    NSInteger       _currentRow;
    BOOL            _scrollDown;
}

@property (assign) id <CustomScrollViewDelegate> customDelegate;

- (void)Reload;
- (void)webViewsFromMinY:(CGFloat)minimumVisibleY toMaxY:(CGFloat)maximumVisibleY;
- (void)Next;
- (void)Previous;

@end

//
//  CustomScrollView.m
//  ContinuousScrollingViewer
//
//  Created by USER on 12/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CustomScrollView.h"

@implementation CustomScrollView
@synthesize customDelegate;

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height * 2);
        
        _scrollDown = TRUE;
        _currentRow = 0;
        _horizontalGap = 20;
        _verticalGap = 20;
        _numberOfRow = -1;
        _visibleUIWebViews = [[NSMutableArray alloc] init];
        _visibleRows = [[NSMutableArray alloc] init];
        _containerView = [[UIView alloc] init];
        _containerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
        [self addSubview:_containerView];
        [_containerView setUserInteractionEnabled:YES];
        
        [self setShowsVerticalScrollIndicator:NO];
    }
    return self;
}

#pragma mark -
#pragma mark Layout

- (void)recenterIfNecessary {
    CGPoint currentOffset = [self contentOffset];
    CGFloat contentHeight = [self contentSize].height;
    CGFloat centerOffsetY = (contentHeight - [self bounds].size.height) / 2.0;
    
        self.contentOffset = CGPointMake(currentOffset.x, centerOffsetY);
        
    CGFloat distance = (centerOffsetY - currentOffset.y);
    
    if([_visibleUIWebViews count]!=0)
    {
        NSInteger row = 0;    
        NSNumber *tempNum = [_visibleRows objectAtIndex:0];
        row = [tempNum integerValue];
        
        if(row == 0)
        {
            CGRect visibleBounds = [self convertRect:[self bounds] toView:_containerView];
            CGFloat minimumVisibleY = CGRectGetMinY(visibleBounds);
            UIWebView *webViewFast = [_visibleUIWebViews objectAtIndex:0];
            CGPoint position = [_containerView convertPoint:webViewFast.frame.origin toView:self];
            position.y += distance;
            
            if(position.y > minimumVisibleY)
            {
                distance -= (position.y - minimumVisibleY); 
            }
        }
        
        tempNum = [_visibleRows lastObject];
        row = [tempNum integerValue];
        
        if(row == _numberOfRow - 1)
        {
            CGRect visibleBounds = [self convertRect:[self bounds] toView:_containerView];
            CGFloat maximumVisibleY = CGRectGetMaxY(visibleBounds);
            UIWebView *webViewFast = [_visibleUIWebViews lastObject];
            CGPoint position = [_containerView convertPoint:webViewFast.frame.origin toView:self];
            position.y += webViewFast.frame.size.height;
            position.y += distance;
            
            if(position.y < maximumVisibleY)
            {
                distance -= (position.y - maximumVisibleY); 
            }
        }
        
        if(distance<=0)
            _scrollDown = YES;
        else
            _scrollDown = NO;
    }
    
    for (UIWebView *webView in _visibleUIWebViews) {
            CGPoint center = [_containerView convertPoint:webView.center toView:self];
            center.y += distance;
            webView.center = [self convertPoint:center toView:_containerView];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if(customDelegate != nil)
    {
        if(_numberOfRow == -1)
            _numberOfRow = [customDelegate numberOfRowsInCustomScrollView:self];
        
        
    [self recenterIfNecessary];
    
    
    CGRect visibleBounds = [self convertRect:[self bounds] toView:_containerView];
    CGFloat minimumVisibleY = CGRectGetMinY(visibleBounds);
    CGFloat maximumVisibleY = CGRectGetMaxY(visibleBounds);
    
    [self webViewsFromMinY:minimumVisibleY toMaxY:maximumVisibleY];
    }
}

- (void) Reload
{
    
    while ([_visibleUIWebViews count]!=0) {
        UIWebView *firstWebView = [_visibleUIWebViews objectAtIndex:0];
        [firstWebView removeFromSuperview];
        [_visibleUIWebViews removeObjectAtIndex:0];
        [_visibleRows removeObjectAtIndex:0];
    }    
    
    _scrollDown = TRUE;
    _currentRow = 0;
    _numberOfRow = [customDelegate numberOfRowsInCustomScrollView:self];
    [self layoutSubviews];
}

- (UIWebView *)insertWebViewForRow:(NSInteger) row {
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(_horizontalGap, 0, self.contentSize.width - 2 * _horizontalGap, 40)];
    [webView loadHTMLString:[NSString stringWithFormat:@"%@<br/><br/>",[customDelegate customScrollView:self contentForRow:row]] baseURL:nil];
    [_containerView addSubview:webView];

    [(UIScrollView*)[webView.subviews objectAtIndex:0] setShowsHorizontalScrollIndicator:NO];
    [(UIScrollView*)[webView.subviews objectAtIndex:0] setShowsVerticalScrollIndicator:NO];
    ((UIScrollView*)[webView.subviews objectAtIndex:0]).scrollEnabled = FALSE;
    
    webView.delegate = self;
    
    return webView;
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
    NSNumber *tempNum = (NSNumber *)[theWebView stringByEvaluatingJavaScriptFromString: @"document.body.offsetHeight"];
    NSInteger height = [tempNum integerValue];
    
    NSInteger differ = 0;
    BOOL hasUpdate = FALSE;
    
    if(_scrollDown == TRUE)
    {
    for (UIWebView *webView in _visibleUIWebViews) {
        if(webView == theWebView)
        {
            differ = height - webView.frame.size.height;
            
            CGRect temp = webView.frame;
            temp.size.height = height;
            webView.frame = temp;
            hasUpdate = TRUE;
        }
        else if(hasUpdate == YES)
        {
            CGRect temp = webView.frame;
            temp.origin.y += differ;
            webView.frame = temp;
        }
    }
    }
    else
    {
        for (int i=[_visibleUIWebViews count]-1;i>=0;i--) {
            UIWebView *webView = [_visibleUIWebViews objectAtIndex:i];
            
            if(webView == theWebView)
            {
                differ = height - webView.frame.size.height;
                
                CGRect temp = webView.frame;
                temp.origin.y -= differ;
                temp.size.height = height;
                webView.frame = temp;
                hasUpdate = TRUE;
            }
            else if(hasUpdate == YES)
            {
                CGRect temp = webView.frame;
                temp.origin.y -= differ;
                webView.frame = temp;
            }
        }
    }
}


-(BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    //CAPTURE USER LINK-CLICK.
    
    if(navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        NSURL *url = [request URL];
        
        NSInteger row = 0,i=0;
        
        for (UIWebView *webView1 in _visibleUIWebViews) 
        {
            if(webView1 == webView)
            {
                NSNumber *temp = [_visibleRows objectAtIndex:i];
                row = [temp integerValue];
                break;
            }
            i++;
        }
        
        return [customDelegate customScrollView:self ClickOnRow:row Url:url];
    }
    else
        return YES;   
}

- (CGFloat)placeNewWebViewOnDown:(CGFloat)downEdge {
    NSInteger row = _currentRow;
    
    if([_visibleRows count]!=0)
    {
        NSNumber *tempNum = [_visibleRows lastObject];
        row = [tempNum integerValue] + 1;
        
        if(row >= _numberOfRow)
            row = _numberOfRow - 1;
    }
    
    UIWebView *webView = [self insertWebViewForRow:row];
    [_visibleUIWebViews addObject:webView];
    [_visibleRows addObject:[[NSNumber alloc] initWithInteger:row]];
    
    CGRect frame = [webView frame];
    frame.origin.y = downEdge;
    [webView setFrame:frame];
    
    return CGRectGetMaxY(frame);
}

- (CGFloat)placeNewWebViewOnUp:(CGFloat)upEdge {
    NSInteger row = 0;
    
    if([_visibleRows count]!=0)
    {
        NSNumber *tempNum = [_visibleRows objectAtIndex:0];
        row = [tempNum integerValue] - 1;
        
        if(row < 0)
            row = 0;
    }
    
    UIWebView *webView = [self insertWebViewForRow:row];
    [_visibleUIWebViews insertObject:webView atIndex:0]; // add rightmost label at the end of the array
    [_visibleRows insertObject:[[NSNumber alloc] initWithInteger:row] atIndex:0];
    
    CGRect frame = [webView frame];
    frame.origin.y = upEdge - frame.size.height;
    [webView setFrame:frame];
    
    return CGRectGetMinY(frame);
}

- (void)webViewsFromMinY:(CGFloat)minimumVisibleY toMaxY:(CGFloat)maximumVisibleY {
    
    if ([_visibleUIWebViews count] == 0) {
        [self placeNewWebViewOnDown:minimumVisibleY];
    }
    
    BOOL addInDown = FALSE,addInUp = FALSE;
    
    
    UIWebView *lastWebView = [_visibleUIWebViews lastObject];
    CGFloat downEdge = CGRectGetMaxY([lastWebView frame]) + _verticalGap;

    while (downEdge < maximumVisibleY) {
        
        NSInteger row = 0;    
        NSNumber *tempNum = [_visibleRows lastObject];
        row = [tempNum integerValue];
        
        if(row == _numberOfRow - 1)
            break;
        
        downEdge = [self placeNewWebViewOnDown:downEdge] + _verticalGap;
        addInDown = TRUE;
    }
    
    UIWebView *firstWebView = [_visibleUIWebViews objectAtIndex:0];
    CGFloat upEdge = CGRectGetMinY([firstWebView frame]) - _verticalGap;
    while (upEdge > minimumVisibleY) {
        
        NSInteger row = 0;    
        NSNumber *tempNum = [_visibleRows objectAtIndex:0];
        row = [tempNum integerValue];
        
        if(row == 0)
            break;
        
        upEdge = [self placeNewWebViewOnUp:upEdge] - _verticalGap;
        addInUp = TRUE;
    }
    
    lastWebView = [_visibleUIWebViews lastObject];
    
    if(addInUp == TRUE)
    while ([lastWebView frame].origin.y > maximumVisibleY) {
        [lastWebView removeFromSuperview];
        [_visibleUIWebViews removeLastObject];
        [_visibleRows removeLastObject];
        lastWebView = [_visibleUIWebViews lastObject];
    }
    
    firstWebView = [_visibleUIWebViews objectAtIndex:0];
    
    if(addInDown == TRUE)
    while (CGRectGetMaxY([firstWebView frame]) < minimumVisibleY) {
        [firstWebView removeFromSuperview];
        [_visibleUIWebViews removeObjectAtIndex:0];
        [_visibleRows removeObjectAtIndex:0];
        firstWebView = [_visibleUIWebViews objectAtIndex:0];
    }
}

- (void)Next
{
    _scrollDown = TRUE;
    CGRect visibleBounds = [self convertRect:[self bounds] toView:_containerView];
    CGFloat minimumVisibleY = CGRectGetMinY(visibleBounds);
    NSInteger currentRow=0,i=0;
    
    for (UIWebView *webView in _visibleUIWebViews) {
        CGPoint center = [_containerView convertPoint:webView.frame.origin toView:self];
        if(minimumVisibleY < center.y + webView.frame.size.height)
        {
            NSNumber *temp = [_visibleRows objectAtIndex:i];
            currentRow = [temp integerValue];
            break;
        }
        i++;
    }
    
    if(currentRow + 1 !=_numberOfRow)
        currentRow++;
    
    while ([_visibleUIWebViews count]!=0) {
        UIWebView *firstWebView = [_visibleUIWebViews objectAtIndex:0];
        [firstWebView removeFromSuperview];
        [_visibleUIWebViews removeObjectAtIndex:0];
        [_visibleRows removeObjectAtIndex:0];
    }    
    
    _currentRow = currentRow;
    [self layoutSubviews];
}

- (void)Previous
{
    _scrollDown = TRUE;
    CGRect visibleBounds = [self convertRect:[self bounds] toView:_containerView];
    CGFloat minimumVisibleY = CGRectGetMinY(visibleBounds);
    NSInteger currentRow=0,i=0;
    
    for (UIWebView *webView in _visibleUIWebViews) {
        CGPoint center = [_containerView convertPoint:webView.frame.origin toView:self];
        if(minimumVisibleY < center.y + webView.frame.size.height)
        {
            NSNumber *temp = [_visibleRows objectAtIndex:i];
            currentRow = [temp integerValue];
            break;
        }
        i++;
    }
    
    if(currentRow!=0)
        currentRow--;
    
    while ([_visibleUIWebViews count]!=0) {
            UIWebView *firstWebView = [_visibleUIWebViews objectAtIndex:0];
            [firstWebView removeFromSuperview];
            [_visibleUIWebViews removeObjectAtIndex:0];
            [_visibleRows removeObjectAtIndex:0];
        }    
    
    _currentRow = currentRow;
    [self layoutSubviews];
}

@end

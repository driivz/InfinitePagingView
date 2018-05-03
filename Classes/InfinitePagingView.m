//
//  InfinitePagingView.m
//  InfinitePagingView
//
//  Created by SHIGETA Takuji
//

/*
 The MIT License (MIT)
 
 Copyright (c) 2012 SHIGETA Takuji
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "InfinitePagingView.h"

@interface InfinitePagingView ()

@property(nonatomic, weak)   UIScrollView *innerScrollView;
@property(nonatomic, strong) NSMutableArray *pageViews;
@property(nonatomic, assign) NSInteger lastPageIndex;

@end

@implementation InfinitePagingView

- (void)setFrame:(CGRect)frame {
    super.frame = frame;
    if (!self.innerScrollView) {
        _currentPageIndex = 0;
        self.userInteractionEnabled = YES;
        self.clipsToBounds = YES;
        CGRect bounds = CGRectZero;
        bounds.size = frame.size;
        
        UIScrollView *innerScrollView = [[UIScrollView alloc] initWithFrame:bounds];
        innerScrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
        innerScrollView.delegate = self;
        innerScrollView.backgroundColor = [UIColor clearColor];
        innerScrollView.clipsToBounds = NO;
        innerScrollView.pagingEnabled = YES;
        innerScrollView.scrollEnabled = YES;
        innerScrollView.showsHorizontalScrollIndicator = NO;
        innerScrollView.showsVerticalScrollIndicator = NO;
        innerScrollView.scrollsToTop = NO;
        [self addSubview:innerScrollView];
        _innerScrollView = innerScrollView;
        
        _scrollDirection = InfinitePagingViewHorizonScrollDirection;
        _pageSize = frame.size;
        
        _pageViews = [NSMutableArray array];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if ([hitView isKindOfClass:[UIButton class]]) {
        return hitView;
    }
    else if (nil != hitView) {
        return self.innerScrollView;
    }
    
    return nil;
}

#pragma mark - Public methods

- (void)addPageView:(UIView *)pageView {
    pageView.tag = _pageViews.count;
    [_pageViews addObject:pageView];
    [self updatePosition];
    [self layoutPages];
}

- (void)removeAllPages {
    [self.pageViews enumerateObjectsUsingBlock:^(UIView *pageView, NSUInteger idx, BOOL * _Nonnull stop) {
        [pageView removeFromSuperview];
    }];
    
    [_pageViews removeAllObjects];
    [self updatePosition];
    [self layoutPages];
}

- (void)scrollToPreviousPage {
    [self scrollToPageToDirection:InfiniteScrollDirectionBack];
}

- (void)scrollToNextPage {
    [self scrollToPageToDirection:InfiniteScrollDirectionForward];
}

- (void)scrollToPageToDirection:(InfiniteScrollDirection)direction {
    __weak typeof(self) weak = self;
    [UIView animateWithDuration:0.3 animations:^{
        [weak scrollBy:direction animated:NO];
    } completion:^(BOOL finished) {
        [weak scrollViewDidEndDecelerating:weak.innerScrollView];
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutPages];
}

#pragma mark - Private methods

- (void)layoutPages {
    if (self.scrollDirection == InfinitePagingViewHorizonScrollDirection) {
        CGFloat left_margin = (self.frame.size.width - self.pageSize.width) * 0.5;
        self.innerScrollView.frame = CGRectMake(left_margin, 0.0, self.pageSize.width, self.frame.size.height);
        self.innerScrollView.contentSize = CGSizeMake(self.frame.size.width * self.pageViews.count, self.frame.size.height);
    } else {
        CGFloat top_margin  = (self.frame.size.height - self.pageSize.height) * 0.5;
        self.innerScrollView.frame = CGRectMake(0.0, top_margin, self.frame.size.width, self.pageSize.height);
        self.innerScrollView.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height * self.pageViews.count);
    }
    
    [self.pageViews enumerateObjectsUsingBlock:^(UIView *pageView, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.scrollDirection == InfinitePagingViewHorizonScrollDirection) {
            pageView.center = CGPointMake((idx * (self.innerScrollView.frame.size.width) + (self.innerScrollView.frame.size.width * 0.5)),
                                          self.innerScrollView.center.y);
        }
        else {
            pageView.center = CGPointMake(self.innerScrollView.center.x,
                                          (idx * (self.innerScrollView.frame.size.height) + (self.innerScrollView.frame.size.height * 0.5)));
        }
        
        [self.innerScrollView addSubview:pageView];
    }];
    
    if (self.scrollDirection == InfinitePagingViewHorizonScrollDirection) {
        self.innerScrollView.contentSize = CGSizeMake(self.pageViews.count * self.innerScrollView.frame.size.width,
                                                      self.frame.size.height);
        self.innerScrollView.contentOffset = CGPointMake(self.pageSize.width * self.lastPageIndex, 0.0);
    }
    else {
        self.innerScrollView.contentSize = CGSizeMake(self.innerScrollView.frame.size.width,
                                                      self.pageSize.height * self.pageViews.count);
        self.innerScrollView.contentOffset = CGPointMake(0.0, self.pageSize.height * self.lastPageIndex);
    }
}

- (void)updatePosition {
    _lastPageIndex = floor(self.pageViews.count * 0.5);
    _currentPageIndex = _lastPageIndex;
}

- (void)scrollTo:(NSUInteger)pageIndex animated:(BOOL)animated {
    CGRect adjustScrollRect;
    if (self.scrollDirection == InfinitePagingViewHorizonScrollDirection) {
        if (fmodf(self.innerScrollView.contentOffset.x, self.pageSize.width) != 0) {
            return;
        }
        
        adjustScrollRect = CGRectMake(self.innerScrollView.frame.size.width * pageIndex,
                                      self.innerScrollView.contentOffset.y,
                                      self.innerScrollView.frame.size.width, self.innerScrollView.frame.size.height);
    }
    else {
        if (fmodf(self.innerScrollView.contentOffset.y, self.pageSize.height) != 0) {
            return;
        }
        
        adjustScrollRect = CGRectMake(self.innerScrollView.contentOffset.x,
                                      self.innerScrollView.frame.size.height * pageIndex,
                                      self.innerScrollView.frame.size.width, self.innerScrollView.frame.size.height);
        
    }
    
    _lastPageIndex = pageIndex;
    _currentPageIndex = pageIndex;
    
    [self.innerScrollView scrollRectToVisible:adjustScrollRect animated:animated];
    
    [self layoutPages];
}

- (void)scrollBy:(InfiniteScrollDirection)direction animated:(BOOL)animated {
    CGRect adjustScrollRect;
    if (self.scrollDirection == InfinitePagingViewHorizonScrollDirection) {
        if (fmodf(self.innerScrollView.contentOffset.x, self.pageSize.width) != 0) {
            return;
        }
        
        adjustScrollRect = CGRectMake(self.innerScrollView.contentOffset.x - self.innerScrollView.frame.size.width * direction,
                                      self.innerScrollView.contentOffset.y,
                                      self.innerScrollView.frame.size.width, self.innerScrollView.frame.size.height);
    }
    else {
        if (fmodf(self.innerScrollView.contentOffset.y, self.pageSize.height) != 0) {
            return;
        }
        
        adjustScrollRect = CGRectMake(self.innerScrollView.contentOffset.x,
                                      self.innerScrollView.contentOffset.y - self.innerScrollView.frame.size.height * direction,
                                      self.innerScrollView.frame.size.width, self.innerScrollView.frame.size.height);
        
    }
    
    [self.innerScrollView scrollRectToVisible:adjustScrollRect animated:animated];
}

#pragma mark - UIScrollViewself.delegate methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(pagingView:willBeginDragging:)]) {
        [self.delegate pagingView:self willBeginDragging:self.innerScrollView];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(pagingView:didScroll:)]) {
        [self.delegate pagingView:self didScroll:self.innerScrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([self.delegate respondsToSelector:@selector(pagingView:didEndDragging:)]) {
        [self.delegate pagingView:self didEndDragging:self.innerScrollView];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(pagingView:willBeginDecelerating:)]) {
        [self.delegate pagingView:self willBeginDecelerating:self.innerScrollView];
    }
}

- (NSInteger)pageTagAtLocation:(CGPoint)location {
    NSInteger tag = NSNotFound;
    CGPoint point = [self.innerScrollView convertPoint:location fromView:self];
    for (UIView *page in self.pageViews) {
        if (CGRectContainsPoint(page.frame, point)) {
            tag = page.tag;
            break;
        }
    }
    
    return tag;
}

- (CGPoint)locationForPageTag:(NSInteger)pageTag {
    UIView *page = self.pageViews[pageTag];
    return page.frame.origin;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger pageIndex = 0;
    if (self.scrollDirection == InfinitePagingViewHorizonScrollDirection) {
        pageIndex = self.innerScrollView.contentOffset.x / self.innerScrollView.frame.size.width;
    }
    else {
        pageIndex = self.innerScrollView.contentOffset.y / self.innerScrollView.frame.size.height;
    }
    
    if (pageIndex == self.lastPageIndex) {
        return;
    }
    
    NSInteger moveDirection = pageIndex - self.lastPageIndex;
    
    if (moveDirection >= InfiniteScrollDirectionBack) {
        for (NSUInteger i = 0; i < moveDirection; ++i) {
            UIView *leftView = (self.pageViews).firstObject;
            [self.pageViews removeObjectAtIndex:0];
            [self.pageViews insertObject:leftView atIndex:self.pageViews.count];
        }
    }
    else if (moveDirection <= InfiniteScrollDirectionForward) {
        for (NSInteger i = 0; i > moveDirection; --i) {
            UIView *rightView = (self.pageViews).lastObject;
            [self.pageViews removeLastObject];
            [self.pageViews insertObject:rightView atIndex:0];
        }
    }
    
    [self.pageViews enumerateObjectsUsingBlock:^(UIView *pageView , NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.scrollDirection == InfinitePagingViewHorizonScrollDirection) {
            pageView.center = CGPointMake(idx * self.innerScrollView.frame.size.width + self.innerScrollView.frame.size.width * 0.5,
                                          self.innerScrollView.center.y);
        }
        else {
            pageView.center = CGPointMake(self.innerScrollView.center.x,
                                          idx * (self.innerScrollView.frame.size.height) + (self.innerScrollView.frame.size.height * 0.5));
        }
    }];
    
    [self scrollBy:moveDirection animated:NO];
    
    pageIndex -= moveDirection;
    
    if (pageIndex > self.pageViews.count - 1) {
        pageIndex = self.pageViews.count - 1;
    }
    
    self.lastPageIndex = pageIndex;
    
    if ([self.delegate respondsToSelector:@selector(pagingView:didEndDecelerating:atPageIndex:)]) {
        _currentPageIndex += moveDirection;
        if (self.currentPageIndex < 0) {
            _currentPageIndex = self.pageViews.count - 1;
        }
        else if (self.currentPageIndex >= self.pageViews.count) {
            _currentPageIndex = 0;
        }
        
        [self.delegate pagingView:self didEndDecelerating:self.innerScrollView atPageIndex:self.currentPageIndex];
    }
}

@end

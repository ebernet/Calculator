//
//  GraphView.h
//  Calculator
//
//  Created by Eytan Bernet on 7/12/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GraphView;

@protocol GraphViewDataSource
- (id)yForGraphView:(GraphView *)sender fromXValue:(CGFloat)x;  // id to allow for NAN
@end

@interface GraphView : UIView

- (void)loadDefaults;

@property (nonatomic) CGFloat scale; // this is the scale that the graph will show
@property (nonatomic) CGPoint graphOrigin; // this is the origin of the graph
@property (nonatomic) BOOL drawSegmented; // This decides which drawing mode you use.

@property (nonatomic, weak) id <GraphViewDataSource> dataSource;

@end

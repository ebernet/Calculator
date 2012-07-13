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
- (CGFloat)yForGraphView:(GraphView *)sender fromXValue:(CGFloat)x;
@end

@interface GraphView : UIView

@property (nonatomic, weak) id <GraphViewDataSource> dataSource;

@end

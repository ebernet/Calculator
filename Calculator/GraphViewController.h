//
//  GraphViewController.h
//  Calculator
//
//  Created by Eytan Bernet on 7/12/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SplitViewBarButtonItemPresenter.h"

@interface GraphViewController : UIViewController <SplitViewBarButtonItemPresenter>

@property (nonatomic, strong) id program;

@end

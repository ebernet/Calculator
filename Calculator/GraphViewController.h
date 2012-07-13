//
//  GraphViewController.h
//  Calculator
//
//  Created by Eytan Bernet on 7/12/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GraphViewController : UIViewController

@property (nonatomic, strong) id program;
@property (weak, nonatomic) IBOutlet UILabel *graphEquation;

@end

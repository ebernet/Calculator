//
//  CalculatorProgramsTableViewController.h
//  Calculator
//
//  Created by Eytan Bernet on 7/16/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CalculatorProgramsTableViewController;

@protocol CalculatorProgramsTableViewControllerDelegate <NSObject> // NSObject is needed if you want to support respondsToSelector:
@optional
- (void)calculatorProgramsTableViewController:(CalculatorProgramsTableViewController *)sender choseProgram:(id)program;
- (void)calculatorProgramsTableViewController:(CalculatorProgramsTableViewController *)sender
                               deletedProgram:(id)program; // added after lecture to support deleting from table
@end

@interface CalculatorProgramsTableViewController : UITableViewController
@property (nonatomic, strong) NSArray *programs; // of CalculatorBrain programs;
@property (nonatomic, weak) id <CalculatorProgramsTableViewControllerDelegate> delegate;
@end

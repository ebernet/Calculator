//
//  CalculatorBrain.h
//  Calculator
//
//  Created by Eytan Bernet on 6/4/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CalculatorBrain : NSObject

- (void)pushOperand:(double)operand;
- (double)performOperation:(NSString *)operation;

// Added in homework 1
- (void)clearBrain; // The API for the clear button

// Added in prep for homework 2
@property (readonly) id program;

// Recursive. Returns result of operation recursively. Could be an operation or a program
+ (double)runProgram:(id)program;
+ (NSString *)descriptionOfProgram:(id)program;

// Added in homework 2

@end

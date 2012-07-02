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

- (void)clearBrain; // The API for the clear button

@end

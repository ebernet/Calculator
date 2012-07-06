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
- (id)performOperation:(NSString *)operation;

// Added in homework 1
- (void)clearBrain; // The API for the clear button

// Added in prep for homework 2
@property (readonly) id program;

// Recursive. Returns result of operation recursively. Could be an operation or a program
+ (id)runProgram:(id)program;

// Added in homework 2
+ (id)runProgram:(id)program usingVariableValues:(NSDictionary *)variableValues;
+ (NSString *)descriptionOfProgram:(id)program;
+ (NSSet *)variablesUsedInProgram:(id)program;

// Utility methods to validate operations supported by brain. Brain could always be expanded to support more.
// Like this, a calculator view can intorregate the brain to see what is supported (although using this method,
// Reality is that the brain will just validate what is supported. Would make more sense to have brain publish the type of operations supported,
// Like that you could ask it to give you an array of supported operations
+ (BOOL)isOperation:(NSString *)operation;
+ (BOOL)isSingleOpOperation:(NSString *)operation;
+ (BOOL)isDoubleOpOperation:(NSString *)operation;
+ (BOOL)isNoOpOperation:(NSString *)operation;

// Added to allow variables to be pushed
- (void)pushVariable:(NSString *)variable;

// part 4, undo
- (void)undo;

@end

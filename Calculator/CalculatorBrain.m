//
//  CalculatorBrain.m
//  Calculator
//
//  Created by Eytan Bernet on 6/4/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import "CalculatorBrain.h"

@interface CalculatorBrain()
@property (nonatomic, strong) NSMutableArray *programStack;
@end

@implementation CalculatorBrain

// Changed operandStack to programStack. Allows for recursively having programs as operands...
@synthesize programStack = _programStack;

- (NSMutableArray *)programStack
{
    if (_programStack == nil) _programStack = [[NSMutableArray alloc] init];
    return _programStack;
}

- (void)setProgramStack:(NSMutableArray *)programStack
{
    _programStack = programStack;
}

- (void)pushOperand:(double)operand;
{
    [self.programStack addObject:[NSNumber numberWithDouble:operand]];
}

// Got rid of popOperand. Does not work anymore since we changed the implementation

// program cannot return the actual programStack, we need to return a immutable copy of it...
- (id)program
{
    return [self.programStack copy];
}

+ (NSString *)descriptionOfProgram:(id)program
{
    return @"implement in homework 2";
}

- (double)performOperation:(NSString *)operation;
{
    // Removed the logic that does the actual calculation. Instead, now PUSH the new operation...
    [self.programStack addObject:operation];
    // And then run the new program. It will have to see if something is an operation (in which case, evaluate it); or
    // another program, in which case, runProgram on it...
    return [CalculatorBrain runProgram:self.program];
}

// This will recursively pop numbers or operations off the stack
+ (double)popOperandOffStack:(NSMutableArray *)stack
{
    double result = 0;
    
    id topOfStack = [stack lastObject];         // We want to use introspection on the top of the stack
    if (topOfStack) [stack removeLastObject];   // and if there is a topOfStack, we remove it (remember, we wanted to consume the array
    // Note that we can still run the code below, because it will only be called if there was an element (we can send methods to nil in Obj-C)
    
    // If the last item we are looking at is a number, return it as a double
    if ([topOfStack isKindOfClass:[NSNumber class]]) {
        result = [topOfStack doubleValue];
    // and if the last item is a string, it is probably an operation (although it may be a variable, as we will find in the homework
    } else if ([topOfStack isKindOfClass:[NSString class]]) {
        NSString *operation = topOfStack;
        if ([operation isEqualToString:@"+"]) {
            result = [self popOperandOffStack:stack] + [self popOperandOffStack:stack];
        } else if ([@"×" isEqualToString:operation]) {
            result = [self popOperandOffStack:stack] * [self popOperandOffStack:stack];
        } else if ([@"÷" isEqualToString:operation]) {  // Order of operations IS important for divide and -
            // Protect against divide by 0
            double divisor = [self popOperandOffStack:stack];
            if (divisor != 0) result = [self popOperandOffStack:stack] / divisor;
         } else if ([@"−" isEqualToString:operation]) {
            // Negate the 1st operand popped to achieve proper order
            result = -[self popOperandOffStack:stack] + [self popOperandOffStack:stack];
        } else if ([@"sin" isEqualToString:operation]) {
            result = sin([self popOperandOffStack:stack]);
        } else if ([@"cos" isEqualToString:operation]) {
            result = cos([self popOperandOffStack:stack]);
        } else if ([@"√" isEqualToString:operation]) {
            // Comment sqrt of negatives fix
            double operand = [self popOperandOffStack:stack];
            if (operand > 0)
                result = sqrt(operand);
        } else if ([@"π" isEqualToString:operation]) {
            result = M_PI;
        } else if ([@"±" isEqualToString:operation]) {
            result = -[self popOperandOffStack:stack];
        }
    }
    return result;
}

+ (double)runProgram:(id)program
{
    // We want to consume the program stack, so as we can do the recursion, so...
    NSMutableArray *stack;
    // If what was passed to us was aprogram, make a copy we can consume (mutableCopy achieves that)
    if ([program isKindOfClass:[NSArray class]]) {
        stack = [program mutableCopy];
    }
    // This allows us to pop the operation off the stack and
    return [self popOperandOffStack:stack];
}

- (void)clearBrain
{
    // Clear everything on the stack
    [self.programStack removeAllObjects];
    self.programStack = nil; // Not really necessary, but cleaner
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"stack = %@", self.programStack];
}
@end

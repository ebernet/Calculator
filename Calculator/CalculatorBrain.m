//
//  CalculatorBrain.m
//  Calculator
//
//  Created by Eytan Bernet on 6/4/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import "CalculatorBrain.h"

@interface CalculatorBrain()
@property (nonatomic, strong) NSMutableArray *operandStack;
@end

@implementation CalculatorBrain

@synthesize operandStack = _operandStack;

- (NSMutableArray *)operandStack
{
    if (_operandStack == nil) _operandStack = [[NSMutableArray alloc] init];
    return _operandStack;
}

- (void)clearBrain
{
    // Clear everything on the stack
    [self.operandStack removeAllObjects];
    self.operandStack = nil; // Not really necessary, but cleaner
    // In reality, probably not need to removeAllObjects, but cleaner - in a more sophisticated program, something else might have
    // links to items in the array, and setting the array to nil without removing the elements could cause a leak.
}

- (void)setOperandStack:(NSMutableArray *)operandStack
{
    _operandStack = operandStack;
}

- (void)pushOperand:(double)operand;
{
    [self.operandStack addObject:[NSNumber numberWithDouble:operand]];
}

- (double)popOperand
{
    NSNumber *operandObject = [self.operandStack lastObject];
    if (operandObject) [self.operandStack removeLastObject];
    return [operandObject doubleValue];
}
- (double)performOperation:(NSString *)operation;
{
    double result = 0;
    
    // For plus, order of operations is irrelevent
    if ([operation isEqualToString:@"+"]) {
        result = [self popOperand] + [self popOperand];
    } else if ([@"*" isEqualToString:operation]) {
        result = [self popOperand] * [self popOperand];
    } else if ([@"/" isEqualToString:operation]) {  // Order of operations IS important for divide and -
        // Protect against divide by 0
        double divisor = [self popOperand];
        if (divisor != 0) {
            result =  [self popOperand] / divisor;
        } else {
            result = 0;
        }
    } else if ([@"-" isEqualToString:operation]) {
        // Negate the 1st operand popped to achieve proper order
        result = -[self popOperand] + [self popOperand];
    } else if ([@"sin" isEqualToString:operation]) {
        result = sin([self popOperand]);
    } else if ([@"cos" isEqualToString:operation]) {
        result = cos([self popOperand]);
    } else if ([@"sqrt" isEqualToString:operation]) {
        // Xomment sqrt of negatives fix
        double operand = [self popOperand];
        if (operand > 0)
            result = sqrt(operand);
    } else if ([@"π" isEqualToString:operation]) {
        result = M_PI;
    } else if ([@"+/-" isEqualToString:operation]) {
        result = -[self popOperand];
    }

    [self pushOperand:result];
    
    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"stack = %@", self.operandStack];
}
@end

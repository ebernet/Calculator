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

#pragma mark setters and getters

- (NSMutableArray *)programStack
{
    if (_programStack == nil) _programStack = [[NSMutableArray alloc] init];
    return _programStack;
}

- (void)setProgramStack:(NSMutableArray *)programStack
{
    _programStack = programStack;
}

// program cannot return the actual programStack, we need to return a immutable copy of it...
- (id)program
{
    return [self.programStack copy];
}

#pragma mark helper methods for checking for what is on the stack

+ (BOOL)isOperation:(NSString *)operation
{
    NSSet *operationSet = [[NSSet alloc] initWithObjects:@"sin",@"cos",@"√",@"×",@"÷",@"+",@"−",@"π",@"±",@"e",@"log",nil];
    return [operationSet containsObject:operation];
}

+ (BOOL)isSingleOpOperation:(NSString *)operation
{
    NSSet *operationSet = [[NSSet alloc] initWithObjects:@"sin",@"cos",@"√",@"log",@"±",nil];
    return [operationSet containsObject:operation];
}

+ (BOOL)isDoubleOpOperation:(NSString *)operation
{
    NSSet *operationSet = [[NSSet alloc] initWithObjects:@"×",@"÷",@"+",@"−",nil];
    return [operationSet containsObject:operation];
}

+ (BOOL)isNoOpOperation:(NSString *)operation
{
    NSSet *operationSet = [[NSSet alloc] initWithObjects:@"π",@"e",nil];
    return [operationSet containsObject:operation];
}

+ (BOOL)isErrorCondition:(NSString *)topOfStack
{
    NSSet *errorSet = [[NSSet alloc] initWithObjects:@"Divide By Zero",@"sqrt of negative",@"Insufficient Operands", nil];
    return [errorSet containsObject:topOfStack];
}

#pragma mark stack manipulations

// undo is the old popOperand, but don't return anything
- (void)undo
{
    if (self.programStack.count > 0) [self.programStack removeLastObject];
}

// pushOperand gets the values on the stack...
- (void)pushOperand:(double)operand
{
    [self.programStack addObject:[NSNumber numberWithDouble:operand]];
}

// performOperation gets the operation on the stack, and evaluates the result
- (id)performOperation:(NSString *)operation;
{
    // Removed the logic that does the actual calculation. Instead, now PUSH the new operation...
    [self.programStack addObject:operation];
    // And then run the new program. It will have to see if something is an operation (in which case, evaluate it); or
    // another program, in which case, runProgram on it...
    return [[self class] runProgram:self.program];
}

// And now in homework 2, pushVariable is similar to pushOperand, but put a string (the variable name) on the stack... We check to see if it is indeed not an operation
- (void)pushVariable:(NSString *)variable
{
    if (![[self class] isOperation:variable])
        [self.programStack addObject:variable];
}

#pragma mark Display brain methods

+ (NSString *)removeParens:(NSString *)expressionToSimplify
{
    // for all we know, no simplification is needed
    NSString *returnString = [expressionToSimplify copy];
    // if our expression is inside paretheses, remove them
    if ([expressionToSimplify hasPrefix:@"("] && [expressionToSimplify hasSuffix:@")"]) {
        returnString = [expressionToSimplify substringWithRange:NSMakeRange(1,(expressionToSimplify.length -2))];
    }
    // If after removing parentheses from begining and end, if there are mismatched parentheses inside, return original expression
    NSRange openParens = [returnString rangeOfString:@"("];
    NSRange closeParens = [returnString rangeOfString:@")"];
    
    if ((openParens.location != NSNotFound) && (closeParens.location != NSNotFound)) {
        if (openParens.location <= closeParens.location)
            return returnString; // If the open one is before the closed one
        else
            return expressionToSimplify;

    } else {
        return returnString;
    }
}


+ (NSUInteger)operationPrecedence:(NSString *)operation
{
    NSArray *operations = [NSArray arrayWithObjects:@"÷",@"−" ,@"×",@"+",  nil];
    return [operations indexOfObject:operation]+1;
}

// Find the precedence of the 1st operation in the given string
+ (NSUInteger)nextOpPrecedence:(NSString *)nextOp
{
    NSCharacterSet *doubleOpOps = [NSCharacterSet characterSetWithCharactersInString:@"÷−×+"];
    // find 1t of any of these 4 operations, and get its location
    NSRange firstFoundOp = [nextOp rangeOfCharacterFromSet:doubleOpOps];
    if (firstFoundOp.location != NSNotFound) {
        return [[self class] operationPrecedence:[nextOp substringWithRange:NSMakeRange (firstFoundOp.location,1)]];
    } else {
        return 0;
    }
}


// Homework 2, part 2 - use this to do infix and put correct parens, above to clean up parens
// Similar to popOperandOffStack Note this is recursive, so we consume the stack
+ (NSString *)descriptionOfTopOfStack:(NSMutableArray *)stack {
    // Blank string to be created and appended to
    NSMutableString *programFragment = [NSMutableString stringWithString:@""];
    
    // Get the top operand. it could be another program, an operation, or a value
    id topOfStack = [stack lastObject];
    if (topOfStack) [stack removeLastObject];
    
    // Value? append it to the programFragment string
    if ([topOfStack isKindOfClass:[NSNumber class]]) {
        [programFragment appendFormat:@"%g", [topOfStack doubleValue]];
    // If it is a string, it must be a variable or an operation
    } else if ([topOfStack isKindOfClass:[NSString class]]) {
        NSString *operation = topOfStack;
        // Double operand operations must be in the correct order, and depending on type do and do not have parens
        if ([self isDoubleOpOperation:operation]) {
            NSString *secondOperand = [self descriptionOfTopOfStack:stack];
            NSString *firstOperand = [self descriptionOfTopOfStack:stack];

          
            // This one was SUPER tough!!
            if ([self operationPrecedence:operation] < [self nextOpPrecedence:secondOperand]) {
                [programFragment appendFormat:@"%@ %@ %@", firstOperand, operation,  secondOperand];
            } else if ([self operationPrecedence:operation] == [self nextOpPrecedence:secondOperand]) {
                [programFragment appendFormat:@"%@ %@ %@", firstOperand, operation,  [self removeParens:secondOperand]];
            } else {
                [programFragment appendFormat:@"(%@ %@ %@)", [self removeParens:firstOperand], operation, [self removeParens:secondOperand]];
            }
            
            

        } else if ([self isSingleOpOperation:operation]) {
            // Single operation operands always have parens around them
            [programFragment appendFormat:@"%@(%@)", operation, [self removeParens:[self descriptionOfTopOfStack:stack]]];
        } else if ([self isNoOpOperation:operation]) {
            // no ops, constants, like π, e, etc.
            [programFragment appendFormat:@"%@", operation];
        } else if ([self isErrorCondition:operation]) {
            // errors
            [programFragment appendFormat:@"%@", [self removeParens:[self descriptionOfTopOfStack:stack]]];
        } else {
            // If all else fails, it is a variable, just returun it
            [programFragment appendFormat:@"%@", operation];
        }
    }
    
    return programFragment;
}

// Homework 2, part 1
// The hint was this is like runProgram, so we do pretty much the same
// The difference is that we do not convert the vars to numbers
+ (NSString *)descriptionOfProgram:(id)program
{
    NSMutableArray *stack;
    NSMutableArray *equations = [[NSMutableArray alloc] init];
    
    // If it is an array, then it is it's own little program, and will be separated by a comma. Call it recursively
    if ([program isKindOfClass:[NSArray class]]) {
        stack = [program mutableCopy];
    }
    // While there is a program left, create an array, so as I can join with comma!
    while ([stack count] > 0) {
        [equations addObject:[self removeParens:[self descriptionOfTopOfStack:stack]]];
    }

    // New way to do it! Use the AWESOME componentsJoinedByString
    return [equations componentsJoinedByString:@","];      

}

#pragma mark computational engine

// used for homework 2, part 1
// This will recursively pop numbers or operations off the stack
+ (id)popOperandOffStack:(NSMutableArray *)stack
{
    id result;
    
    id topOfStack = [stack lastObject];         // We want to use introspection on the top of the stack
    if (topOfStack) [stack removeLastObject];   // and if there is a topOfStack, we remove it (remember, we wanted to consume the array
    // Note that we can still run the code below, because it will only be called if there was an element (we can send methods to nil in Obj-C)
    
    // If the last item we are looking at is a number, return it as a double
    if ([topOfStack isKindOfClass:[NSNumber class]]) {
        result = topOfStack;
    // and if the last item is a string, it could be an operation, variable, or error condition
    } else if ([topOfStack isKindOfClass:[NSString class]]) {
        NSString *operation = topOfStack;
        
        if ([self isDoubleOpOperation:operation]) {
            // Get the two operations off the top of the stack
            id secondOperand = [self popOperandOffStack:stack];
            id firstOperand = [self popOperandOffStack:stack];
            
            if (([secondOperand isKindOfClass:[NSNumber class]]) && ([firstOperand isKindOfClass:[NSNumber class]])) {
                double firstOperandVal = [firstOperand doubleValue];
                double secondOperandVal = [secondOperand doubleValue];
                if ([operation isEqualToString:@"+"]) {
                    result = [NSNumber numberWithFloat:firstOperandVal + secondOperandVal];
                } else if ([@"×" isEqualToString:operation]) {
                    result = [NSNumber numberWithFloat:firstOperandVal * secondOperandVal];
                } else if ([@"÷" isEqualToString:operation]) {
                    if (secondOperandVal != 0)
                        result = [NSNumber numberWithFloat:firstOperandVal / secondOperandVal];
                    else
                        result = @"Divide By Zero";
                } else if ([@"−" isEqualToString:operation]) {
                    result = [NSNumber numberWithFloat:firstOperandVal - secondOperandVal];
                }
/* should I return the old error, or the insufficient operand? */
            } else if ([secondOperand isKindOfClass:[NSString class]]) {
                if ([self isErrorCondition:secondOperand]) {
                    result = secondOperand;
                }
            } else if ([firstOperand isKindOfClass:[NSString class]]) {
                if ([self isErrorCondition:firstOperand]) {
                    result = firstOperand;
                }
/* I think either can be argued to be correct  */            

            } else {
                result = @"Insufficient Operands";
            }
        } else if ([self isSingleOpOperation:operation]) {
            id operand = [self popOperandOffStack:stack];

            if ([operand isKindOfClass:[NSNumber class]]) {
                double operandVal = [operand doubleValue];
            
                if ([@"sin" isEqualToString:operation]) {
                    result = [NSNumber numberWithFloat:sin(operandVal)];
                } else if ([@"cos" isEqualToString:operation]) {
                    result = [NSNumber numberWithFloat:cos(operandVal)];
                } else if ([@"log" isEqualToString:operation]) {
                    result = [NSNumber numberWithFloat:log2(operandVal)];
                } else if ([@"±" isEqualToString:operation]) {                  // Weird bug where you can get -0
                    if (operandVal != 0)
                        result = [NSNumber numberWithFloat:-(operandVal)];
                    else
                        result = 0;
                } else if ([@"√" isEqualToString:operation]) {
                    if (operandVal < 0)
                        result = @"sqrt of negative";
                    else
                        result = [NSNumber numberWithFloat:sqrt(operandVal)];
                }
            } else {
                result = @"Insufficient Operands";
            }
        } else if ([self isNoOpOperation:operation]) {
            if ([@"π" isEqualToString:operation]) {
                result = [NSNumber numberWithFloat:M_PI];
            } else if  ([@"e" isEqualToString:operation]) {
                result = [NSNumber numberWithFloat:M_E];
            }
        } else if (![self isErrorCondition:operation]) { // must be a variable, and it has not been replaced...
            result = [NSNumber numberWithInt:0];
        } else {
            // Must be an error
            result = topOfStack;
        }
    }
    return result;
}

+ (id)runProgram:(id)program
{
    NSDictionary *blankDictionary;
    
    return [self runProgram:program usingVariableValues:blankDictionary];
}

// Homework 2, part 1
// Changed to id return value for extra credit
+ (id)runProgram:(id)program usingVariableValues:(NSDictionary *)variableValues
{
    if ([program count]) {
        // We want to consume the program stack, so as we can do the recursion, so...
        NSMutableArray *stack;
        // If what was passed to us was aprogram, make a copy we can consume (mutableCopy achieves that)
        if ([program isKindOfClass:[NSArray class]]) {
            stack = [program mutableCopy];
        }
        if ([variableValues isKindOfClass:[NSDictionary class]]) {
            if (variableValues) {
                // what we do now is iterate through the stack, replacing all variables
                // with their looked up values from the dictionary
                for ( int i = 0;i < stack.count; i++) {
                    id obj = [stack objectAtIndex:i]; 
                    
                    if ([obj isKindOfClass:[NSString class]] && ![self isOperation:obj]) {
                        id value = [variableValues objectForKey:obj];         
                        // If value is not an instance of NSNumber, set it to zero
                        if (![value isKindOfClass:[NSNumber class]]) {
                            value = [NSNumber numberWithInt:0];
                        }
                        // Replace program variable with value.
                        [stack replaceObjectAtIndex:i withObject:value];
                    }     
                }
            }
        }
        // If we have anything sitting on the stack, return it, otherwise we have cleared the brain and we should return 0
        if (stack.count > 0) {
            return [self popOperandOffStack:stack];
        }
    }
    return nil;
}

// If I find a string that is not an operation, I add it to the set.
// I don't need to check for duplicates because sets will not add a duplicate automatically,
// solving a problem you would need to solve with an array (checking the array for duplicates)
+ (NSSet *)variablesUsedInProgram:(id)program
{
    NSSet *result = [[NSSet alloc] init ];
    if ([program isKindOfClass:[NSArray class]]) {
        for (id operationOrOperand in program) {
            if ([operationOrOperand isKindOfClass:[NSString class]]) {
                if (![self isOperation:(NSString *) operationOrOperand]) {
                    // No, it is not an operation, so it has to be a variable. Add it to the set
                    result = [result setByAddingObject:(NSString *) operationOrOperand]; 
                }
            }
        }
    }
    if ([result count])
        return result;
    else
        return nil;
    
    // Could have also done this with an NSMutableSet and returned [result copy], and instead of recreating the set each time
    // from an existing set, appending to the set. Still need to check for empty set and return nil. Found that I cannot
    // use an NSSet unless I alloc/init it, and if I do, it is not nil...
}

- (void)clearBrain
{
    // Clear everything on the stack
    [self.programStack removeAllObjects];
    self.programStack = nil; // Not really necessary, but cleaner
}
@end

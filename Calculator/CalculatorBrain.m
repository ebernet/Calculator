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


+ (id) OperationSet {
    static NSSet * _operationSet = nil;
    if (!_operationSet)
		_operationSet = [[NSSet alloc] initWithObjects:@"sin",@"cos",@"tan",@"√",@"×",@"÷",@"+",@"−",@"π",@"±",@"e",@"log",nil];
	return _operationSet;
}
+ (id) SingleOpSet {
    static NSSet * _singleOpSet = nil;
    if (!_singleOpSet)
        _singleOpSet = [[NSSet alloc] initWithObjects:@"sin",@"cos",@"tan",@"log",@"√",nil];
	return _singleOpSet;
}
+ (id) DoubleOpSet {
    static NSSet * _doubleOpSet = nil;
    if (!_doubleOpSet)
        _doubleOpSet = [[NSSet alloc] initWithObjects:@"×",@"÷",@"+",@"−",nil];
	return _doubleOpSet;
}
+ (id) NoOpSet {
    static NSSet * _noOpSet = nil;
    if (!_noOpSet)
        _noOpSet = [[NSSet alloc] initWithObjects:@"π",@"e",nil];
	return _noOpSet;
}
+ (id) ErrorSet {
    static NSSet * _errorSet = nil;
    if (!_errorSet)
        _errorSet = [[NSSet alloc] initWithObjects:@"Divide By Zero",@"sqrt of negative",@"log of negative",
                                        @"Insufficient Operands",@"infinity",@"negative infinity",nil];
	return _errorSet;
}

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
    return [[self OperationSet] containsObject:operation];
}

+ (BOOL)isSingleOpOperation:(NSString *)operation
{
    return [[self SingleOpSet] containsObject:operation];
}

+ (BOOL)isDoubleOpOperation:(NSString *)operation
{
    return [[self DoubleOpSet] containsObject:operation];
}

+ (BOOL)isNoOpOperation:(NSString *)operation
{
    return [[self NoOpSet] containsObject:operation];
}

+ (BOOL)isErrorCondition:(NSString *)topOfStack
{
    return [[self ErrorSet] containsObject:topOfStack];
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


// Replaced my long code below with this code, that I got some help on
// + and - have a lower priority than times and divide
+ (NSUInteger)priority:(NSString *)operation
{
    if ([operation isEqualToString:@"+"] || [operation isEqualToString:@"−"])
        return 0;
    else
        return 1;
}

// This will call a modigfied description, see below
+ (NSString *)descriptionOfTopOfStack:(NSMutableArray *)stack
{
    return [self descriptionOfTopOfStack:stack operation:nil operandOnRight:NO];
}

// Takes the stack (program), the operation itself (note, it will be nil UNLESS you are looking at a double op), and whether you are evaluating the RIGHT side of the equatiion...
+ (NSString *)descriptionOfTopOfStack:(NSMutableArray *)stack operation:(id)parent operandOnRight:(BOOL)onRight
{
    // Consume the stack. Look at what is on top
    id topOfStack = [stack lastObject];
    if (topOfStack) [stack removeLastObject];

        // Value? Just return it...
    if ([topOfStack isKindOfClass:[NSNumber class]]) {
        return  [NSString stringWithFormat:@"%g",[topOfStack doubleValue] ];
        // If it is a string, it must be a variable or an operation
    } else if ([topOfStack isKindOfClass:[NSString class]]) {
        if ([self isSingleOpOperation:(NSString *) topOfStack]) {
            // Single operation operands always have parens around them. Below is to prevent double Parens, because nil
            // always displays as (null) with description
            NSString *operand = [self descriptionOfTopOfStack:stack];
            if (operand)
                return [NSString stringWithFormat:@"%@(%@)", topOfStack, operand];
            else 
                return [NSString stringWithFormat:@"%@%@", topOfStack, operand];
        } else if ([self isNoOpOperation:(NSString *) topOfStack]) {
            // no ops, constants, like π, e, etc. Just return it
            return topOfStack;
            // Errors, just return the error through it...
        } else if ([self isErrorCondition:(NSString *) topOfStack]) {
            return topOfStack;
            // Meat and potatoes below!!!
        } else if ([self isDoubleOpOperation:(NSString *) topOfStack]) {
            
            // topOfStack is a doubleOp operation, recursively call to get both sides, use flag to indicate right side of equation
            NSString * secondOperand = [self descriptionOfTopOfStack:stack operation:topOfStack operandOnRight:YES];
            NSString * firstOperand = [self descriptionOfTopOfStack:stack operation:topOfStack operandOnRight:NO];
            // are we down in the recursion?
            if (parent) {
                // YES, we are. We need to enclose in parentheses if operation has lower priority than its parent's
                // (because it will be to the RIGHT of the parent operation.
                // OR, if it is on the right side already and the priorities are the same BUT our parent operation is / or -,
                // since 3 - (4 + 5) is not the same as 3 - 4 + 5, and 3 / (4 * 5) is not the same as 3 / 4 * 5, even though the
                // priorities of the two operations in each of those ARE the same
                if ([self priority:topOfStack] < [self priority:parent] || (onRight && ([self priority:topOfStack] == [self priority:parent]) && 
                                                                            ([parent isEqualToString:@"÷"] ||[parent isEqualToString:@"−"]))) {
                    return [NSString stringWithFormat:@"(%@ %@ %@)", firstOperand, topOfStack, secondOperand];
                } else {
                    // Above not met, do not need parentheses
                    return [NSString stringWithFormat:@"%@ %@ %@", firstOperand, topOfStack, secondOperand];
                }
                
            } else {
                // No parent operation, so parentheses not needed
                return [NSString stringWithFormat:@"%@ %@ %@", firstOperand, topOfStack, secondOperand];
            }
                
        } else {
            // Must be a variable
            return topOfStack;
        }
    }
    // No topOfStack, recursion done
    return nil;   
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
        [equations addObject:[self descriptionOfTopOfStack:stack]];
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
                } else if ([@"tan" isEqualToString:operation]) {
                    result = [NSNumber numberWithFloat:tan(operandVal)];
                } else if ([@"log" isEqualToString:operation]) {
                    if (operandVal < 0)
                        result = @"log of negative";
                    else
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
            if ([result isKindOfClass:[NSNumber class]]) {
                if ([result doubleValue] == INFINITY) {
                    result = @"infinity";
                } else  if ([result doubleValue] == -INFINITY) {
                    result = @"negative infinity";
                }
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
    if ([program isKindOfClass:[NSArray class]]) {
        // We want to consume the program stack, so as we can do the recursion, so...
        // Copy it...
        NSMutableArray *stack = [program mutableCopy];
        if ([program count])  {
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
}
@end

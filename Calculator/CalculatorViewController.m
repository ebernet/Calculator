//
//  CalculatorViewController.m
//  Calculator
//
//  Created by Eytan Bernet on 6/4/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "CalculatorViewController.h"
#import "CalculatorBrain.h"

@interface CalculatorViewController()

@property (nonatomic) BOOL userIsInTheMiddleOfEnteringANumber;
@property (nonatomic, strong) CalculatorBrain *brain;
@property (nonatomic) SystemSoundID buttonClick;                        // We want a new system sound for clicking
@property (nonatomic, strong) NSDictionary *testVariableValues;
@end

@implementation CalculatorViewController

@synthesize display = _display;
@synthesize brainInputDisplay = _brainInputDisplay;
@synthesize variableDisplay = _variableDisplay;
@synthesize userIsInTheMiddleOfEnteringANumber = _userIsInTheMiddleOfEnteringANumber;
@synthesize brain = _brain;
@synthesize testVariableValues = _testVariableValues;
@synthesize buttonClick;


- (CalculatorBrain*)brain
{
    if (!_brain) _brain = [[CalculatorBrain alloc] init];
    return  _brain;
}

- (IBAction)undoPressed {
    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self backspacePressed];
    } else {
        [self.brain undo];
        [self updateDisplay];
    }
}

- (IBAction)clearPressed
{
    [self playButtonClick];
    [self.brain clearBrain];                        // Clear the program stack
    self.userIsInTheMiddleOfEnteringANumber = NO;   // and reset all the related views
    self.brainInputDisplay.text = @"";
    self.display.text = @"0";
}

- (IBAction)decimalPressed
{
    // Not already typing, then place a "0.". I think a leading 0 looks better
    if (!self.userIsInTheMiddleOfEnteringANumber) {
        [self playButtonClick];
        self.display.text = @"0.";
        self.userIsInTheMiddleOfEnteringANumber = YES;
        return; // We are done, don't need to evaluate whether there are other decimals
    }
    // Make sure you only allow one decimal
    NSRange range = [self.display.text rangeOfString:@"."];
    if (range.location == NSNotFound) {
        [self playButtonClick];
        self.display.text = [self.display.text stringByAppendingString:@"."];
    }
}

- (IBAction)digitPressed:(UIButton *)sender
{
    [self playButtonClick];
    NSString *digit = sender.currentTitle;
    if (self.userIsInTheMiddleOfEnteringANumber) {
        // If we are already displaying just one 0, we replace it with whatever digit we typed
        if ([self.display.text isEqualToString:@"0"]) {
            self.display.text = digit; 
        } else { // Any other digit gets appended
            self.display.text = [self.display.text stringByAppendingString:digit]; // Append digit
        }
    } else {
        // If we have NOT started typing numbers
        self.display.text = digit;                      // First digit, just put it in the display
        self.userIsInTheMiddleOfEnteringANumber = YES;  // And set flag that we are entering numbers
        // Extra credit homework 1 - once a digit is pressed, we make sure to remove any = that may have been put there by an operation
    }

}

- (IBAction)enterPressed
{
    [self playButtonClick];
    // Whatever is in the display, whether it is a new digit being entered OR the result of the previous evaluation,
    // gets pushed on the stack.
    [self.brain pushOperand:[self.display.text doubleValue]];
    self.userIsInTheMiddleOfEnteringANumber = NO;
    // update the display by running the program, and update the brainInput as well
    [self updateDisplay];
}

- (IBAction)negateNumber
{
    // If we are entering a number.... so we want to remove trailing = but also change the sign
    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self playButtonClick];
        // Make sure we have not just entered a decimal (showing "0."). We don't need to negate that.
        // If we are showing real numbers, we do NOT push this on the stack of operations, sicne we have yet to push the number!
        if (![self.display.text isEqualToString:@"0."]) {
            self.display.text = [NSString stringWithFormat:@"%g",-[self.display.text doubleValue]];
        }
    } else {
        // Okay, if we are showing what is on the stack
        if ([self.display.text doubleValue] != 0) { // Again, only negate it if we actually have a non-zero number
            [self playButtonClick];
            // This is a tough one. Should we push the operation down if the stack was evaluating to 0??
            [[self.brain performOperation:@"±"] doubleValue];        }
        [self updateDisplay];
        
    }
}

- (IBAction)variablePressed:(UIButton *)sender
{
    // variables push any number sitting in the display on the stack
    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self enterPressed];
    } else {
        [self playButtonClick]; // Only play click for the variable if we did not do it via enterPressed
    }
    
    // Here is that push...
    [self.brain pushVariable:sender.currentTitle];
    
    // Evaluate the operation - display always reflects running the program
    [self updateDisplay];
}

- (IBAction)backspacePressed
{
    // Only work if they are entering numbers
    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self playButtonClick];
        if (self.display.text.length > 0) {
            // This will take care of multiple numbers, OR of "0."
            self.display.text = [self.display.text substringToIndex:(self.display.text.length - 1)];
        }
        if ((self.display.text.length == 0) || [self.display.text isEqualToString:@"0"]) { // The second check is if they deleted the decimal
            self.display.text = @"0";
            self.userIsInTheMiddleOfEnteringANumber = NO;
        }
    }
}

- (IBAction)operationPressed:(UIButton *)sender
{
    // Operations push any number sitting in the display on the stack
    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self enterPressed];
    } else {
        [self playButtonClick]; // Only play click for the opertion if we did not do it via enterPressed
    }
    // Evaluate the operation - display always reflects running the program
    [[self.brain performOperation:sender.currentTitle] doubleValue];
    
    [self updateDisplay];
}

- (IBAction)testPressed:(UIButton *)sender
{
    if ([sender.currentTitle isEqualToString:@"Test 1"]) {
        self.testVariableValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithFloat:5.0], @"x",
                                    [NSNumber numberWithFloat:4.8], @"a",
                                    [NSNumber numberWithFloat:0], @"foo",
                                    nil];
    } else if  ([sender.currentTitle isEqualToString:@"Test 2"]) {
        self.testVariableValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithFloat:-2.0], @"x",
                                   [NSNumber numberWithFloat:2.0], @"a",
                                   [NSNumber numberWithFloat:0.2], @"foo",
                                   nil];
    } else if  ([sender.currentTitle isEqualToString:@"Test 3"]) {
        self.testVariableValues = nil;
    }

    [self updateDisplay];
}

- (void)playButtonClick
{
    AudioServicesPlaySystemSound(buttonClick);
}

// Need to add a viewDidLoad to set up the sound.
// adding sound, this is the soundfile setup
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // get the file path to the buttonClick
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"click"
                                                          ofType:@"wav"];
    // Did we find the audio file?
    if (soundPath) {
        // convert the file path to a URL
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundPath];
        
        OSStatus err = AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundFileURL , &buttonClick);
        
        if (err != kAudioServicesNoError)
            NSLog(@"Could not load %@, error code: %ld", soundFileURL, err);
    }
    
}

- (void)updateDisplay
{
    // Evaluate the program, place the result in the display. Result may be an error condition
    id resultOfProgram = [CalculatorBrain runProgram:[self.brain program] usingVariableValues:self.testVariableValues];
    if ([resultOfProgram isKindOfClass:[NSNumber class]]) {
        self.display.text = [NSString stringWithFormat:@"%g",[resultOfProgram doubleValue]];
    } else {
        self.display.text = resultOfProgram;   // Can show error conditions
    }
    
    // Always show the program, not its evaluation, in the brainInputDisplay
    self.brainInputDisplay.text = [CalculatorBrain descriptionOfProgram:[self.brain program]];
    
    // SHow variables used in the current program
    self.variableDisplay.text = @"";
    // Only if the dictionary is not nil
    if (self.testVariableValues) {
        NSArray *variablesInUse = [[CalculatorBrain variablesUsedInProgram:self.brain.program] allObjects];
        for (int i = 0; i < variablesInUse.count; i++) {
            self.variableDisplay.text = [self.variableDisplay.text stringByAppendingFormat:@"%@ = %g, ",[variablesInUse objectAtIndex:i],[[self.testVariableValues valueForKey:[variablesInUse objectAtIndex:i]] doubleValue]];
        }
        // Remove the trailing ", "
        if (self.variableDisplay.text.length > 0) self.variableDisplay.text = [self.variableDisplay.text substringToIndex:self.variableDisplay.text.length-2];
    }
    
}


- (void)viewDidUnload {
    [self setBrainInputDisplay:nil];
    [self setDisplay:nil];
    [self setVariableDisplay:nil];
    [super viewDidUnload];
}
@end

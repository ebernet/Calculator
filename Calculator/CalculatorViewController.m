//
//  CalculatorViewController.m
//  Calculator
//
//  Created by Eytan Bernet on 6/4/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "CalculatorViewController.h"
#import "GraphViewController.h"
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

#define GRAPH_BUTTON_TAG 10

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
    //self.testVariableValues = nil;                // The assignment is ambiguous as to whether clear should clear the variables, or just the brain
                                                    // I am assuming no. Let test 3 do that...
    self.userIsInTheMiddleOfEnteringANumber = NO;   // and reset all the related views
    [self updateDisplay];
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
    }

}

- (IBAction)enterPressed
{
    [self playButtonClick];
    // Only gets called if the user was in the middle of entering a number, so it pushes value in the display
    // onto the stack
    [self.brain pushOperand:[self.display.text doubleValue]];
    self.userIsInTheMiddleOfEnteringANumber = NO;
    [self updateDisplay];
}

- (IBAction)negateNumber
{
    // If we are entering a number.... so we want to remove trailing = but also change the sign
    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self playButtonClick];
        // If we are showing real numbers, we do NOT push this on the stack of operations, since we have yet to push the number!
        // Do not allow negation of "0". You can now negate if you started typing a decimal.
        if ([self.display.text isEqualToString:@"0."]) {
            self.display.text = @"-0.";
        } else if (![self.display.text isEqualToString:@"0"]) {
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
    // Now push the variable
    [self.brain pushVariable:sender.currentTitle];
    [self updateDisplay];
}

// Called from undo, no longer called from a button. Conserved space on calculator for assignment 3. Removed IBAction
- (void)backspacePressed
{
    // Only work if they are entering numbers
    if (self.userIsInTheMiddleOfEnteringANumber) {
        [self playButtonClick];
        if (self.display.text.length > 0) {
            // This will take care of multiple numbers, OR of "0."
            self.display.text = [self.display.text substringToIndex:(self.display.text.length - 1)];
        }
        if ((self.display.text.length == 0) || [self.display.text isEqualToString:@"0"] || [self.display.text isEqualToString:@"-"] || [self.display.text isEqualToString:@"-0"]) { // The second check is if they deleted the decimal
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
    // Evaluate the operation - but no longer use it to update the display.
    [[self.brain performOperation:sender.currentTitle] doubleValue];
    [self updateDisplay];
}


- (void)playButtonClick
{
    AudioServicesPlaySystemSound(buttonClick);
}

// Need to add a viewDidLoad to set up the sound.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // get the file path to the buttonClick
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"click" ofType:@"wav"];
    // Did we find the audio file?
    if (soundPath) {
        // convert the file path to a URL
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundPath];
        OSStatus err = AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundFileURL , &buttonClick);
        if (err != kAudioServicesNoError)
            NSLog(@"Could not load %@, error code: %ld", soundFileURL, err);
    }
}

// Moved all the diplay stuff here
- (void)updateDisplay
{
    // Evaluate the program, place the result in the display. Result may be an error condition
    id resultOfProgram = [[self.brain class] runProgram:[self.brain program] usingVariableValues:self.testVariableValues];
    if ([resultOfProgram isKindOfClass:[NSNumber class]]) {
        self.display.text = [NSString stringWithFormat:@"%g",[resultOfProgram doubleValue]];
    } else if ([resultOfProgram isKindOfClass:[NSString class]]) {
        self.display.text = resultOfProgram;   // Can show error conditions
    } else { // if the you undo the brain, nil will be returned, so put up a 0
        self.display.text = @"0";
    }
    
    // Always show the program, not its evaluation, in the brainInputDisplay.
    self.brainInputDisplay.text = @"";
    if ([self.brain program])
        self.brainInputDisplay.text = [[self.brain class] descriptionOfProgram:[self.brain program]];
}

- (void)viewDidUnload {
    [self setBrainInputDisplay:nil];
    [self setDisplay:nil];
    [self setVariableDisplay:nil];
    [super viewDidUnload];
}

#pragma mark Assignment 3 code

// Allow everything but upsidedown for the calculator
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

// Pass the program onto the GraphView. While only topmost program will be graphed, lower down display will handle
// Not showing it....
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowGraph"]) {
        [segue.destinationViewController setProgram:[self.brain program]];
    }
}

- (void)viewWillLayoutSubviews
{
    
    if (!(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        // Adjust position for graph button
        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
        {
            // code for landscape orientation   
            [self.view viewWithTag:GRAPH_BUTTON_TAG].frame = CGRectMake(384, 214, 44, 44);
     
        } else {
            // code for portrait orientation   
            [self.view viewWithTag:GRAPH_BUTTON_TAG].frame = CGRectMake(250, 335, 44, 44);
           
        }
    }
}


@end

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
@end

@implementation CalculatorViewController

@synthesize display = _display;
@synthesize brainInputDisplay = _brainInputDisplay;
@synthesize userIsInTheMiddleOfEnteringANumber = _userIsInTheMiddleOfEnteringANumber;
@synthesize brain = _brain;
@synthesize buttonClick;


- (CalculatorBrain*)brain
{
    if (!_brain) _brain = [[CalculatorBrain alloc] init];
    return  _brain;
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
    self.brainInputDisplay.text = [self.brainInputDisplay.text stringByReplacingOccurrencesOfString:@"= " withString:@""];
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
        // Extra credit - once a digit is pressed, we make sure to remove any = that may have been put there by an operation
        self.brainInputDisplay.text = [self.brainInputDisplay.text stringByReplacingOccurrencesOfString:@"= " withString:@""];
    }

}

- (IBAction)enterPressed
{
    [self playButtonClick];
    // Whatever is in the display, whether it is a new digit being entered OR the result of the previous evaluation,
    // gets pushed on the stack. So update the brain display. Check for just one thing, "0.", and replace with 0!
    if ([self.display.text isEqualToString:@"0."]) self.display.text = @"0";
    self.brainInputDisplay.text = [self.brainInputDisplay.text stringByAppendingFormat:@"%@ ", self.display.text];

    // Here is that push...
    [self.brain pushOperand:[self.display.text doubleValue]];
    // We are certainly not enetering a number, regardless of whether we had been...
    self.userIsInTheMiddleOfEnteringANumber = NO;

    // If we had put an "=" sign in the brain, we are removing it, since this was not an operation we pushed
    self.brainInputDisplay.text = [self.brainInputDisplay.text stringByReplacingOccurrencesOfString:@"= " withString:@""];

}

- (IBAction)negateNumber
{
    // Remove any prior =
    self.brainInputDisplay.text = [self.brainInputDisplay.text stringByReplacingOccurrencesOfString:@"= " withString:@""];

    // If we are entering a number....
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
            double result = [self.brain performOperation:@"+/-"]; // We want to replace the result on the stack
            NSString *resultString = [NSString stringWithFormat:@"%g", result];
            self.display.text = resultString;
            // Note, I am adding these negations to the brainInputDisplay, but they are NOT going on the stack. Is this accurate?
            self.brainInputDisplay.text = [self.brainInputDisplay.text stringByAppendingString:@" +/- "];
        }
        
    }
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
    // Evaluate the operation
    double result = [self.brain performOperation:sender.currentTitle];
    // And place the result on the stack
    self.display.text = [NSString stringWithFormat:@"%g", result];
    self.brainInputDisplay.text = [self.brainInputDisplay.text stringByAppendingFormat:@"%@ ",sender.currentTitle];
 
    // A question could be made, is π an operation? If it is not, should we evaluate it and put the = sign?
    // The code before is in case I want to ensure only "real" operations are checked for...

    //    NSArray *arrayOfStrings = [NSArray arrayWithObjects:@"sin",@"cos",@"sqrt",nil];
    //    NSSet *setOfStrings = [NSSet setWithArray:arrayOfStrings];
    //    if ([setOfStrings containsObject:(NSString *)sender.currentTitle]) {
    //    } else {
    //        self.brainInputDisplay.text = [self.brainInputDisplay.text stringByAppendingString:@" "];
    //    }
    

    // Remove any prior =
    self.brainInputDisplay.text = [self.brainInputDisplay.text stringByReplacingOccurrencesOfString:@"= " withString:@""];
    // And append one at the end
    self.brainInputDisplay.text = [self.brainInputDisplay.text stringByAppendingString:@"= "];
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

- (void)viewDidUnload {
    [self setBrainInputDisplay:nil];
    [self setDisplay:nil];
    [super viewDidUnload];
}
@end

//
//  GraphViewController.m
//  Calculator
//
//  Created by Eytan Bernet on 7/12/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import "GraphViewController.h"
#import "GraphView.h"
#import "CalculatorBrain.h"

@interface GraphViewController () <GraphViewDataSource>
@property (weak, nonatomic) IBOutlet GraphView *graphView;
@end

@implementation GraphViewController
@synthesize graphView = _graphView;
@synthesize program = _program;
@synthesize graphEquation = _graphEquation;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setGraphView:(GraphView *)graphView
{
    _graphView = graphView;
    // enable pinch gestures in the FaceView using its pinch: handler
//    [self.faceView addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self.faceView action:@selector(pinch:)]];
//    // recognize a pan gesture and modify our Model
//    [self.faceView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHappinessGesture:)]];
    self.graphView.dataSource = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated
{
    id descriptionOfProgram = [CalculatorBrain descriptionOfProgram:[self program]];
    if ([descriptionOfProgram isKindOfClass:[NSString class]] && ![descriptionOfProgram isEqualToString:@""]) {
        // Only show what is being graphed. Other programs in stack not yet being used are NOT being graphed.
        NSRange commaLocation = [descriptionOfProgram rangeOfString:@","];
        if (commaLocation.location != NSNotFound)
            descriptionOfProgram = [(NSString *)descriptionOfProgram substringToIndex:commaLocation.location];
        self.graphEquation.text = [NSString stringWithFormat:@"y = %@",descriptionOfProgram];
    }
//    [self.graphView loadDefaults];
}

- (void)setProgram:(id)program
{
    if (_program != program) {
        _program = program;
        
        [self.graphView setNeedsDisplay];
    }
}


- (CGFloat)yForGraphView:(GraphView *)sender fromXValue:(CGFloat)x
{
    CGFloat returnVal = 0;
    id returnedValue = [CalculatorBrain runProgram:[self program]
                               usingVariableValues:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    [NSNumber numberWithDouble:x], @"x", nil]];
    
    if ([returnedValue isKindOfClass:[NSNumber class]]) {
        returnVal = [returnedValue doubleValue];
    }
    return returnVal;
}


- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self setGraphView:nil];
    [self setGraphEquation:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


@end

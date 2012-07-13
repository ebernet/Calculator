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
    [self.graphView addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self.graphView action:@selector(pinch:)]];
    [self.graphView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self.graphView action:@selector(pan:)]];
    UITapGestureRecognizer *tripleFingerDTap = [[UITapGestureRecognizer alloc] initWithTarget:self.graphView action:@selector(tap:)];
    tripleFingerDTap.numberOfTapsRequired = 3;
    
    [self.graphView addGestureRecognizer:tripleFingerDTap];
    self.graphView.dataSource = self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Load up any defaults, if there were any...
    [self.graphView loadDefaults];
}


- (void)setProgram:(id)program
{
    if (_program != program) {
        _program = program;
        
        [self.graphView setNeedsDisplay];
        id descriptionOfProgram = [CalculatorBrain descriptionOfProgram:[self program]];
        if ([descriptionOfProgram isKindOfClass:[NSString class]] && ![descriptionOfProgram isEqualToString:@""]) {
            NSRange commaLocation = [descriptionOfProgram rangeOfString:@","];
            if (commaLocation.location != NSNotFound)
                descriptionOfProgram = [(NSString *)descriptionOfProgram substringToIndex:commaLocation.location];
            self.title = [NSString stringWithFormat:@"y = %@",descriptionOfProgram];
        }
    }
}


- (CGFloat)yForGraphView:(GraphView *)sender fromXValue:(CGFloat)x
{
    // If there is no program, no need to do calculations. Retunr Not A Number.
    
    if ([[self program] count] == 0) return NAN;
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
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


@end

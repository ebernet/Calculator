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
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UILabel *toolbarTitle;
@property (weak, nonatomic) NSString *variableName;

@end

@implementation GraphViewController
@synthesize graphView = _graphView;
@synthesize toolbar = _toolbar;
@synthesize program = _program;
@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize toolbarTitle = _toolbarTitle;
@synthesize variableName = _variableName;

#define GRAPH_TITLE 9

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// This will be needed for iPad bar
- (void)setSplitViewBarButtonItem:(UIBarButtonItem *)splitViewBarButtonItem
{
    if (_splitViewBarButtonItem != splitViewBarButtonItem) {
        NSMutableArray *toolBarItems = [self.toolbar.items mutableCopy];
        if (_splitViewBarButtonItem) [toolBarItems removeObject:_splitViewBarButtonItem];
        if (splitViewBarButtonItem) [toolBarItems insertObject:splitViewBarButtonItem atIndex:0];
        self.toolbar.items = toolBarItems;
        _splitViewBarButtonItem = splitViewBarButtonItem;
    }
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

- (IBAction)togglePixels:(id)sender {
    if ([sender isKindOfClass:[UISwitch class]])
        [self.graphView setDrawSegmented:![sender isOn]];
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
        
        id descriptionOfProgram = [CalculatorBrain descriptionOfProgram:[self program]];
        // Okay, the program description is valid...
        if ([descriptionOfProgram isKindOfClass:[NSString class]]) {
            // No program, just say "Graph"
            if ([descriptionOfProgram isEqualToString:@""]) {
                if (self.splitViewController) {
                    self.toolbarTitle.text = @"Graph";
                } else {
                    self.title = @"Graph";
                }
            } else {
                // remove the comma if more than one program on stack
                NSRange commaLocation = [descriptionOfProgram rangeOfString:@","];
                if (commaLocation.location != NSNotFound)
                    descriptionOfProgram = [(NSString *)descriptionOfProgram substringToIndex:commaLocation.location];

                if (self.splitViewController) {
                    self.toolbarTitle.text = [NSString stringWithFormat:@"Y = %@",descriptionOfProgram];	
                } else {
                    self.title = [NSString stringWithFormat:@"Y = %@",descriptionOfProgram];
                }
            }
        } else {  // We had no program, or it was not a string
            if (self.splitViewController) {
                self.toolbarTitle.text = @"Graph";
            } else {
                self.title = @"Graph";
            }
        }

        
        // This allows me to alter the symbol for X without incurring problems
        if ([[[CalculatorBrain variablesUsedInProgram:[self program]] allObjects] count] > 0) {
            self.variableName = [[[CalculatorBrain variablesUsedInProgram:[self program]] allObjects] objectAtIndex:0];
        }

        
        
        [self.graphView setNeedsDisplay];
    }
}


- (id)yForGraphView:(GraphView *)sender fromXValue:(CGFloat)x
{
    // If there is no program, no need to do calculations. Retunr Not A Number.
    
    if ([[self program] count] == 0) return @"NOPROGRAM";
    id returnVal = @"NAN";

    
    id returnedValue = [CalculatorBrain runProgram:[self program]
                               usingVariableValues:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    [NSNumber numberWithDouble:x], self.variableName, nil]];
    
    if ([returnedValue isKindOfClass:[NSNumber class]]) {
        returnVal = returnedValue;
    }
    return returnVal;
}


- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self setGraphView:nil];
    [self setToolbar:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


@end

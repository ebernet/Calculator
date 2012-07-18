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
// added for favorites
#import "CalculatorProgramsTableViewController.h"

@interface GraphViewController () <GraphViewDataSource, CalculatorProgramsTableViewControllerDelegate>

@property (weak, nonatomic) IBOutlet GraphView *graphView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UILabel *toolbarTitle;
@property (weak, nonatomic) NSString *variableName;
@property (weak, nonatomic) NSString *simplifiedProgram;
@property (strong, nonatomic) NSMutableDictionary *variableDictionary;
@property (nonatomic, strong) UIPopoverController *popoverController; // This is for favorites prevent multiple popovers
@end

@implementation GraphViewController
@synthesize graphView = _graphView;
@synthesize toolbar = _toolbar;
@synthesize program = _program;
@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize toolbarTitle = _toolbarTitle;
@synthesize variableName = _variableName;
@synthesize simplifiedProgram = _simplifiedProgram;
@synthesize variableDictionary = _variableDictionary;
@synthesize popoverController;

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

- (NSMutableDictionary *)variableDictionary
{
    if (!_variableDictionary)
        _variableDictionary = [[NSMutableDictionary alloc] init];
    return _variableDictionary;
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
        
        // remove the comma if more than one program on stack
        NSArray *listPrograms = [[CalculatorBrain descriptionOfProgram:self.program] componentsSeparatedByString:@","];
        id descriptionOfProgram = [listPrograms objectAtIndex:0];
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
                if (self.splitViewController) {
                    self.toolbarTitle.text = [NSString stringWithFormat:@"Y = %@",descriptionOfProgram];	
                } else {
                    self.title = [NSString stringWithFormat:@"Y = %@",descriptionOfProgram];
                }
                // Program without the Y
                self.simplifiedProgram = descriptionOfProgram;
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
            [[self variableDictionary] setValue:0 forKey:self.variableName];
        } else {
            self.variableName = @"";
        }

        
        [self.graphView setNeedsDisplay];
    }
}


- (id)yForGraphView:(GraphView *)sender fromXValue:(CGFloat)x
{
    // If there is no program, no need to do calculations. Return Not A Number.
    if ([[self program] isKindOfClass:[NSArray class]]) {
        if ([[self program] count] == 0) return @"NOPROGRAM";
    } else if ([[self program] isKindOfClass:[NSString class]]) {
        if ([[self program] isEqualToString:@""]) return @"NOPROGRAM";
    }
    
    // If the program didn't contain a variable name. Instead of putting the X here I get the variables that may be in it out of
    // The CalculatorBrain by querying the program for variables in use. This allows for multiple graphs you could draw on
    // top of each other for different variables.
    if (!(self.variableName) || [self.variableName isEqualToString:@""]) return @"NOPROGRAM";
    
    id returnVal = @"NAN";

    [[self variableDictionary] setValue:[NSNumber numberWithDouble:x] forKey:self.variableName];

    id returnedValue = [CalculatorBrain runProgram:[self program]
                               usingVariableValues:self.variableDictionary];
    
    // This shaves a ittle time off, by making the disctionary a mutable dictionary and changing the key value each
    // time rather than recreating an new NSDictionary each time. At the time of reduction it was 6% of cycles,
    // After it was at 3%
    
//    id returnedValue = [CalculatorBrain runProgram:[self program]
//                               usingVariableValues:[NSDictionary dictionaryWithObjectsAndKeys:
//                                                    [NSNumber numberWithDouble:x], self.variableName, nil]];
    
    if ([returnedValue isKindOfClass:[NSNumber class]]) {
        returnVal = returnedValue;
    }
    return returnVal;
}

- (IBAction)resetScale
{
    [self.graphView resetScale];
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
    if (self.splitViewController) return YES;
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark - Additions for favorites

// Part of the favorites TableViewController
#define FAVORITES_KEY @"GraphViewController.Favorites"

- (IBAction)addToFavorites {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *favorites = [[defaults objectForKey:FAVORITES_KEY] mutableCopy];
    if (!favorites) favorites = [NSMutableArray array];
    if (![favorites containsObject:self.program]) {
        [favorites addObject:self.program];
        [defaults setObject:favorites forKey:FAVORITES_KEY];
        [defaults synchronize];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Favorites Graph"]) {
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
            UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
            [self.popoverController dismissPopoverAnimated:YES];
            self.popoverController = popoverSegue.popoverController; // might want to be popover's delegate and self.popoverController = nil on dismiss?
        }
        NSArray *programs = [[NSUserDefaults standardUserDefaults] objectForKey:FAVORITES_KEY];
        [segue.destinationViewController setPrograms:programs];
        [segue.destinationViewController setDelegate:self];
    }
}

- (void)calculatorProgramsTableViewController:(CalculatorProgramsTableViewController *)sender choseProgram:(id)program
{
    self.program = program;
    [self.navigationController popViewControllerAnimated:YES]; // added after lecture to support iPhone
}

// added after lecture to support deletion from the table
// deletes the given program from NSUserDefaults (including duplicates)
// then resets the Model of the sender

- (void)calculatorProgramsTableViewController:(CalculatorProgramsTableViewController *)sender
                               deletedProgram:(id)program
{
    NSString *deletedProgramDescription = [CalculatorBrain descriptionOfProgram:program];
    NSMutableArray *favorites = [NSMutableArray array];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (id program in [defaults objectForKey:FAVORITES_KEY]) {
        if (![[CalculatorBrain descriptionOfProgram:program] isEqualToString:deletedProgramDescription]) {
            [favorites addObject:program];
        }
    }
    [defaults setObject:favorites forKey:FAVORITES_KEY];
    [defaults synchronize];
    sender.programs = favorites;
    // This will bring you back to the graph after you delete the last program
    if ([favorites count] == 0) {
        [self.navigationController popViewControllerAnimated:YES];
        [popoverController dismissPopoverAnimated:YES];
    }
}

@end

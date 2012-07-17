//
//  CalculatorProgramsTableViewController.m
//  Calculator
//
//  Created by Eytan Bernet on 7/16/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import "CalculatorProgramsTableViewController.h"
#import "CalculatorBrain.h"

@interface CalculatorProgramsTableViewController ()

@end

@implementation CalculatorProgramsTableViewController

@synthesize programs = _programs;
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

// Added to support updating of programs menu in place
- (void)setPrograms:(NSArray *)programs
{
    if (_programs != programs) {
        _programs = programs;
        [self.tableView reloadData];
    }
}

// Allow everything but upsidedown for the TableViewController
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.programs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Calculator Program Description";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    
    id program = [self.programs objectAtIndex:indexPath.row];
    NSString * descriptionOfProgram = [CalculatorBrain descriptionOfProgram:program];
    // Only show the valid program - we can take care of this when we place it there
    NSRange commaLocation = [descriptionOfProgram rangeOfString:@","];
    if (commaLocation.location != NSNotFound) {
            descriptionOfProgram = [(NSString *)descriptionOfProgram substringToIndex:commaLocation.location];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Y = %@",descriptionOfProgram];
    
    return cell;
}

// this method added after lecture to support deletion
// simply delegates deletion

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        id program = [self.programs objectAtIndex:indexPath.row];
        [self.delegate calculatorProgramsTableViewController:self deletedProgram:program];
    }
}

// added after lecture
// don't allow deletion if the delegate does not support it too!

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.delegate respondsToSelector:@selector(calculatorProgramsTableViewController:deletedProgram:)];
}



#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id program = [self.programs objectAtIndex:indexPath.row];
    [self.delegate calculatorProgramsTableViewController:self choseProgram:program];
}


@end

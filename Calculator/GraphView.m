//
//  GraphView.m
//  Calculator
//
//  Created by Eytan Bernet on 7/12/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import "GraphView.h"
#import "AxesDrawer.h"

@implementation GraphView


@synthesize scale = _scale;
@synthesize graphOrigin = _graphOrigin;
@synthesize dataSource = _dataSource;
@synthesize drawSegmented = _drawSegmented;

#define DEFAULT_SCALE 1.00

NSString * const GraphingCalculatorScalePrefKey = @"GraphingCalculatorScalePrefKey";
NSString * const GraphingCalculatorOriginPrefKey = @"GraphingCalculatorOriginPrefKey";


- (double)calculateDefaultScale
{
    
    // Updated to skip over values if they are invalid
    
    // Figure out what the scale should be based on the program and the known size of the GraphView.
    // Note we want to look at the height since that is where the y result will be graphed
    
    // Figure out value with x at 0, then given the width/height figure out what y values will be that will fit on screen
    
    // Okay, first figure for 0 at origin, we have no scaling info, so we need to do the best
    // to send stuff down. First we see how tall it can be:
    
    CGFloat yAxisHeightLimit = self.bounds.size.height / 2; // this can be used for positive or negative height
    CGFloat xAxisWidthLimit = self.bounds.size.width / 2;   // Assuming our x value fed is going to go neg and pos as well
    
    // We can use the delegated datasource to see our values, so we will be calling yForGraphView
    
    CGFloat yScale = .5;    // Starting scale. Initially, the scale will be 1 (after we multiply it by 2
    CGFloat x;              // Used to iterate over x values
    CGFloat yForPositiveX;  // results for poitive x values...
    CGFloat yForNegativeX;  // and for negative x values
    
    id returnedValue;       // Used to handle errors for the deleghate method
    
    CGFloat maxY = 0;       // what the current calculated maxY will be, allows us to continuously refine
    CGFloat maxX = 0;       // Same for x - we need scales to be the same on x AND y axis
    BOOL scaleUp = YES;     // Should our scale grow larger than 1, or should we be dividing the scale?
    int heightToFigure = yAxisHeightLimit;  // What the new calcuated height should be, this is independent of the actual pixel height
    int widthToFigure = xAxisWidthLimit;    // ...same for width
    
    
    while (maxY < (heightToFigure - 5)) { // Some arbirary border from edge, will look nicer
        while (ABS(x) < widthToFigure) {
            scaleUp?(yScale *= 2):(yScale /= 2);
            x = 1;
            heightToFigure = (yAxisHeightLimit * yScale);
            widthToFigure = (xAxisWidthLimit * yScale);
            
            returnedValue = [self.dataSource yForGraphView:self fromXValue:x];
            if ([returnedValue isKindOfClass:[NSNumber class]]) {
                yForPositiveX = [returnedValue doubleValue];
            } else {
                continue;
            }
            if (abs(yForPositiveX) > maxY) maxY = abs(yForPositiveX);
            
            returnedValue = [self.dataSource yForGraphView:self fromXValue:-x];
            if ([returnedValue isKindOfClass:[NSNumber class]]) {
                yForNegativeX = [returnedValue doubleValue];
            } else {
                continue;
            }
            if (abs(yForNegativeX) > maxY) maxY = abs(yForPositiveX);
            
            if (abs(yForNegativeX) > maxY) maxY = abs(yForNegativeX);
            while ((abs(yForPositiveX) < heightToFigure) && 
                   (abs(yForNegativeX) < heightToFigure) &&
                   (x < widthToFigure)) {
                x++;

                returnedValue = [self.dataSource yForGraphView:self fromXValue:x];
                if ([returnedValue isKindOfClass:[NSNumber class]]) {
                    yForPositiveX = [returnedValue doubleValue];
                } else {
                    continue;
                }

                if (abs(yForPositiveX) > maxY) maxY = abs(yForPositiveX);

                returnedValue = [self.dataSource yForGraphView:self fromXValue:-x];
                if ([returnedValue isKindOfClass:[NSNumber class]]) {
                    yForNegativeX = [returnedValue doubleValue];
                } else {
                    continue;
                }
                if (abs(yForNegativeX) > maxY) maxY = abs(yForNegativeX);
            }
        }
        if (maxY < (widthToFigure/2)) {
            // calculate the scale factor and get maximum x
            scaleUp = NO;
            maxX = x;
            x = 0;
        }
    }
    CGFloat scaleToPassDown = (xAxisWidthLimit < yAxisHeightLimit)?(xAxisWidthLimit / maxX):(yAxisHeightLimit / maxX);
    NSLog(@"Default Scale: %f", scaleToPassDown);
    return scaleToPassDown;
    
}

- (void)setDrawSegmented:(BOOL)drawSegmented
{
    if (_drawSegmented != drawSegmented)
    {
        _drawSegmented = drawSegmented;
        [self setNeedsDisplay];
    }
}

- (CGFloat)scale
{
    if (!_scale) {
        return DEFAULT_SCALE;
    } else {
        return _scale;
    }
}

- (void)setScale:(CGFloat)scale{
    if (scale != _scale) {
        _scale = scale;
        [self setNeedsDisplay];
    }
}

- (CGPoint)graphOrigin
{
    if (CGPointEqualToPoint(_graphOrigin, CGPointZero)) {
        return CGPointMake(self.bounds.origin.x + self.bounds.size.width/2, self.bounds.origin.y + self.bounds.size.height/2);
    } else {
        return _graphOrigin;
    }
}

- (void)setGraphOrigin:(CGPoint)graphOrigin {
    if (!CGPointEqualToPoint(graphOrigin,_graphOrigin)) {
        _graphOrigin = graphOrigin;
        [self setNeedsDisplay];
    }
}

- (void)pinch:(UIPinchGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) || (gesture.state == UIGestureRecognizerStateEnded)) {
        self.scale *= gesture.scale;
        gesture.scale = 1;
        // Set this here because a default is not created until AFTER we manipulate it ourselves
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:self.scale] forKey:GraphingCalculatorScalePrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


- (void)pan:(UIPanGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) || (gesture.state == UIGestureRecognizerStateEnded)) {
        CGPoint translation = [gesture translationInView:self];
        CGFloat currentX = self.graphOrigin.x;
        CGFloat currentY = self.graphOrigin.y;
        self.graphOrigin = CGPointMake(currentX + (translation.x / 1), currentY + (translation.y / 1));
        [gesture setTranslation:CGPointZero inView:self];
        // Set this here because a default is not created until AFTER we manipulate it ourselves
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGPoint(self.graphOrigin) forKey:GraphingCalculatorOriginPrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)tap:(UITapGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) || (gesture.state == UIGestureRecognizerStateEnded)) {
        CGPoint currentLocation = [gesture locationInView:self];
        self.graphOrigin = currentLocation;
        // Set this here because a default is not created until AFTER we manipulate it ourselves
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGPoint(self.graphOrigin) forKey:GraphingCalculatorOriginPrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)loadDefaults
{
    
    NSString *defaultOriginString = [[NSUserDefaults standardUserDefaults] objectForKey:GraphingCalculatorOriginPrefKey];
    if (defaultOriginString)
        [self setGraphOrigin:CGPointFromString(defaultOriginString)];
    
    NSNumber *defaultScaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:GraphingCalculatorScalePrefKey];
    if (defaultScaleValue) {
        [self setScale:[defaultScaleValue floatValue]];
    } else {
        [self setScale:[self calculateDefaultScale]];
    }
}

//- (void)awakeFromNib
//{
//    [super awakeFromNib];
//    [self setContentMode:UIViewContentModeRedraw];
//}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setContentMode:UIViewContentModeRedraw];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    
    [AxesDrawer drawAxesInRect:self.bounds originAtPoint:self.graphOrigin scale:[self scale]];
    
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat screenScaling = [self contentScaleFactor];      // what are the actual pixel sizes?
    
    CGFloat yOffset = self.graphOrigin.y;
    CGFloat xOffset = self.graphOrigin.x;
    
    CGFloat startingXCoordinate = self.graphOrigin.x - self.bounds.size.width;
    CGFloat endingXCoordinate = startingXCoordinate + self.bounds.size.width; // On screen coordinates
    
    CGFloat startingXValue = startingXCoordinate / self.scale;
    
    CGFloat xIncrement = 1/screenScaling;
    CGFloat xIncrementValue = 1/self.scale/screenScaling;
    
    CGFloat xValue = startingXValue;
    CGFloat yValue;
    
    id returnedValue = [self.dataSource yForGraphView:self fromXValue:xValue];
    if ([returnedValue isKindOfClass:[NSNumber class]]) {
         yValue = [returnedValue doubleValue];
    }
    
    // Used in continuing lines when not possible to move to line
    CGFloat oldXValue;
    CGFloat oldYValue;
    BOOL drawnDiscontiguous = NO;
    
    
    if (self.drawSegmented) {
        CGContextSetFillColorWithColor(context, [[UIColor blueColor] CGColor]);
        
        for (CGFloat x = startingXCoordinate+1; x <= endingXCoordinate; x+=xIncrement) {
            xValue += xIncrementValue;
            
            returnedValue = [self.dataSource yForGraphView:self fromXValue:xValue];
            if ([returnedValue isKindOfClass:[NSNumber class]]) {
                yValue = [returnedValue doubleValue];
            } else if ([returnedValue isKindOfClass:[NSString class]]) {
                continue;
            }

            CGContextFillRect(context, CGRectMake(xOffset + (xValue*self.scale),yOffset-(yValue*self.scale),1,1));
        }
        
    } else {
        CGContextBeginPath(context);
        [[UIColor blueColor] setStroke];

        if ([returnedValue isKindOfClass:[NSNumber class]]) {
            CGContextMoveToPoint(context, xOffset + (xValue*self.scale), yOffset-(yValue*self.scale));
        } else {
            while (![returnedValue isKindOfClass:[NSNumber class]] && (xValue <= endingXCoordinate)) {
                returnedValue = [self.dataSource yForGraphView:self fromXValue:xValue];
                xValue += xIncrementValue;
            }
            if (xValue > endingXCoordinate) {
                return;
            }
            yValue = [returnedValue doubleValue];
        
            CGContextMoveToPoint(context, xOffset + (xValue*self.scale), yOffset-(yValue*self.scale));
       
        }

        
        for (CGFloat x = startingXCoordinate+1; x <= endingXCoordinate; x+=xIncrement) {
            xValue += xIncrementValue;

            returnedValue = [self.dataSource yForGraphView:self fromXValue:xValue];
            if ([returnedValue isKindOfClass:[NSNumber class]]) {
                yValue = [returnedValue doubleValue];
            } else if ([returnedValue isKindOfClass:[NSString class]]) {
                if (!drawnDiscontiguous) {
                    CGContextAddLineToPoint(context, xOffset + (oldXValue*self.scale), yOffset-(oldYValue*self.scale));
                    drawnDiscontiguous = YES;
                }
                continue;
            }


            drawnDiscontiguous = NO;
            oldXValue = xValue;
            oldYValue = yValue;
            
            CGContextAddLineToPoint(context, xOffset + (xValue*self.scale), yOffset-(yValue*self.scale));
            
        }
        CGContextStrokePath(context);
    }
}

@end
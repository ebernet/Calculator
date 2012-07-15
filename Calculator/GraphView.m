//
//  GraphView.m
//  Calculator
//
//  Created by Eytan Bernet on 7/12/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import "GraphView.h"
#import "AxesDrawer.h"

@interface GraphView ()
@end

@implementation GraphView

@synthesize scale = _scale;
@synthesize graphOrigin = _graphOrigin;
@synthesize dataSource = _dataSource;
@synthesize drawSegmented = _drawSegmented;

// default scale goes -10 to 10 in portrait view
#define DEFAULT_SCALE 15.00 
#define DEFAULT_PAN_RATE 1

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
    
    
    id returnedValue;       // Used to handle errors for the delegate method
    CGFloat yForX;          // The numerical value for it
    CGFloat theScale = DEFAULT_SCALE;    // Starting scale. Initially, the scale will be the default
    CGFloat maxX = self.bounds.size.width/theScale/2;     // Default given default size on iPhone
    CGFloat minX = -maxX;      // Default given default size on iPhone
    
    // Given X axis in portrait on iPhone is going -10 to 10, this is the default on Y axis
    CGFloat maxYPossible = self.bounds.size.width / self.bounds.size.height * (maxX-minX);
    // We also want to make sure the graph is visible, so if we never go over a small threshhold we need to decrease
    // Ths scale to a lower height. If you never get to a tenth the height, then you should probably retry
    CGFloat maxY = 0;
    
    // This is the iteration value. For figuring out max/min, we don't really ned to iterate over pixels, sufficient to
    // do it over points
    CGFloat incrementValue;
    
    while (maxY < (maxYPossible /3)) {
        incrementValue = (maxX - minX)/self.bounds.size.width;
        for (CGFloat x = minX; x <= maxX; x+= incrementValue) {
            returnedValue = [self.dataSource yForGraphView:self fromXValue:x];
            if ([returnedValue isKindOfClass:[NSNumber class]]) {
                yForX = [returnedValue doubleValue];
            } else {
                yForX = 0;
            }
            if ((yForX > maxY) || (yForX < -maxY)) {
                maxY = ABS(yForX);
            }
        }
        if (maxY == 0) return DEFAULT_SCALE; // On iPad, we display the graph before any calculation, so be sure to set it
        // to the default value otherwise you get stuck here. Also if all your graph is invaild (all values along axis
        // return NAN
        if (maxY < (maxYPossible /3)) {
            theScale *=2;
            maxX = self.bounds.size.width/theScale/2;
            minX = -maxX;
            maxYPossible /= 2;
        } else if (maxY > maxYPossible) {
            theScale /=2;
            maxX = self.bounds.size.width/theScale/2;
            minX = -maxX;
            maxYPossible *= 2;
            maxY = 0;
        }
    }
    NSLog(@"Default Scale: %f", theScale);
    return theScale;
    
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
        self.graphOrigin = CGPointMake(currentX + (translation.x / DEFAULT_PAN_RATE), currentY + (translation.y / DEFAULT_PAN_RATE));
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

- (void)resetScale
{
    self.scale = [self calculateDefaultScale];
    self.graphOrigin = CGPointMake(self.bounds.origin.x + self.bounds.size.width/2, self.bounds.origin.y + self.bounds.size.height/2);;
}

- (void)setup
{
    self.drawSegmented = NO;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

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
    
    // This is where we are at 0, 0 in screen point
    
    CGFloat yOffset = self.graphOrigin.y;
    CGFloat xOffset = self.graphOrigin.x;
    
    // Where we start
    CGFloat startingXCoordinate = -xOffset;
    CGFloat endingXCoordinate = startingXCoordinate + self.bounds.size.width; // On screen coordinates
    
    // In pixel coordinates
    CGFloat startingXValue = startingXCoordinate / self.scale;
    
    // What the increment is, in points
    CGFloat xIncrement = 1/screenScaling;
    CGFloat xIncrementValue = 1/self.scale/screenScaling;
    
    CGFloat xValue = startingXValue;
    CGFloat yValue;
    
    id returnedValue = [self.dataSource yForGraphView:self fromXValue:xValue];
    if ([returnedValue isKindOfClass:[NSNumber class]]) {
         yValue = [returnedValue doubleValue];
    } else if ([returnedValue isKindOfClass:[NSString class]]) {
        // If there is no proram, don't waste time analyzing
        if ([returnedValue isEqualToString:@"NOPROGRAM"]) return;
    }
    
    // Used in continuing lines when not possible to move to line
    CGFloat oldXValue;
    CGFloat oldYValue;
    BOOL drawnDiscontiguous = NO;
    
    
    // Draw by pixels
    if (self.drawSegmented) {
        CGContextSetFillColorWithColor(context, [[UIColor blueColor] CGColor]);
        
        // iterate along x coordinates according to our scale
        for (CGFloat x = startingXCoordinate; x <= endingXCoordinate; x+=xIncrement) {
            // and pixel coordinates
            xValue += xIncrementValue;
            
            // If the function does not evaluate to a real number, go to the next point/subpoint along the axis
            returnedValue = [self.dataSource yForGraphView:self fromXValue:xValue];
            if ([returnedValue isKindOfClass:[NSNumber class]]) {
                yValue = [returnedValue doubleValue];
            } else if ([returnedValue isKindOfClass:[NSString class]]) {
                continue;
            }

            // Once we have a valid point, draw it as a rectangle of 1 pixel
            CGContextFillRect(context, CGRectMake( (xValue*self.scale) + xOffset,yOffset-(yValue*self.scale),xIncrement,xIncrement));
        }
    // Draw by line    
    } else {
        CGContextBeginPath(context);
        [[UIColor blueColor] setStroke];

        if ([returnedValue isKindOfClass:[NSNumber class]]) {
            CGContextMoveToPoint(context,  (xValue*self.scale) + xOffset, yOffset-(yValue*self.scale));
        } else {
            while (![returnedValue isKindOfClass:[NSNumber class]] && (xValue <= endingXCoordinate)) {
                returnedValue = [self.dataSource yForGraphView:self fromXValue:xValue];
                xValue += xIncrementValue;
            }
            if (xValue > endingXCoordinate) {
                return;
            }
            yValue = [returnedValue doubleValue];
        
            CGContextMoveToPoint(context, (xValue*self.scale) + xOffset, yOffset-(yValue*self.scale));
       
        }

        
        for (CGFloat x = startingXCoordinate+1; x <= endingXCoordinate; x+=xIncrement) {
            xValue += xIncrementValue;

            returnedValue = [self.dataSource yForGraphView:self fromXValue:xValue];
            if ([returnedValue isKindOfClass:[NSNumber class]]) {
                yValue = [returnedValue doubleValue];
            } else if ([returnedValue isKindOfClass:[NSString class]]) {
                if (!drawnDiscontiguous) {
                    CGContextAddLineToPoint(context,  (oldXValue*self.scale) + xOffset, yOffset-(oldYValue*self.scale));
                    drawnDiscontiguous = YES;
                }
                CGContextMoveToPoint(context, (xValue*self.scale) + xOffset, yOffset-(yValue*self.scale));
               continue;
            }


            drawnDiscontiguous = NO;
            oldXValue = xValue;
            oldYValue = yValue;
            
            CGContextAddLineToPoint(context,  (xValue*self.scale) + xOffset, yOffset-(yValue*self.scale));
            
        }
        CGContextStrokePath(context);
    }
}

@end
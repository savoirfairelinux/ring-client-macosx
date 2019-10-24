/*
 *  Copyright (C) 2015-2016 Savoir-faire Linux Inc.
 *  Author: Alexandre Lision <alexandre.lision@savoirfairelinux.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
 */

#import "IconButton.h"
#import "NSColor+RingTheme.h"

#import <QuartzCore/QuartzCore.h>

@interface IconButton()
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@end

@implementation IconButton
NSString* BLINK_ANIMATION_IDENTIFIER = @"blinkAnimation";
@synthesize trackingArea;

-(void) awakeFromNib {
    if (!self.bgColor) {
        self.bgColor = [NSColor ringBlue];
    }

    if (!self.cornerRadius) {
        self.cornerRadius = @(NSWidth(self.frame) / 2);
    }

    if (self.imageInsets == 0)
        self.imageInsets = 8.0f;
    if (!self.imageIncreaseOnClick) {
        self.imageIncreaseOnClick = 0;
    }

    self.pressed = NO;

}

-(instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame: frameRect];
    if (!self.bgColor) {
        self.bgColor = [NSColor ringBlue];
    }

    if (!self.cornerRadius) {
        self.cornerRadius = @(NSWidth(self.frame) / 2);
    }

    if (self.imageInsets == 0)
        self.imageInsets = 8.0f;
    if (!self.imageIncreaseOnClick) {
        self.imageIncreaseOnClick = 0;
    }

    self.pressed = NO;
    return self;
}

-(void) setPressed:(BOOL)newVal
{
    _pressed = newVal;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    NSColor* backgroundColor;
    NSColor* backgroundStrokeColor;
    NSColor* tintColor = self.imageColor ? self.imageColor : [NSColor whiteColor];

    if (self.bgColor == [NSColor clearColor]) {
        backgroundColor = self.bgColor ;
        backgroundStrokeColor = self.borderColor ? self.borderColor : self.bgColor;
        if(!self.isEnabled) {
            if (self.buttonDisableColor) {
                tintColor = self.buttonDisableColor;
            } else {
                tintColor = [[NSColor grayColor] colorWithAlphaComponent:0.3];
            }
        }
    }
    else if (!self.isEnabled) {
        backgroundColor = [self.bgColor colorWithAlphaComponent:0.7];
        backgroundStrokeColor = self.borderColor ? self.borderColor: [self.bgColor colorWithAlphaComponent:0.7];
        if (self.buttonDisableColor) {
            tintColor = self.buttonDisableColor;
        } else {
            tintColor = [[NSColor grayColor] colorWithAlphaComponent:0.3];
        }
    } else if (self.mouseDown || self.isPressed) {
        if (self.highlightColor) {
            backgroundColor = self.highlightColor;
            backgroundStrokeColor = self.borderColor ? self.borderColor: [self.highlightColor darkenColorByValue:0.1];
        } else {
            backgroundColor = [self.bgColor darkenColorByValue:0.3];
            backgroundStrokeColor = self.borderColor ? self.borderColor: [self.bgColor darkenColorByValue:0.4];
        }
    }

    else {
        backgroundColor = self.bgColor;
        backgroundStrokeColor = self.borderColor ? self.borderColor: [self.bgColor darkenColorByValue:0.1];
    }

    //// Subframes
    NSRect group = NSMakeRect(NSMinX(dirtyRect) + floor(NSWidth(dirtyRect) * 0.03333) + 1,
                              NSMinY(dirtyRect) + floor(NSHeight(dirtyRect) * 0.03333) + 1,
                              floor(NSWidth(dirtyRect) * 0.96667) - floor(NSWidth(dirtyRect) * 0.03333),
                              floor(NSHeight(dirtyRect) * 0.96667) - floor(NSHeight(dirtyRect) * 0.03333));

    //// Group
    {
        //// Oval Drawing
        NSBezierPath* ovalPath = [NSBezierPath bezierPathWithRoundedRect:group
                                                                 xRadius:[self.cornerRadius floatValue]
                                                                 yRadius:[self.cornerRadius floatValue]];
        if(self.cornerColor) {
            NSRect frame = [self frame];

            [backgroundColor setFill];
            [ovalPath fill];

            CGPoint top = CGPointMake(frame.size.width * 0.5, 0);
            CGPoint right = CGPointMake(frame.size.width, frame.size.height * 0.5);
            CGPoint bottom = CGPointMake(frame.size.width * 0.5, frame.size.height);
            CGPoint left = CGPointMake(0, frame.size.height * 0.5);
            CGPoint topLeft = CGPointMake(0, 0);
            CGPoint topRight = CGPointMake(frame.size.width, 0);
            CGPoint bottomLeft = CGPointMake(0, frame.size.height);
            CGPoint bottomRight = CGPointMake(frame.size.width, frame.size.height);

            NSBezierPath* topLeftPath = [[NSBezierPath alloc] init];
            NSPoint pointArrayLeft[3];
            pointArrayLeft[0] = left;
            pointArrayLeft[1] = topLeft;
            pointArrayLeft[2] = top;

            [topLeftPath appendBezierPathWithPoints:pointArrayLeft count:3];
            [topLeftPath appendBezierPathWithArcFromPoint: topLeft toPoint: left radius: 20.0f];
            [self.cornerColor setFill];
            [topLeftPath fill];

            NSBezierPath* topRightPath = [[NSBezierPath alloc] init];
            NSPoint pointArrayTop[3];
            pointArrayTop[0] = top;
            pointArrayTop[1] = topRight;
            pointArrayTop[2] = right;
            [topRightPath appendBezierPathWithPoints:pointArrayTop count:3];
            [topRightPath appendBezierPathWithArcFromPoint: topRight toPoint: top radius: 20.0f];
            [topRightPath fill];

            NSBezierPath* bottomLeftPath = [[NSBezierPath alloc] init];
            NSPoint pointArrayRight[3];
            pointArrayRight[0] = right;
            pointArrayRight[1] = bottomRight;
            pointArrayRight[2] = bottom;
            [bottomLeftPath appendBezierPathWithPoints:pointArrayRight count:3];
            [bottomLeftPath appendBezierPathWithArcFromPoint: bottomRight toPoint: right radius: 20.0f];
            [bottomLeftPath fill];

            NSBezierPath* bottomRightPath = [[NSBezierPath alloc] init];
            NSPoint pointArrayBottom[3];
            pointArrayBottom[0] = bottom;
            pointArrayBottom[1] = bottomLeft;
            pointArrayBottom[2] = left;
            [bottomRightPath appendBezierPathWithPoints:pointArrayBottom count:3];
            [bottomRightPath appendBezierPathWithArcFromPoint: bottomLeft toPoint: bottom radius: 20.0f];
            [bottomRightPath fill];
            return;
        }

        [backgroundColor setFill];
        [ovalPath fill];
        [backgroundStrokeColor setStroke];
        [ovalPath setLineWidth: 1];
        [ovalPath stroke];

        [NSGraphicsContext saveGraphicsState];

        NSBezierPath* path = [NSBezierPath bezierPathWithRect:dirtyRect];
        [path addClip];

        auto insets = self.mouseDown ? (self.imageInsets - self.imageIncreaseOnClick) : self.imageInsets;
        auto rect = NSInsetRect(group, insets, insets);
        if ([self title].length == 0) {
            [self setImagePosition:NSImageOverlaps];
            [[NSColor image:self.image tintedWithColor:tintColor] drawInRect:rect
                                                                    fromRect:NSZeroRect
                                                                   operation:NSCompositeSourceOver
                                                                    fraction:1.0
                                                              respectFlipped:YES
                                                                       hints:nil];
            
            [NSGraphicsContext restoreGraphicsState];
            return;
        }

        NSRect rectText = rect;
        NSRect rectImage = rect;
        NSDictionary *att = nil;

        NSMutableParagraphStyle *style =
        [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineBreakMode:NSLineBreakByWordWrapping];
        [style setAlignment:NSCenterTextAlignment];
        att = [[NSDictionary alloc] initWithObjectsAndKeys:
               style, NSParagraphStyleAttributeName,
               tintColor,
               NSForegroundColorAttributeName, nil];
        if(self.fontSize) {
            NSFont *font = [NSFont fontWithName:@"Helvetica Neue Light" size: self.fontSize];
            att = [[NSDictionary alloc] initWithObjectsAndKeys:
                   font,NSFontAttributeName,
                   style, NSParagraphStyleAttributeName,
                   tintColor, NSForegroundColorAttributeName, nil];

        }
        rectText.size = [[self title] sizeWithAttributes:att];
        rectImage.size.width = rectImage.size.height;
        rectText.origin.x = floor( NSMidX(rect) - (rectText.size.width / 2 - rectImage.size.width / 2));
        rectImage.origin.x = rectText.origin.x - rectImage.size.width - insets;
        rectText.origin.y = floor( NSMidY([self bounds]) - rectText.size.height / 2 );
        [[self title] drawInRect:rectText withAttributes:att];
        
        [[NSColor image:self.image tintedWithColor:tintColor] drawInRect:rectImage
                                                                fromRect:NSZeroRect
                                                               operation:NSCompositeSourceOver
                                                                fraction:1.0
                                                          respectFlipped:YES
                                                                   hints:nil];
        [NSGraphicsContext restoreGraphicsState];
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    self.mouseDown = TRUE;
    [self setNeedsDisplay:YES];

    [super mouseDown:theEvent];

    self.mouseDown = FALSE;
    [self setNeedsDisplay:YES];
}

-(void)startBlinkAnimationfrom:(NSColor*)startColor
                            to:(NSColor*)endColor
                   scaleFactor:(CGFloat)scaleFactor
                      duration:(CGFloat) duration {
    CIFilter *filter = [CIFilter filterWithName:@"CIFalseColor"];
    [filter setDefaults];
    [filter setValue:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0] forKey:@"inputColor0"];
    [filter setValue:[CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forKey:@"inputColor1"];
    [filter setName: @"pulseFilter"];
    [[self layer] setFilters:[NSArray arrayWithObject: filter]];
    CABasicAnimation* pulseAnimation = [CABasicAnimation animation];
    pulseAnimation.keyPath = @"filters.pulseFilter.inputColor1";
    pulseAnimation.fromValue =  [CIColor colorWithCGColor:[startColor CGColor]];
    pulseAnimation.toValue = [CIColor colorWithCGColor:[endColor CGColor]];

    auto currentOrigin = self.frame.origin;
    auto currentSize = self.frame.size;
    auto newSize = CGSizeMake(currentSize.width * scaleFactor, currentSize.height * scaleFactor);
    auto newOrigin = CGPointMake(currentOrigin.x - (newSize.width - currentSize.width)  * 0.5, currentOrigin.y - (newSize.height - currentSize.height) * 0.5 );
    CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    positionAnimation.fromValue = [NSValue valueWithPoint:NSPointFromCGPoint(currentOrigin)];
    positionAnimation.toValue = [NSValue valueWithPoint:NSPointFromCGPoint(newOrigin)];
    CABasicAnimation *sizeAnimation = [CABasicAnimation animationWithKeyPath:@"bounds.size"];
    sizeAnimation.fromValue = [NSValue valueWithSize:NSSizeFromCGSize(currentSize)];
    sizeAnimation.toValue = [NSValue valueWithSize:NSSizeFromCGSize(newSize)];
    CAAnimationGroup * group =[CAAnimationGroup animation];
    group.removedOnCompletion=NO; group.fillMode=kCAFillModeForwards;
    group.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear];
    group.animations =[NSArray arrayWithObjects: pulseAnimation, positionAnimation, sizeAnimation, nil];
    group.duration =duration;
    group.repeatCount = HUGE;
    group.autoreverses = NO;
    [self.layer addAnimation:group forKey:BLINK_ANIMATION_IDENTIFIER];
    self.animating = true;
}

-(void)stopBlinkAnimation {
    self.animating = false;
    [self.layer removeAnimationForKey:BLINK_ANIMATION_IDENTIFIER];
}

@end

//
//  SVMView.h
//  UCocoa
//
//  Created by Swordow on 5/2/15.
//  Copyright (c) 2015 Swordow. All rights reserved.
//

#ifndef UCocoa_SVMView_h
#define UCocoa_SVMView_h


#import <Cocoa/Cocoa.h>

struct XPoint {
  NSPoint pos;
  signed char value;
};

@interface SVMView : NSView {
  struct XPoint pointArray[10000];
  int pointCount;
  NSColor* colors[7];
  signed char cur_value;
  NSBitmapImageRep* buffer;
  NSTimer* timer;
}
-(id)initWithFrame:(NSRect)frameRect;
-(void)dealloc;
-(void)drawRect:(NSRect)dirtyRect;
-(void)runSVM:(id)param;
-(void)mouseDown:(NSEvent*) event;
-(void)updateView:(NSTimer*)sender;
-(IBAction)run:(id)sender;
-(IBAction)change:(id)sender;
-(IBAction)clear:(id)sender;
-(IBAction)load:(id)sender;
-(IBAction)save:(id)sender;

@end

#endif

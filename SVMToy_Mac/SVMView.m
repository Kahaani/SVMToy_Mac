//
//  SVMView.m
//  UCocoa
//
//  Created by Swordow on 5/2/15.
//  Copyright (c) 2015 Swordow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVMView.h"
#include "svm.h"

#define DEFAULT_PARAM "-t 2 -c 100"
#define XLEN 500
#define YLEN 500

@interface SVMView ()
@property (strong) NSThread* thread;
@property (strong) IBOutlet NSTextField*   cmd;
-(void) DrawLine:(CGFloat)x1 :(CGFloat)y1 :(CGFloat)x2 :(CGFloat)y2 :(NSColor*)c;
-(NSColor*) toRGB:(int)r :(int)g :(int)b;
-(void) SetPixel:(CGFloat)x :(CGFloat)y :(NSColor*)c;
-(void) draw_all_points;
@end

@implementation SVMView

-(NSColor*) toRGB:(int)r :(int)g :(int)b
{
  return [NSColor colorWithDeviceRed:((CGFloat)(r+1))/256 green:((CGFloat)(g+1))/256 blue:((CGFloat)(b+1))/256 alpha:1.f];
}

-(id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  if (self)
  {
    colors[0] = [self toRGB:0:0:0];
    colors[1] = [self toRGB:0:120:120];
    colors[2] = [self toRGB:120:120:0];
    colors[3] = [self toRGB:120:0:120];
    colors[4] = [self toRGB:0:200:200];
    colors[5] = [self toRGB:200:200:0];
    colors[6] = [self toRGB:200:0:200];
    cur_value = 4;
  }
  return self;
}

-(void)dealloc
{
}

-(void) draw_all_points
{
  for (int i=0; i<pointCount; i++)
  {
    NSRect rect;
    rect.origin.x = pointArray[i].pos.x*XLEN;
    rect.origin.y = pointArray[i].pos.y*YLEN;
    rect.size.height = 4;
    rect.size.width = 4;
    [colors[pointArray[i].value]set];
    NSBezierPath* cPoint = [NSBezierPath bezierPathWithOvalInRect:rect];
    [cPoint fill];
  }
  
}

-(void) SetPixel:(CGFloat)x :(CGFloat)y :(NSColor *)c
{

  NSRect rect;
  rect.origin = NSMakePoint(x, y);
  rect.size.height = 1;
  rect.size.width = 1;
  [c set];
  NSBezierPath* cPoint = [NSBezierPath bezierPathWithOvalInRect:rect];
  [cPoint fill];
}

-(void) DrawLine:(CGFloat)x1 :(CGFloat)y1 :(CGFloat)x2 :(CGFloat)y2 :(NSColor*)c
{
  NSBezierPath* p = [NSBezierPath new];
  [p moveToPoint:NSMakePoint(x1, y1)];
  [p lineToPoint:NSMakePoint(x2, y2)];
  [c set];
  [p setLineWidth:1.0f];
  [p fill];
}

-(void)drawRect:(NSRect)dirtyRect
{
  NSColor *w = [NSColor blackColor];
  [w set];
  NSRectFill([self bounds]);
  if (!buffer) {
    [self lockFocus];
    buffer = [[NSBitmapImageRep alloc] initWithFocusedViewRect:dirtyRect];
    [self unlockFocus];
    if (!buffer) NSLog(@"buffer create failed\n");
    [[self cmd] setStringValue:@"-t 2 -c 100"];
  }
  [buffer drawAtPoint:NSMakePoint(0,0)];
}

- (void) mouseDown:(NSEvent *)event
{
  NSPoint curPos;
  curPos = [self convertPoint:[event locationInWindow] fromView:nil];
  pointArray[pointCount].value = cur_value;
  pointArray[pointCount].pos.x = curPos.x/XLEN;
  pointArray[pointCount].pos.y = curPos.y/YLEN;
  pointCount++;
  NSGraphicsContext* gc = [NSGraphicsContext currentContext];
  if (!gc) NSLog(@"GC failed\n");
  [gc saveGraphicsState];
  NSGraphicsContext* bgc = [NSGraphicsContext graphicsContextWithBitmapImageRep:buffer];
  [NSGraphicsContext setCurrentContext:bgc];
  NSRect rect;
  rect.origin = curPos;
  rect.size.height = 4;
  rect.size.width = 4;
  [colors[cur_value] set];
  NSBezierPath* cPoint = [NSBezierPath bezierPathWithOvalInRect:rect];
  [cPoint fill];
  [NSGraphicsContext restoreGraphicsState];
  [self setNeedsDisplay:YES];
}

-(void)updateView:(NSTimer *)sender
{
  [self setNeedsDisplay:YES];
}

-(void)runSVM:(id)tparam{
  // guard
  if(pointCount == 0) return;
  NSLog(@"running SVM\n");
  NSGraphicsContext* gc = [NSGraphicsContext currentContext];
  if (!gc) NSLog(@"GC failed\n");
  [gc saveGraphicsState];
  NSGraphicsContext* bgc = [NSGraphicsContext graphicsContextWithBitmapImageRep:buffer];
  [NSGraphicsContext setCurrentContext:bgc];
  
  //
  struct svm_parameter param;
  int i,j;
  
  // default values
  param.svm_type = C_SVC;
  param.kernel_type = RBF;
  param.degree = 3;
  param.gamma = 0;
  param.coef0 = 0;
  param.nu = 0.5;
  param.cache_size = 100;
  param.C = 1;
  param.eps = 1e-3;
  param.p = 0.1;
  param.shrinking = 1;
  param.probability = 0;
  param.nr_weight = 0;
  param.weight_label = NULL;
  param.weight = NULL;
  
  // parse options
  const char *p = [[[self cmd] stringValue] cStringUsingEncoding:NSASCIIStringEncoding];
  NSLog(@"cmd=%s\n",p);
  while (1) {
    while (*p && *p != '-')
      p++;
    
    if (*p == '\0')
      break;
    
    p++;
    switch (*p++) {
      case 's':
        param.svm_type = atoi(p);
        break;
      case 't':
        param.kernel_type = atoi(p);
        break;
      case 'd':
        param.degree = atoi(p);
        break;
      case 'g':
        param.gamma = atof(p);
        break;
      case 'r':
        param.coef0 = atof(p);
        break;
      case 'n':
        param.nu = atof(p);
        break;
      case 'm':
        param.cache_size = atof(p);
        break;
      case 'c':
        param.C = atof(p);
        break;
      case 'e':
        param.eps = atof(p);
        break;
      case 'p':
        param.p = atof(p);
        break;
      case 'h':
        param.shrinking = atoi(p);
        break;
      case 'b':
        param.probability = atoi(p);
        break;
      case 'w':
        ++param.nr_weight;
        param.weight_label = (int *)realloc(param.weight_label,sizeof(int)*param.nr_weight);
        param.weight = (double *)realloc(param.weight,sizeof(double)*param.nr_weight);
        param.weight_label[param.nr_weight-1] = atoi(p);
        while(*p && !isspace(*p)) ++p;
        param.weight[param.nr_weight-1] = atof(p);
        break;
    }
  }
  
  // build problem
  struct svm_problem prob;
  
  prob.l = pointCount;
  prob.y = malloc(sizeof(double)*prob.l);
  
  if(param.kernel_type == PRECOMPUTED)
  {
  }
  else if(param.svm_type == EPSILON_SVR ||
          param.svm_type == NU_SVR)
  {
    if(param.gamma == 0) param.gamma = 1;
    struct svm_node *x_space = malloc(sizeof(struct svm_node)*2*prob.l);
    prob.x = malloc(sizeof(struct svm_node)*prob.l);
    
    i = 0;
    for (int q = 0; q < pointCount; q++, i++)
    {
      x_space[2 * i].index = 1;
      x_space[2 * i].value = pointArray[q].pos.x;
      x_space[2 * i + 1].index = -1;
      prob.x[i] = &x_space[2 * i];
      prob.y[i] = pointArray[q].pos.y;
    }
    
    // build model & classify
    struct svm_model *model = svm_train(&prob, &param);
    struct svm_node x[2];
    x[0].index = 1;
    x[1].index = -1;
    int *j = malloc(sizeof(int)*XLEN);
    
    for (i = 0; i < XLEN; i++)
    {
      x[0].value = (double) i / XLEN;
      j[i] = (int)(YLEN*svm_predict(model, x));
    }
    
    [self DrawLine:0:0:0:YLEN:colors[0]];
    
    int p = (int)(param.p * YLEN);
    for(int i=1; i < XLEN; i++)
    {
      [self DrawLine:i:0:i:YLEN:colors[0]];
      
      [self DrawLine:i-1:j[i-1]:i:j[i]:colors[5]];
      
      if(param.svm_type == EPSILON_SVR)
      {
        [self DrawLine:i-1:j[i-1]+p:i:j[i]+p:colors[2]];
        
        [self DrawLine:i-1:j[i-1]-p:i:j[i]-p:colors[2]];
      }
    }
    
    svm_free_and_destroy_model(&model);
    free(j);
    free(x_space);
    free(prob.x);
    free(prob.y);
  }
  else
  {
    if(param.gamma == 0) param.gamma = 0.5;
    struct svm_node *x_space = malloc(sizeof(struct svm_node)*3*prob.l);
    prob.x = malloc(sizeof(struct svm_node)*prob.l);
    
    i = 0;
    for (int q = 0; q < pointCount; q++, i++)
    {
      x_space[3 * i].index = 1;
      x_space[3 * i].value = pointArray[q].pos.x;
      x_space[3 * i + 1].index = 2;
      x_space[3 * i + 1].value = pointArray[q].pos.y;
      x_space[3 * i + 2].index = -1;
      prob.x[i] = &x_space[3 * i];
      prob.y[i] = pointArray[q].value;
    }
    
    // build model & classify
    struct svm_model *model = svm_train(&prob, &param);
    struct svm_node x[3];
    x[0].index = 1;
    x[1].index = 2;
    x[2].index = -1;
    
    for (i = 0; i < XLEN; i++)
      for (j = 0; j < YLEN; j++) {
        x[0].value = (double) i / XLEN;
        x[1].value = (double) j / YLEN;
        double d = svm_predict(model, x);
        if (param.svm_type == ONE_CLASS && d<0) d=2;
        [self SetPixel:(CGFloat)i :(CGFloat)j :colors[(int)d]];
      }
    
    svm_free_and_destroy_model(&model);
    free(x_space);
    free(prob.x);
    free(prob.y);
  }
  free(param.weight_label);
  free(param.weight);
  [self draw_all_points];
  [NSGraphicsContext restoreGraphicsState];
  [self setNeedsDisplay:YES];
  
}

-(IBAction)run:(id)sender
{
  // guard
  if(pointCount == 0) return;
  { // clear
    NSGraphicsContext* bgc = [NSGraphicsContext graphicsContextWithBitmapImageRep:buffer];
    if (!bgc) NSLog(@"BGC failed\n");
    [NSGraphicsContext setCurrentContext:bgc];
    NSColor *w = [NSColor blackColor];
    [w set];
    NSRectFill([self bounds]);
    [self draw_all_points];
  }
  timer = [NSTimer scheduledTimerWithTimeInterval:(1.0/60.f) target:self selector:@selector(updateView:) userInfo:nil repeats:YES];
  [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
  NSThread* t = [[NSThread alloc] initWithTarget:self selector:@selector(runSVM:) object:nil];
  [t start];
}

-(IBAction)change:(id)sender
{
  cur_value++;
  if (cur_value>6) cur_value = 4;
}

-(IBAction)clear:(id)sender
{
  NSGraphicsContext* gc = [NSGraphicsContext currentContext];
  if (!gc) NSLog(@"GC failed\n");
  [gc saveGraphicsState];
  NSGraphicsContext* bgc = [NSGraphicsContext graphicsContextWithBitmapImageRep:buffer];
  if (!bgc) NSLog(@"BGC failed\n");
  [NSGraphicsContext setCurrentContext:bgc];
  NSColor *w = [NSColor blackColor];
  [w set];
  NSRectFill([self bounds]);
  [NSGraphicsContext restoreGraphicsState];
  cur_value = 4;
  pointCount = 0;
  [self setNeedsDisplay:YES];
}

-(IBAction)load:(id)sender
{
}

-(IBAction)save:(id)sender
{
}


@end

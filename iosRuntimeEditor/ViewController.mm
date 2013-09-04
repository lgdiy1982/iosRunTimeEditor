//
//  ViewController.m
//  iosRuntimeEditor
//
//  Created by lg on 8/24/13.
//  Copyright (c) 2013 lg. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import <objc/message.h>
#include <list>

@class PointContext;

CGRect rectInflate(CGPoint pt, CGFloat edge)
{
    return CGRectMake(pt.x - edge/2, pt.y - edge/2, edge, edge);
}

CGPoint tl(CGRect rect) {  return rect.origin; }
CGPoint tr(CGRect rect)  { return CGPointMake(rect.origin.x + rect.size.width, rect.origin.y) ;}
CGPoint rb(CGRect rect)  { return CGPointMake(rect.origin.x + rect.size.width, rect.origin.y) ;}
CGPoint bl(CGRect rect)  { return CGPointMake(rect.origin.x + rect.size.width, rect.origin.y) ;}

struct CPoint :public CGPoint {
public:
    CPoint(CGFloat x, CGFloat y)
    {
        this->x = x;
        this->y= y;
    }
    CPoint(const CGPoint& ref)
    {
        x = ref.x;
        y = ref.y ;
    }
    void operator = (const CGPoint& ref)
    {
        x = ref.x;
        y = ref.y;
    }
    
    CPoint operator + (const CGPoint& ref )
    {
        return CPoint(this->x + ref.x, this->y + ref.y);
    }
    
    CPoint operator - (const CGPoint& ref)
    {
        return CPoint(this->x -ref.x, this->y - ref.y);
    }
    
    CPoint& operator += (const CGPoint& ref)
    {
        x += ref.x;
        y += ref.y;
        return *this;
    }
    
    CPoint& operator -= (const CGPoint& ref)
    {
        x -= ref.x;
        y -= ref.y;
        return *this;
    }
    
    bool operator == (const CGPoint& ref)
    {
        return  x == ref.x && y == ref.y;
    }
    
    bool operator != (const CGPoint& ref)
    {
        return  !(*this == ref);
    }
};



#define LINEMARGIN 4


enum EPtState {
    eNone = 0x0000,
    
    eInside = 0x1000,
    
    eInCornerTL = 0x0001,
    eInCornerTR = 0x0002,
    eInCornerRB = 0x0004 ,
    eInCornerBL = 0x0010,
    
    eInEdgeT = 0x0010,
    eInEdgeL = 0x0020,
    eInEdgeB = 0x0040,
    eInEdgeR = 0x0100,
    
    eInCorner = eInCornerTL | eInCornerTR | eInCornerRB | eInCornerBL,
    eInEdge = eInEdgeT | eInEdgeL | eInEdgeB | eInEdgeR,
};

EPtState ptState(CGPoint pt, CGRect frame)
{
    
    if (CGRectContainsPoint(rectInflate(tl(frame), LINEMARGIN), pt)) {
        return eInCornerTL;
    }
    if (CGRectContainsPoint(rectInflate(tr(frame), LINEMARGIN), pt)) {
        return eInCornerTR;
    }
    if (CGRectContainsPoint(rectInflate(rb(frame), LINEMARGIN), pt)) {
        return eInCornerRB;
    }
    if (CGRectContainsPoint(rectInflate(bl(frame), LINEMARGIN), pt)) {
        return eInCornerBL;
    }
    
    if (CGRectContainsPoint(frame, pt)) {
        return eInside;
    }
    
    return  eNone;
}


bool isInCorner(EPtState e)
{
    return  (e & eInCorner) == eInCorner;
}

bool isInLine(EPtState e)
{
    return (e & eInEdge) == eInEdge;
}




@interface PointContext : NSObject
@property (nonatomic) UIView *view;
@property (nonatomic) enum EPtState ptCtx;
@end

@implementation PointContext
@synthesize view, ptCtx;
@end




//find the deepest view
//priority corner > line = block
PointContext* hitTest(CGPoint pt,  UIView* root)
{
    PointContext * ctx = [[PointContext alloc] init];
    ctx.view = root;
    ctx.ptCtx = eInside;
    std::list<UIView*> q;
    q.push_front(root);
    
    while (!q.empty()) {
        UIView *top = q.back();
        q.pop_back();
        
        for(UIView *childView in top.subviews) {
            CGPoint inpt = [childView convertPoint: pt fromView:root];
            enum EPtState state = ptState(inpt, childView.bounds);
            if (isInCorner( state )) {
                ctx.ptCtx = state;
                ctx.view = childView;
            }
            else if (isInLine(state) && !isInCorner(ctx.ptCtx)) {
                ctx.ptCtx = state;
                ctx.view = childView;
            }
            else if ( state == eInside && !isInCorner(ctx.ptCtx)) {
                ctx.ptCtx = state;
                ctx.view = childView;
                q.push_front(childView);
            }            
        }
    }
    return ctx;
}


void disableChildren (UIView* root)
{
    for (UIView *childView in root.subviews) {
        [root.subviews makeObjectsPerformSelector:@selector(setUserInteractionEnabled:) withObject:[NSNumber numberWithBool:FALSE]];
        disableChildren(childView);
    }    
}



@interface ViewController ()
{
    PointContext *ctx ;
    CGPoint lastPos;
    
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    disableChildren(self.view);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchesBegan");
    for (UITouch *touch in touches)
    {
        CGPoint pt = [touch locationInView:self.view];
        ctx = hitTest(pt, self.view);
        lastPos = pt;
        //NSLog(@"view tag [%d] state %d" , ctx.view.tag, ctx.ptCtx);
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchesMoved");
    for (UITouch *touch in touches)
    {
        if (ctx.view != self.view && ctx.ptCtx == eInside)
        {
            CGPoint curPt = [touch locationInView:self.view];
            ctx.view.center = CGPointMake(ctx.view.center.x + curPt.x - lastPos.x ,  ctx.view.center.y + curPt.y - lastPos.y);
            lastPos = [touch locationInView:self.view];
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchesEnded");
}

void Swizzle(Class c, SEL orig, SEL newsel)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, newsel);
    c = object_getClass((id)c);
    
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, newsel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
         method_exchangeImplementations(origMethod, newMethod);
}

//- (void)drawRect:(CGRect)rect {
//    [super drawRect:rect];
//    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
//    
//    // Draw them with a 2.0 stroke width so they are a bit more visible.
//    CGContextSetLineWidth(context, 2.0);
//    
//    CGContextMoveToPoint(context, 0,0); //start at this point
//    
//    CGContextAddLineToPoint(context, 20, 20); //draw to this point
//    
//    // and now draw the Path!
//    CGContextStrokePath(context);
//}

@end

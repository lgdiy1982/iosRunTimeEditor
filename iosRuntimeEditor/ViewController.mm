//
//  ViewController.m
//  iosRuntimeEditor
//
//  Created by lg on 8/24/13.
//  Copyright (c) 2013 lg. All rights reserved.
//

#import "ViewController.h"
#include <list>

@class PointContext;

CGRect rectInflate(CGPoint pt, CGFloat edge)
{
    return CGRectMake(pt.x - edge/2, pt.y - edge/2, edge, edge);
}
#define LINEMARGIN 4


enum EPtState {
    eInside = 0x0000,
    
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
//    if (rectInflate() ) {
//
//    }
    
    return  eInside;
}


bool isInCorner(EPtState e)
{
    return  (e | eInCorner) == eInCorner;
}

bool isInLine(EPtState e)
{
    return (e | eInEdge) == eInEdge;
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
            CGPoint pt = [childView convertPoint: pt fromView:root];
            enum EPtState state = ptState(pt, childView.frame);
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
            }
            q.push_front(childView);
        }
    }
    return ctx;
}


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}







@end

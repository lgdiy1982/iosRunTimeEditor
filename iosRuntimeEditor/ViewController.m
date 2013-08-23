//
//  ViewController.m
//  iosRuntimeEditor
//
//  Created by lg on 8/24/13.
//  Copyright (c) 2013 lg. All rights reserved.
//

#import "ViewController.h"

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
#define LINEMARGIN 4



enum EPtState
{
    inside=0x0000,
    
    topC=0x0010,
    leftC=0x0020,
    bottomC=0x0040,
    rightC=0x0100,
    
    topL = 0x0000,
    leftL=0x0001,
    bottomL=0x0002,
    rightL=0x0004,
    
    
    inConor = topC|leftC|bottomC|rightC,
    inLine = topL|leftL|bottomL|rightL
} ;


@class PointContext;

CGRect rectInflate(CGPoint pt, CGFloat edge)
{
    return CGRectMake(pt.x - edge/2, pt.y - edge/2, edge, edge);
}

EPtState ptState(CGPoint pt, CGRect frame)
{
    if (rectInflate(frame.topleft) ) {
        
    }
    return  topC;
}


bool isInCorner(EPtState e)
{
    return  (e | inConor) == inConor;
}

bool isInLine(EPtState e)
{
    return (e | inLine) == inLine;
}



@interface PointContext : NSObject
@property (nonatomic) UIView *view;
@property (nonatomic) enum EPtState ptCtx;
@end

@implementation PointContext
@synthesize view, ptCtx;
@end



@interface ViewController ()
@property (strong, nonatomic) IBOutlet UITextView *infoTextView;

@end


//find the deepest view
//priority corner > line = block
PointContext* hitTest(CGPoint pt,  UIView* root)
{
    PointContext * ctx = [[PointContext alloc] init];
    ctx.view = root;
    ctx.ptCtx = inside;
    std::list<UIView*> q;
    q.push_front(root);
    
    while (!q.empty()) {
        UIView *top = q.back();
        q.pop_back();
        
        for(UIView *childView in top.subviews) {
            CGPoint pt = [childView convertPoint: pt fromView:root];
            EPtState state = ptState(pt, childView.frame);
            if (isInCorner( state )) {
                ctx.ptCtx = state;
                ctx.view = childView;
            }
            else if (isInLine(state) && !isInCorner(ctx.ptCtx)) {
                ctx.ptCtx = state;
                ctx.view = childView;
            }
            else if ( state == inside && !isInCorner(ctx.ptCtx)) {
                ctx.ptCtx = state;
                ctx.view = childView;
            }
            q.push_front(childView);
        }
    }
    return ctx;
}
@end

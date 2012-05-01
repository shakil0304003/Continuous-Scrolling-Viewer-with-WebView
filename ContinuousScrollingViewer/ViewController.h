//
//  ViewController.h
//  ContinuousScrollingViewer
//
//  Created by USER on 12/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomScrollView.h"

@interface ViewController : UIViewController<CustomScrollViewDelegate>
{
    IBOutlet CustomScrollView *scrollView;
    IBOutlet UIButton *next;
    IBOutlet UIButton *previous;
}

-(IBAction)Click:(id)sender;

@end

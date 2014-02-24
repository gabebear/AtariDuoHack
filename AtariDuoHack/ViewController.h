//
//  ViewController.h
//  AtariDuoHack
//
//  Created by Gabe Ghearing on 2/19/14.
//  Copyright (c) 2014 Foolish Code. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property(nonatomic, weak) IBOutlet UITextView *txtView;

@property(nonatomic,weak) IBOutlet UILabel *up;
@property(nonatomic,weak) IBOutlet UILabel *down;
@property(nonatomic,weak) IBOutlet UILabel *left;
@property(nonatomic,weak) IBOutlet UILabel *right;
@property(nonatomic,weak) IBOutlet UILabel *butt_a;
@property(nonatomic,weak) IBOutlet UILabel *butt_b;
@property(nonatomic,weak) IBOutlet UILabel *butt_x;
@property(nonatomic,weak) IBOutlet UILabel *butt_y;

@end

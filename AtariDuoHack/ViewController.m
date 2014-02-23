//
//  ViewController.m
//  AtariDuoHack
//
//  Created by Gabe Ghearing on 2/19/14.
//  Copyright (c) 2014 Foolish Code. All rights reserved.
//

#import "ViewController.h"
#import "AtariDuoGamePad.h"

@interface ViewController ()
@property (nonatomic, strong) AtariDuoGamePad *gamePad;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.gamePad = [[AtariDuoGamePad alloc] init];
	
	// simulating a mainloop with a timer (you'll probably use something else like GLKit's update)
	[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(mainGameLoop) userInfo:nil repeats:YES];
	
	[self konamiCheat];
}

- (void)konamiCheat {
	__block int konamiCodeIndex = 0;
	static uint8_t konamiCode[] = {
		ATARI_UP,
		ATARI_UP,
		ATARI_DOWN,
		ATARI_DOWN,
		ATARI_LEFT,
		ATARI_RIGHT,
		ATARI_LEFT,
		ATARI_RIGHT,
		ATARI_BUTT_B,
		ATARI_BUTT_A,
		0 // marking the end of the code with a 0
	};
	self.gamePad.handler = ^(uint8_t state) {
		// ignore when nothing is pressed
		if (state != 0) {
			uint8_t konamiState = konamiCode[konamiCodeIndex];
			if (konamiState == state) {
				// correct! go to next part of code
				konamiCodeIndex++;
			} else {
				// incorrect! start over
				konamiCodeIndex = 0;
			}
			
			if (konamiCode[konamiCodeIndex] == 0) {
				// we've reached the end so the code is successful!
				[[[UIAlertView alloc] initWithTitle:@"God Mode!!!"
				                            message:@"Too bad this isn't a game... yet"
				                           delegate:nil
				                  cancelButtonTitle:@"Done"
				                  otherButtonTitles:nil] show];
				
				
				konamiCodeIndex = 0;
			}
		}
	};
}

- (void)mainGameLoop {
	// This just prints the state of the gamepad
	uint8_t state = [self.gamePad pollCurrentState];
	NSString *stateString = @"";
	if (state == 0) {
		stateString = @"nothing pressed";
	}
	if (state & ATARI_BUTT_Y) {
		stateString = [NSString stringWithFormat:@"Y %@", stateString];
	}
	if (state & ATARI_BUTT_X) {
		stateString = [NSString stringWithFormat:@"X %@", stateString];
	}
	if (state & ATARI_BUTT_B) {
		stateString = [NSString stringWithFormat:@"B %@", stateString];
	}
	if (state & ATARI_BUTT_A) {
		stateString = [NSString stringWithFormat:@"A %@", stateString];
	}
	if (state & ATARI_RIGHT) {
		stateString = [NSString stringWithFormat:@"RIGHT %@", stateString];
	}
	if (state & ATARI_LEFT) {
		stateString = [NSString stringWithFormat:@"LEFT %@", stateString];
	}
	if (state & ATARI_DOWN) {
		stateString = [NSString stringWithFormat:@"DOWN %@", stateString];
	}
	if (state & ATARI_UP) {
		stateString = [NSString stringWithFormat:@"UP %@", stateString];
	}
	stateString = [NSString
	               stringWithFormat:@"\n\nstate: %02x %@", state, stateString];
	[self.txtView setText:stateString];
}


@end

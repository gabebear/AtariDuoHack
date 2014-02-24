//
//  AtariDuoGamePad.h
//  AtariDuoHack
//
//  Created by Gabe Ghearing on 2/19/14.
//  Copyright (c) 2014 Foolish Code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>

//
//      ⬆️
//    ⬅️  ➡️      X  Y
//      ⬇️       A  B
//

typedef enum {
	ATARI_UP = 0x01,
	ATARI_DOWN = 0x08,
	ATARI_LEFT = 0x02,
	ATARI_RIGHT = 0x04,
	ATARI_BUTT_X = 0x80,
	ATARI_BUTT_Y = 0x10,
	ATARI_BUTT_A = 0x40,
	ATARI_BUTT_B = 0x20,
} ATARI_ENUMS;


@interface AtariDuoGamePad : NSObject <NSStreamDelegate, NSCopying>

// !! MUST BE RUN ON MAIN THREAD !!
// This is probably what you want to use in your main game loop
//  - checks for new data (doesn't wait for runloop check)
//  - if there is new data it runs appropriate handlers before returning
//  - returns the state of the gamepad
- (uint8_t)pollCurrentState;

// The handler is run on the main thread whenever a new state is detected.
// This makes it good for detecting combos and codes
//   New states are detected:
//    - when a runloop event happens
//    - when the current state is polled
@property (nonatomic, strong) void (^handler)(uint8_t state);

// Tells you if the gamepad is there or not
@property (nonatomic, readonly) BOOL isConnected;


@end

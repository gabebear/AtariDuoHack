//
//  AtariDuoGamePad.m
//  AtariDuoHack
//
//  Created by Gabe Ghearing on 2/19/14.
//  Copyright (c) 2014 Foolish Code. All rights reserved.
//

#import "AtariDuoGamePad.h"

#define supportedProtocol @"com.discoverybaygames.duo"

static BOOL isGamePadconnected;
static NSMutableDictionary *eventHandlers;
static uint8_t currentState;
static AtariDuoGamePad *masterAtari;
static void (^masterHandler)(int state);
static NSInputStream *inputStream;

@implementation AtariDuoGamePad

- (id)init {
	if (self = [super init]) {
		static dispatch_once_t pred;
		dispatch_once(&pred, ^{
			// initialize stuff the first time
			isGamePadconnected = false;
			masterHandler = ^(int state) {};
			eventHandlers = [NSMutableDictionary dictionary];
			currentState = 0;
			
			// create one master AtariDuoGamePad that will live forever.
			// this will serve as the delegate for the EAAccessory stuff
			dispatch_async(dispatch_get_main_queue(), ^{
				masterAtari = [[AtariDuoGamePad alloc] init];
				
				[[NSNotificationCenter defaultCenter] addObserver:masterAtari
									 selector:@selector(deviceConnect:)
									     name:EAAccessoryDidConnectNotification
									   object:nil];
				
				[[NSNotificationCenter defaultCenter] addObserver:masterAtari
									 selector:@selector(deviceDisconnect:)
									     name:EAAccessoryDidDisconnectNotification
									   object:nil];
				
				[[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications];
				
				[masterAtari useAccessory:nil];
			});
		});
	}
	return self;
}

- (void)dealloc {
	void (^mainThreadBlock)(void) = ^{
		[eventHandlers removeObjectForKey:self];
		[self rebuildMasterHandler];
	};
	if ([NSThread isMainThread]) {
		mainThreadBlock();
	} else {
		dispatch_async(dispatch_get_main_queue(), mainThreadBlock);
	}
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (void (^)(uint8_t))handler {
	void (^theHandler)(uint8_t state) = nil;
	for (AtariDuoGamePad *key in eventHandlers) {
		if (key == self) {
			theHandler = [eventHandlers objectForKey:key];
		}
	}
	return theHandler;
}

- (void)setHandler:(void (^)(uint8_t))gamePadHandler {
	void (^mainThreadBlock)(void) = ^{
		[eventHandlers setObject:[gamePadHandler copy] forKey:self];
		[self rebuildMasterHandler];
	};
	if ([NSThread isMainThread]) {
		mainThreadBlock();
	} else {
		dispatch_async(dispatch_get_main_queue(), mainThreadBlock);
	}
}

- (BOOL)isConnected {
	return isGamePadconnected;
}

- (uint8_t)pollCurrentState {
	if ([inputStream hasBytesAvailable]) {
		[self getBytesAvailableOnStream:inputStream];
	}
	return currentState;
}

- (void)rebuildMasterHandler {
	masterHandler = nil;
	for (AtariDuoGamePad *key in eventHandlers) {
		void (^handler)(int state) = [eventHandlers objectForKey:key];
		if (!masterHandler) {
			masterHandler = handler;
		} else {
			masterHandler = ^(int state) {
				masterHandler(state);
				handler(state);
			};
		}
	}
}

- (void)deviceConnect:(NSNotification *)notification {
	[self useAccessory:[[notification userInfo] objectForKey:EAAccessoryKey]];
}

- (void)useAccessory:(EAAccessory *)accessory {
	if (![[accessory protocolStrings] containsObject:supportedProtocol]) {
		accessory = nil;
	}
	if (!accessory) {
		NSArray *accessories =
		[[EAAccessoryManager sharedAccessoryManager] connectedAccessories];
		for (EAAccessory *obj in accessories) {
			if ([[obj protocolStrings] containsObject:supportedProtocol]) {
				accessory = obj;
			}
		}
	}
	if (accessory) {
		EASession *session =
		[[EASession alloc] initWithAccessory:accessory
					 forProtocol:supportedProtocol];
		
		if (session) {
			inputStream = [session inputStream];
			[inputStream setDelegate:self];
			
			// mainly scheduling on the runloop to make sure we don't leave
			// tons of data around in buffers
			[inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
			                       forMode:NSDefaultRunLoopMode];
			
			[inputStream open];
            [session.outputStream open];
			
			isGamePadconnected = YES;
			masterHandler(0);
		}
	}
}

- (void)deviceDisconnect:(NSNotification *)notification {
	isGamePadconnected = NO;
	currentState = 0;
	masterHandler(0);
}

- (void)getBytesAvailableOnStream:(NSInputStream *)stream {
	// This doesn't deal with cases where 3 bytes of a command aren't all available at
	// once, but that shouldn't happen often(never seen it) and it will re-synch after
	// that happens (possibly losing some input, but recovering).
	
	static uint8_t readBuf[300];
	NSInteger numRead = [stream read:readBuf maxLength:300];
	
	int index = 0;
	while (numRead >= index + 3) {
		uint8_t buf0 = readBuf[index];
		uint8_t buf1 = readBuf[index + 1];
		uint8_t buf2 = readBuf[index + 2];
		
		// The first byte is always 1bit defining whether the data is buttons or direction
		// The state is always repeated on the next 2 bytes in the lower 4bits
		//    (that's what I've seen... log it if anything else happens)
		if ((buf1 == buf2) && (((buf0 & 0xFE) | (buf2 & 0xF0)) == 0)) {
			uint8_t newState;
			if (buf0) {
				newState = (buf2 << 4) | (currentState & 0x0F);
			} else {
				newState = buf2 | (currentState & 0xF0);
			}
			
			currentState = newState;
			masterHandler(currentState);
		} else {
			NSLog(@"weird, hadn't seen this before: %@", [NSData dataWithBytes:readBuf length:numRead]);
			break;
		}
		index += 3;
	}
}

#pragma mark -
#pragma mark NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
	if(stream==inputStream) {
		switch (eventCode) {
			case NSStreamEventHasBytesAvailable:
				[self getBytesAvailableOnStream:inputStream];
				break;
				
			case NSStreamEventErrorOccurred:
				[stream close];
				
			case NSStreamEventHasSpaceAvailable:
			case NSStreamEventNone:
			case NSStreamEventOpenCompleted:
			case NSStreamEventEndEncountered:
				break;
		}
	}
}

@end

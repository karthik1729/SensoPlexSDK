//
//  SPAppDelegate.m
//  SensoPlexDesktop
//
//  Created by Karthik Thirumalasetti on 16/07/14.
//  Copyright (c) 2014 SweetSpotScience. All rights reserved.
//

#import "SPAppDelegate.h"


@interface SPAppDelegate()<SensoPlexDelegate, SensoPlexSensorDataDelegate>{
    // flag to make sure that we delete old sensor data that
    // was serialized when starting new capture sessions
    BOOL deletedOldSerializedSensorData;
}


// show status to the user
- (void) promptUserToTurnOnSensor;
- (void) promptUserToTurnBluetoothOn;

// SensoPlex actions
//-(IBAction) toggleLED:(id)sender;
//-(IBAction) startStreamingData:(id)sender;
//-(IBAction) stopStreamingData:(id)sender;
//-(IBAction) emailStreamedData:(id)sender;
//-(IBAction) getFirmwareVersion:(id)sender;
//-(IBAction) getStatus:(id)sender;

@end

@implementation SPAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    // if we are not connected, then scan for our peripheral to connect to
    [self initializeSensoPlex];
    SensoPlexState state = self.sensoPlex.state;
    if ( state == SensoPlexDisconnected || state == SensoPlexFailedToConnect ) {
        [self.sensoPlex scanForBLEPeripherals];
    } else {
        [self showConnectionState:state];
    }
}

- (void) initializeSensoPlex {
    if( !self.sensoPlex ) {
        SensoPlex *sensoPlex = [[SensoPlex alloc] init];
        
        self.sensoPlex = sensoPlex;
        
        // remove any saved sensor data so that we start from scratch each time
        if ( !deletedOldSerializedSensorData ) {
            [self.sensoPlex deleteAllSerializedSensorData];
            deletedOldSerializedSensorData = YES;
        }
    }
    
    
    self.sensoPlex.delegate = self;
}

-(void)onSensorData:(SensorData *)sensorData{
    
}

-(void)showConnectionState:(SensoPlexState)state{
    
}

-(void)showStatus:(NSString *)status for:(NSTimeInterval)forTime{
    
}

-(void)promptUserToTurnBluetoothOn{
    
}

-(void)promptUserToTurnOnSensor{
    
}

-(BOOL) shouldConnectToSensoPlexPeripheral:(CBPeripheral*)peripheral{
    return YES;
}

@end
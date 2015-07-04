//
//  ViewController.h
//  OTA-d0wn
//
//  Created by Keaton Burleson on 7/2/15.
//  Copyright (c) 2015 Keaton Burleson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController <NSComboBoxDataSource, NSComboBoxDelegate>{
    NSUserDefaults *defaults;
    NSMutableArray *devices;
    NSMutableData *taskData;
    BOOL terminated;

}
@property (weak) IBOutlet NSTextField *firmwareField;
@property (weak) IBOutlet NSButton *browseForFirmware;
@property (weak) IBOutlet NSTextField *ipAddressField;
@property (weak) IBOutlet NSTextField *thanksLabel;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSProgressIndicator *whatAreWeDoing;
@property (weak) IBOutlet NSLevelIndicator *progess;
@property (weak) IBOutlet NSWindow *mainWindow;

@property (weak) IBOutlet NSTextField *toolField;
@property (weak) IBOutlet NSButton *browseForTool;
@property (weak) IBOutlet NSButton *downgradeButton;



@end


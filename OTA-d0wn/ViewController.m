//
//  ViewController.m
//  OTA-d0wn
//
//  Created by Keaton Burleson on 7/2/15.
//  Copyright (c) 2015 Keaton Burleson. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

@synthesize firmwareField, browseForTool, browseForFirmware, toolField,downgradeButton, ipAddressField, whatAreWeDoing, statusLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    defaults = [NSUserDefaults standardUserDefaults];
    devices = [[NSMutableArray alloc]initWithObjects:@"iPad2,1", @"iPhone4,1", nil];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(myMethod:)
                   name:@"NSFileHandleReadCompletionNotification"
                 object:nil];
    taskData = [[NSMutableData alloc]init];
    [ipAddressField setFocusRingType:NSFocusRingTypeNone];
    [firmwareField setFocusRingType:NSFocusRingTypeNone];
    
    if ([defaults objectForKey:@"ip"] != nil) {
        ipAddressField.stringValue = [defaults objectForKey:@"ip"];
    }
    
    if ([defaults objectForKey:@"firmware"] != nil) {
        firmwareField.stringValue = [defaults objectForKey:@"firmware"];
    }
    
    NSString *script = [[[NSBundle mainBundle]resourcePath] stringByAppendingString:@"/movebss.sh"];
    // At this point, we have already checked if script exists and has a shebang
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager isExecutableFileAtPath:script]) {
        NSArray *chmodArguments = [NSArray arrayWithObjects:@"a+x", script, nil];
        NSTask *chmod = [NSTask launchedTaskWithLaunchPath:@"/bin/chmod" arguments:chmodArguments];
        [chmod waitUntilExit];
    }
        
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
-(NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox{
    return devices.count;
}

-(id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)loc{
    return [devices objectAtIndex:loc];
}

-(IBAction)choseDevice:(NSComboBox*)sender{
    [defaults setObject:sender.stringValue forKey:@"device"];
    [defaults synchronize];
}

- (IBAction)downgradeDevice:(id)sender {
    NSTask *task = [[NSTask alloc] init];
 
    [task setCurrentDirectoryPath:[[NSBundle mainBundle]resourcePath]];
    NSString *str=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ipsw"];
    
    [whatAreWeDoing startAnimation:nil];
    [whatAreWeDoing setHidden:false];
    
    
    // [task setCurrentDirectoryPath:[NSString stringWithFormat:@"../..%@/", [defaults objectForKey:@"tool"]]];
    NSLog(@"working dir: %@", [task currentDirectoryPath] );
    //     task.launchPath = [NSString stringWithFormat:@"%@/ipsw", [defaults objectForKey:@"tool"]];
    
    [defaults setObject:ipAddressField.stringValue forKey:@"ip"];
    
    NSString *firmwarePath = [NSString stringWithFormat:@"%@/custom_firmware.ipsw", [[NSBundle mainBundle] resourcePath]];
    [defaults setObject:firmwarePath forKey:@"firmwarePath"];
    
    [task setLaunchPath:str];
    task.arguments  = @[[defaults objectForKey:@"firmware"], firmwarePath, @"-bbupdate"];
    NSLog(@"firmware path: %@", [defaults objectForKey:@"firmware"]);
    NSLog(@"launch: %@", task.launchPath);
    NSLog(@"arguments: %@", task.arguments);
    NSLog(@"firmware path 2: %@", firmwarePath);
    NSPipe * out = [NSPipe pipe];
    [task setStandardOutput:out];
    [defaults synchronize];
    statusLabel.stringValue = @"Making IPSW";
    
    downgradeButton.enabled = NO;
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
          _progess.floatValue = 1;
        
        [task launch];
  
    
        
        NSFileHandle * read = [out fileHandleForReading];
        
        NSData * dataRead = [read readDataToEndOfFile];
        NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
        NSLog(@"output: %@", stringRead);
        if([stringRead containsString:@"error: Could not load IPSW"]){
            self.thanksLabel.stringValue = @"Error: Could not load IPSW";
            downgradeButton.enabled = YES;
            
            
        }else{
     [self fetchBlobs];
        }

   

    });
    


   
}






-(void)fetchBlobs{
    NSTask *task = [[NSTask alloc] init];
    
    
    NSString *str=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"idevicerestore"];
    
       _progess.floatValue = 2;
    
    // [task setCurrentDirectoryPath:[NSString stringWithFormat:@"../..%@/", [defaults objectForKey:@"tool"]]];
    NSLog(@"working dir: %@", [task currentDirectoryPath] );
    //     task.launchPath = [NSString stringWithFormat:@"%@/ipsw", [defaults objectForKey:@"tool"]];
    
    
    statusLabel.stringValue = @"Fetching SHSH blobs";
    [task setLaunchPath:str];
    NSString *firmwarePath = [NSString stringWithFormat:@"%@/custom_firmware.ipsw", [[NSBundle mainBundle] resourcePath]];
    [defaults setObject:firmwarePath forKey:@"firmwarePath"];
    [defaults synchronize];
    
    task.arguments  = @[@"-t", firmwarePath];

    NSPipe * out = [NSPipe pipe];
    [task setStandardOutput:out];
    
  
    downgradeButton.enabled = NO;
    
  dispatch_async(dispatch_get_main_queue(), ^{
        
        
        [task launch];


        

      
        
        
        
    });
    NSFileHandle * read = [out fileHandleForReading];
    
    NSData * dataRead = [read readDataToEndOfFile];
    NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    NSLog(@"output: %@", stringRead);
    
    
    NSRange isRange = [stringRead rangeOfString:@" ERROR: could " options:NSCaseInsensitiveSearch];
    if(isRange.location == 0) {
        self.thanksLabel.stringValue = @"Error: unknown device connected";
        downgradeButton.enabled = YES;
       
    } else {
        NSRange isSpacedRange = [stringRead rangeOfString:@" ERROR: Unable " options:NSCaseInsensitiveSearch];
        if(isSpacedRange.location != NSNotFound) {
            self.thanksLabel.stringValue = @"Error: no device connected";
            downgradeButton.enabled = YES;
            
        }else{
            NSLog(@"making iBSS");
            downgradeButton.enabled = YES;
           
                    [self makeiBSS];
        }
    }

 
}

-(void)makeiBSS{
    NSTask *task = [[NSTask alloc] init];

    


    

    NSLog(@"working dir: %@", [task currentDirectoryPath] );

 
 
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    
    
    if (![fileManager fileExistsAtPath:[[task currentDirectoryPath] stringByAppendingString:@"/custom_firmware.ipsw"]]){
        [fileManager copyItemAtPath:[defaults objectForKey:@"firmwarePath"] toPath:[task currentDirectoryPath] error:nil];
    }
    
    NSString *firmwarePath = [NSString stringWithFormat:@"%@/custom_firmware.ipsw", [[NSBundle mainBundle] resourcePath]];
    NSString *junkPath = [NSString stringWithFormat:@"%@/bss", [[NSBundle mainBundle]resourcePath]];
  
    
    [task setLaunchPath:@"/usr/bin/unzip"];
    task.arguments  = @[firmwarePath, @"-d",  junkPath];
   
    
    NSPipe * out = [NSPipe pipe];
    [task setStandardOutput:out];
    
    statusLabel.stringValue = @"Unzipping Firmware";
    [task setCurrentDirectoryPath:[[NSBundle mainBundle]resourcePath]];
    downgradeButton.enabled = NO;
    
    [task launch];
    _progess.floatValue = 3;
    NSFileHandle * read = [out fileHandleForReading];
    
    NSData * dataRead = [read readDataToEndOfFile];
    NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    NSLog(@"output: %@", stringRead);
    
    
    NSRange isRange = [stringRead rangeOfString:@" error: cannot open infile " options:NSCaseInsensitiveSearch];
    if(isRange.location == 0) {
        self.thanksLabel.stringValue = @"Error: unknown device connected";
        downgradeButton.enabled = YES;
       
    } else {
        NSRange isSpacedRange = [stringRead rangeOfString:@" ERROR: Unable " options:NSCaseInsensitiveSearch];
        if(isSpacedRange.location != NSNotFound) {
            self.thanksLabel.stringValue = @"Error: no device connected";
            downgradeButton.enabled = YES;
           
        }else{
            NSLog(@"making scp");
            downgradeButton.enabled = YES;
              _progess.floatValue = 3;
          
            [self pwniBSS];
        }
    }

    
    
}

-(void)pwniBSS{
    NSTask *task = [[NSTask alloc] init];
    
    
    
    
    [task setCurrentDirectoryPath:[[NSBundle mainBundle]resourcePath]];
    
    NSLog(@"working dir: %@", [task currentDirectoryPath] );
    
    
    NSString *iBSS;
     NSString *junkPath = [NSString stringWithFormat:@"%@/bss/Firmware/dfu/", [[NSBundle mainBundle]resourcePath]];
    
    NSFileManager *fileManager = [NSFileManager new];
    
    for(NSString *item in [fileManager contentsOfDirectoryAtPath:junkPath error:nil]) {
        if ([item containsString:@"iBSS"]) {
            iBSS = item;
        }
    }
    
    


    iBSS = [NSString stringWithFormat:@"%@/bss/Firmware/DFU/%@", [[NSBundle mainBundle]resourcePath], iBSS];
        NSLog(@"iBSS path: %@", iBSS);


    
    NSString *scriptPath = [NSString stringWithFormat:@"%@/movebss.sh", [[NSBundle mainBundle]resourcePath]];
    
    [task setLaunchPath:@"/bin/sh"];
    task.arguments  = @[@"-c", scriptPath];
    
    
    NSPipe * out = [NSPipe pipe];
    [task setStandardOutput:out];
    
    statusLabel.stringValue = @"Making pwned iBSS";

    downgradeButton.enabled = NO;
    
    [task launch];
    
    _progess.floatValue = 4;
    NSFileHandle * read = [out fileHandleForReading];
    
    NSData * dataRead = [read readDataToEndOfFile];
    NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    NSLog(@"output: %@", stringRead);
    
    
    NSRange isRange = [stringRead rangeOfString:@" error: cannot open infile " options:NSCaseInsensitiveSearch];
    if(isRange.location == 0) {
        self.thanksLabel.stringValue = @"Error: unknown device connected";
        downgradeButton.enabled = YES;
        
    } else {
        NSRange isSpacedRange = [stringRead rangeOfString:@" ERROR: Unable " options:NSCaseInsensitiveSearch];
        if(isSpacedRange.location != NSNotFound) {
            self.thanksLabel.stringValue = @"Error: no device connected";
            downgradeButton.enabled = YES;
            
        }else{
            NSLog(@"making scp");
            downgradeButton.enabled = YES;
            _progess.floatValue = 3;
           [self cleanup];
          
        }
    }
    
    
}
-(void)cleanup{
    NSTask *task = [[NSTask alloc] init];
    

   NSString *junkPath = [NSString stringWithFormat:@"%@/bss/", [[NSBundle mainBundle]resourcePath]];
  
 
    
    [task setLaunchPath:@"/bin/rm"];
    task.arguments  = @[@"-r", junkPath];
    
    
    NSPipe * out = [NSPipe pipe];
    [task setStandardOutput:out];
    
    statusLabel.stringValue = @"Tidying up";
    [task setCurrentDirectoryPath:[[NSBundle mainBundle]resourcePath]];
    downgradeButton.enabled = NO;
    
    [task launch];
    _progess.floatValue = 3;
    NSFileHandle * read = [out fileHandleForReading];
    
    NSData * dataRead = [read readDataToEndOfFile];
    NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    NSLog(@"output: %@", stringRead);
    
    
    NSRange isRange = [stringRead rangeOfString:@" error: cannot open infile " options:NSCaseInsensitiveSearch];
    if(isRange.location == 0) {
        self.thanksLabel.stringValue = @"Error: unknown device connected";
        downgradeButton.enabled = YES;
        
    } else {
        NSRange isSpacedRange = [stringRead rangeOfString:@" ERROR: Unable " options:NSCaseInsensitiveSearch];
        if(isSpacedRange.location != NSNotFound) {
            self.thanksLabel.stringValue = @"Error: no device connected";
            downgradeButton.enabled = YES;
            
        }else{
            NSLog(@"making scp");
            downgradeButton.enabled = YES;
            _progess.floatValue = 5;
            [whatAreWeDoing stopAnimation:nil];
            whatAreWeDoing.hidden = YES;
            statusLabel.stringValue = @"Done";
           
            
            
        }
    }

}




-(IBAction)openFileBrowser:(id)sender{

    
        // Loop counter.
        int i;
    
        // Create a File Open Dialog class.
        NSOpenPanel* openDlg = [NSOpenPanel openPanel];
        
        // Set array of file types
        NSArray *fileTypesArray;
        fileTypesArray = [NSArray arrayWithObjects:@"ipsw", @"ispw", nil];
        
        // Enable options in the dialog.
        [openDlg setCanChooseFiles:YES];
        [openDlg setAllowedFileTypes:fileTypesArray];
        [openDlg setAllowsMultipleSelection:false];
        
        // Display the dialog box.  If the OK pressed,
        // process the files.
        if ( [openDlg runModal] == NSModalResponseOK ) {
            
            // Gets list of all files selected
            NSArray *files = [openDlg URLs];
            
            // Loop through the files and process them.
            for( i = 0; i < [files count]; i++ ) {
                
                // Do something with the filename.
                NSLog(@"File path: %@", [[files objectAtIndex:i] path]);
                firmwareField.stringValue = [[files objectAtIndex:i]path];
                NSString * firmwarePath = [firmwareField.stringValue stringByReplacingOccurrencesOfString:@" " withString:@" "];
                
                [defaults setObject:firmwarePath forKey:@"firmware"];
                [defaults synchronize];
                
                
            }
            
        }
        
    
}



- (void)myMethod:(NSNotification *)note
{
    // Get output string
    NSData *data = [[note userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // Do something with string
    NSLog(@"woot: %@", string);
    // Ask for another notification

    

}






@end

//
//  MoLogger.m
//
//  Created by Jeremy Millers on 07/17/13.
//  Copyright (c) 2013 moBiddy, Inc. All rights reserved.
//

#import "MoLogger.h"
#import "MoConstants.h"


#ifdef __APPLE__
#ifdef TARGET_OS_MAC
#import <IOKit/IOKitLib.h>
#import <sys/sysctl.h>

@interface VarSystemInfo:NSObject
@property (readwrite, strong, nonatomic) NSString *sysName;
@property (readwrite, strong, nonatomic) NSString *sysUserName;
@property (readwrite, strong, nonatomic) NSString *sysFullUserName;
@property (readwrite, strong, nonatomic) NSString *sysOSName;
@property (readwrite, strong, nonatomic) NSString *sysOSVersion;
@property (readwrite, strong, nonatomic) NSString *sysPhysicalMemory;
@property (readwrite, strong, nonatomic) NSString *sysSerialNumber;
@property (readwrite, strong, nonatomic) NSString *sysUUID;
@property (readwrite, strong, nonatomic) NSString *sysModelID;
@property (readwrite, strong, nonatomic) NSString *sysModelName;
@property (readwrite, strong, nonatomic) NSString *sysProcessorName;
@property (readwrite, strong, nonatomic) NSString *sysProcessorSpeed;
@property (readwrite, strong, nonatomic) NSNumber *sysProcessorCount;
@property (readonly,  strong, nonatomic) NSString *getOSVersionInfo;

- (NSString *) _strIORegistryEntry:(NSString *)registryKey;
- (NSString *) _strControlEntry:(NSString *)ctlKey;
- (NSNumber *) _numControlEntry:(NSString *)ctlKey;
- (NSString *) _modelNameFromID:(NSString *)modelID;
- (NSString *) _parseBrandName:(NSString *)brandName;
@end

static NSString* const kVarSysInfoVersionFormat  = @"%@.%@.%@ (%@)";
static NSString* const kVarSysInfoPlatformExpert = @"IOPlatformExpertDevice";

static NSString* const kVarSysInfoKeyOSVersion = @"kern.osrelease";
static NSString* const kVarSysInfoKeyOSBuild   = @"kern.osversion";
static NSString* const kVarSysInfoKeyModel     = @"hw.model";
static NSString* const kVarSysInfoKeyCPUCount  = @"hw.physicalcpu";
static NSString* const kVarSysInfoKeyCPUFreq   = @"hw.cpufrequency";
static NSString* const kVarSysInfoKeyCPUBrand  = @"machdep.cpu.brand_string";

static NSString* const kVarSysInfoMachineNames       = @"MachineNames";
static NSString* const kVarSysInfoMachineiMac        = @"iMac";
static NSString* const kVarSysInfoMachineMacmini     = @"Mac mini";
static NSString* const kVarSysInfoMachineMacBookAir  = @"MacBook Air";
static NSString* const kVarSysInfoMachineMacBookPro  = @"MacBook Pro";
static NSString* const kVarSysInfoMachineMacPro      = @"Mac Pro";

#pragma mark - Implementation:
#pragma mark -

@implementation VarSystemInfo

@synthesize sysName, sysUserName, sysFullUserName;
@synthesize sysOSName, sysOSVersion;
@synthesize sysPhysicalMemory;
@synthesize sysSerialNumber, sysUUID;
@synthesize sysModelID, sysModelName;
@synthesize sysProcessorName, sysProcessorSpeed, sysProcessorCount;

#pragma mark - Helper Methods:

- (NSString *) _strIORegistryEntry:(NSString *)registryKey {
    
    NSString *retString;
    
    io_service_t service =
    IOServiceGetMatchingService( kIOMasterPortDefault,
                                IOServiceMatching([kVarSysInfoPlatformExpert UTF8String]) );
    if ( service ) {
        
        CFTypeRef cfRefString =
        IORegistryEntryCreateCFProperty( service,
                                        (__bridge CFStringRef)registryKey,
                                        kCFAllocatorDefault, kNilOptions );
        if ( cfRefString ) {
            
            retString = [NSString stringWithString:(__bridge NSString *)cfRefString];
            CFRelease(cfRefString);
            
        } IOObjectRelease( service );
        
    } return retString;
}

- (NSString *) _strControlEntry:(NSString *)ctlKey {
    
    size_t size = 0;
    if ( sysctlbyname([ctlKey UTF8String], NULL, &size, NULL, 0) == -1 ) return nil;
    
    char *machine = calloc( 1, size );
    
    sysctlbyname([ctlKey UTF8String], machine, &size, NULL, 0);
    NSString *ctlValue = [NSString stringWithCString:machine encoding:[NSString defaultCStringEncoding]];
    
    free(machine); return ctlValue;
}

- (NSNumber *) _numControlEntry:(NSString *)ctlKey {
    
    size_t size = sizeof( uint64_t ); uint64_t ctlValue = 0;
    if ( sysctlbyname([ctlKey UTF8String], &ctlValue, &size, NULL, 0) == -1 ) return nil;
    return [NSNumber numberWithUnsignedLongLong:ctlValue];
}

- (NSString *) _modelNameFromID:(NSString *)modelID {
    
    /*!
     * @discussion Maintain Machine Names plist from the following site
     * @abstract ref: http://www.everymac.com/systems/by_capability/mac-specs-by-machine-model-machine-id.html
     *
     * @discussion Also info found in SPMachineTypes.plist @ /System/Library/PrivateFrameworks/...
     *             ...AppleSystemInfo.framework/Versions/A/Resources
     *             Information here is private and can not be linked into the code.
     */
    
    NSDictionary *modelDict = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:kVarSysInfoMachineNames withExtension:@"plist"]];
    NSString *modelName = [modelDict objectForKey:modelID];
    
    if ( !modelName ) {
        
        if ( [modelID.lowercaseString hasPrefix:kVarSysInfoMachineiMac.lowercaseString] ) return kVarSysInfoMachineiMac;
        else if ( [modelID.lowercaseString hasPrefix:kVarSysInfoMachineMacmini] )    return kVarSysInfoMachineMacmini;
        else if ( [modelID.lowercaseString hasPrefix:kVarSysInfoMachineMacBookAir] ) return kVarSysInfoMachineMacBookAir;
        else if ( [modelID.lowercaseString hasPrefix:kVarSysInfoMachineMacBookPro] ) return kVarSysInfoMachineMacBookPro;
        else if ( [modelID.lowercaseString hasPrefix:kVarSysInfoMachineMacPro] )     return kVarSysInfoMachineMacPro;
        else return modelID;
    } return modelName;
}

- (NSString *) _parseBrandName:(NSString *)brandName {
    
    if ( !brandName ) return nil;
    
    NSMutableArray *newWords = [NSMutableArray array];
    NSString *strCopyRight = @"r", *strTradeMark = @"tm", *strCPU = @"CPU";
    
    NSArray *words = [brandName componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
    
    for ( NSString *word in words ) {
        
        if ( [word isEqualToString:strCPU] )       break;
        if ( [word isEqualToString:@""] )          continue;
        if ( [word.lowercaseString isEqualToString:strCopyRight] ) continue;
        if ( [word.lowercaseString isEqualToString:strTradeMark] ) continue;
        
        if ( [word length] > 0 ) {
            
            NSString *firstChar = [word substringToIndex:1];
            if ( NSNotFound != [firstChar rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location ) continue;
            
            [newWords addObject:word];
            
        } } return [newWords componentsJoinedByString:@" "];
}

- (NSString *) getOSVersionInfo {
    
    NSString *darwinVer = [self _strControlEntry:kVarSysInfoKeyOSVersion];
    NSString *buildNo = [self _strControlEntry:kVarSysInfoKeyOSBuild];
    if ( !darwinVer || !buildNo ) return nil;
    
    NSString *majorVer = @"10", *minorVer = @"x", *bugFix = @"x";
    NSArray *darwinChunks = [darwinVer componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    
    if ( [darwinChunks count] > 0 ) {
        
        NSInteger firstChunk = [(NSString *)[darwinChunks objectAtIndex:0] integerValue];
        minorVer = [NSString stringWithFormat:@"%ld", (firstChunk - 4)];
        bugFix = [darwinChunks objectAtIndex:1];
        return [NSString stringWithFormat:kVarSysInfoVersionFormat, majorVer, minorVer, bugFix, buildNo];
        
    } return nil;
}

#pragma mark - Initalization:

- (void) setupSystemInformation {
    NSProcessInfo *pi = [NSProcessInfo processInfo];
    self.sysName = [[NSHost currentHost] localizedName];
    self.sysUserName = NSUserName();
    self.sysFullUserName = NSFullUserName();
    self.sysOSName = pi.operatingSystemName;
    self.sysOSVersion = self.getOSVersionInfo;
    self.sysPhysicalMemory = [[NSNumber numberWithUnsignedLongLong:pi.physicalMemory] description];
    self.sysSerialNumber = [self _strIORegistryEntry:(__bridge NSString *)CFSTR(kIOPlatformSerialNumberKey)];
    self.sysUUID = [self _strIORegistryEntry:(__bridge NSString *)CFSTR(kIOPlatformUUIDKey)];
    self.sysModelID = [self _strControlEntry:kVarSysInfoKeyModel];
    self.sysModelName = [self _modelNameFromID:self.sysModelID];
    self.sysProcessorName = [self _parseBrandName:[self _strControlEntry:kVarSysInfoKeyCPUBrand]];
    self.sysProcessorSpeed = [[self _numControlEntry:kVarSysInfoKeyCPUFreq] description];
    self.sysProcessorCount = [self _numControlEntry:kVarSysInfoKeyCPUCount];
}

- (id) init {
    
    if ( (self = [super init]) ) {
        
        [self setupSystemInformation];
        
    } return self;
}

@end
#endif
#endif


// max file size before clipping
#define MAX_LOG_FILE_SIZE 1024000

// This is a singleton class, see below
static MoLogger* sharedLogger = nil;

// we cache whether we should log all messages or just errors
static BOOL enableMessageLogging = YES;

@interface MoLogger()

@property (strong, nonatomic, retain) NSRecursiveLock *lock;

@end

#pragma mark -
#pragma mark Logging

// option to redefine error logging
void LogError ( NSString *format, ... )
{
    @try {
        va_list args;
        va_start(args, format);
        NSString *formattedContent = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        [MoLogger logError:formattedContent];
    
        NSLog(@"%@", formattedContent);
    }
    @catch (NSException *exception) {
        NSLog(@"*** ERROR trying to log error: %@", exception.description);
    }
}

// option to redefine message logging
void Log ( NSString *format, ... ) {

    @try {
        va_list args;
        va_start(args, format);
        
        NSString *formattedContent = [[NSString alloc] initWithFormat:format arguments:args];
        [MoLogger log:formattedContent];
        
#ifdef _LOG_TO_CONSOLE
        if ( formattedContent )
            NSLog(@"%@", formattedContent);
#endif
        
        va_end(args);
    }
    @catch (NSException *exception) {
        NSLog(@"*** ERROR trying to log message: %@", exception.description);
    }
}

@implementation MoLogger

@synthesize fileHandle;
@synthesize dateFormatter;

- (id) init {
    if ( self = [super init] ) {
        self.lock = [[NSRecursiveLock alloc] init];
    }
    
    return self;
}

+ (void) logError:(NSString *) error {
    MoLogger *logger = [MoLogger logger];
    @try {
        // prepend error and log the content
        NSString *content = [NSString stringWithFormat: @"ERROR: %@", error];
        [logger log:content];
    } @catch (NSException *exception) {
        NSLog(@"Error trying to LogMessage for MoLogger  %@", exception);
    }
}

+ (void) log:(NSString *) msg  {
    MoLogger *logger = [MoLogger logger];
    @try {
        if ( enableMessageLogging ) {
            
            // log the content
            NSString *content = msg; //[[NSString alloc] initWithFormat:format arguments:args];
            //NSString *content = [NSString stringWithFormat:format, args];
            [logger log:content];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Error trying to LogMessage for MoLogger  %@", exception);
    }
}

-(void) log:(NSString*)content {

    BOOL locked = NO;
    @try {
        
        [self.lock lock];
        locked = YES;

        // open the file handle if needed (if this is our first)
        [self openLogFileIfNeeded];
        
        // prepend the date/time and append a newline
        if ( !dateFormatter ) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss:SSS";
            self.dateFormatter = formatter;
        }
        
        //append text to file (you'll probably want to add a newline every write)
        NSDate *date = [NSDate date];
        NSString *timestamp = [dateFormatter stringFromDate:date];
        NSString *contentToWrite = [NSString stringWithFormat:@"%@ %@\n",
                                    timestamp, content];
        [fileHandle writeData:[contentToWrite dataUsingEncoding:NSUTF8StringEncoding]];
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        if ( locked )
            [self.lock unlock];
    }
}

- (void) openLogFileIfNeeded {
    if ( !fileHandle ) {
        
        //Get the file path
        NSString *fileName = [self logFileLocation];
        
        //create file if it doesn't exist
        if(![[NSFileManager defaultManager] fileExistsAtPath:fileName])
            [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
        
        //append text to file
        NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
        unsigned long long fileSize = [file seekToEndOfFile];
        
        // clear the file if it gets too big
        if ( fileSize > [self maxFileSize] ) {
            [file truncateFileAtOffset:0];
        }
        
        self.fileHandle = file;
        
        [self log:@"\n\n********* NEW LOG INSTANCE **********\n"];
        
        // add the app version to this, as well as other OS information
    #ifdef __APPLE__
        #ifdef TARGET_OS_MAC
        VarSystemInfo *sysInfo = [VarSystemInfo new];
        NSString *deviceInfo = [NSString stringWithFormat:@"%@ - OS: %@", sysInfo.sysModelName, sysInfo.sysOSVersion];
        Log(deviceInfo);
        NSString *appInfo = [NSString stringWithFormat:@"App Version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
        Log(appInfo);
        #elif TARGET_OS_IPHONE
        UIDevice *device = [UIDevice currentDevice];
        NSString *deviceInfo = [NSString stringWithFormat:@"%@ - OS: %@", device.model, device.systemVersion];
        Log(deviceInfo);
        NSString *appInfo = [NSString stringWithFormat:@"App Version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
        Log(appInfo);
        #endif
    #endif
        
    }
}

// enable / disable logging
- (void) enableLogging:(BOOL)enable {
    enableMessageLogging = enable;
}

// close the log file
- (void) closeLogFile {
    [fileHandle closeFile];
    self.fileHandle = nil;
}

// get the log file's filename/path
- (NSString*) logFileLocation {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"log.rtf"];
    return fileName;
}

// return the maximum file size before having to clear the log file
- (SInt32) maxFileSize {
    return MAX_LOG_FILE_SIZE;
}

#pragma mark -
#pragma mark Singleton Object Methods

+(MoLogger *)logger {
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedLogger = [[MoLogger alloc] init];
    });
    return sharedLogger;
}



@end

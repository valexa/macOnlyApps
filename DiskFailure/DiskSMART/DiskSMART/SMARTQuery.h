#import <Cocoa/Cocoa.h>

// won't be able to use keys with embedded spaces for KVC and bindings
#define kWindowSMARTsModelKeyString							@"model"
#define kWindowSMARTsFirmwareKeyString						@"firmware"
#define kWindowSMARTsSerialNumberKeyString					@"serialNumber"
#define kWindowSMARTsSMARTSupportKeyString					@"SMARTSupported"
#define kWindowSMARTsWriteCacheSupportKeyString				@"writeCacheSupported"
#define kWindowSMARTsPMSupportKeyString						@"powerManagementSupported"
#define kWindowSMARTsCFSupportKeyString						@"compactFlashSupported"
#define kWindowSMARTsAPMSupportKeyString					@"advancedPowerManagementSupported"
#define kWindowSMARTs48BitAddressingSupportKeyString		@"lba48Supported"
#define kWindowSMARTsFlushCacheCommandSupportKeyString		@"flushCacheSupported"
#define kWindowSMARTsFlushCacheExtCommandSupportKeyString	@"flushCacheExtSupported"
#define kWindowSMARTsQueueDepthKeyString					@"queueDepth"
#define kWindowSMARTsNCQSupportKeyString					@"NCQSupported"
#define kWindowSMARTsDeviceInitiatedPMKeyString				@"deviceCanInitiatePHYPowerManagement"
#define kWindowSMARTsHostInitiatedPMKeyString				@"deviceSupportsHostInitiatedPHYPowerManagement"
#define kWindowSMARTsInterfaceSpeedKeyString				@"interfaceSpeed"
#define kWindowSMARTsDeviceOkKeyString						@"deviceOK"

#define kWindowSMARTsDeviceMaxTempKeyString					@"MaxTemp"
#define kWindowSMARTsDeviceLifetimeMaxTempKeyString			@"LifetimeMaxTemp"

#define kWindowSMARTsTempKeyString                          @"Temp"
#define kWindowSMARTsStartStopCountKeyString                @"StartStopCount"
#define kWindowSMARTsReallocatedSectorsCountKeyString       @"ReallocatedSectorsCount"
#define kWindowSMARTsLoadCycleCountKeyString                @"LoadCycleCount"


// The following attributes are optionally supported and is generally considered
// to be vendor-specific, although it appears that the majority of vendors
// do implement them <http://en.wikipedia.org/wiki/S.M.A.R.T.>

#define kWindowSMARTsTempAttribute                          0xC2
#define kWindowSMARTsStartStopCountAttribute                0x04
#define kWindowSMARTsReallocatedSectorsCountAttribute       0x05
#define kWindowSMARTsLoadCycleCountAttribute				0xC1


@interface SMARTQuery : NSObject {

}

+ (NSDictionary*) getSMARTData:(io_service_t) service;

@end

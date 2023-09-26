#import "SMARTQuery.h"

#include <ctype.h>
#include <stdio.h>
#include <sys/param.h>
#include <sys/time.h>
#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/mach_init.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOReturn.h>
#include <IOKit/storage/ata/ATASMARTLib.h>
#include <IOKit/storage/IOStorageDeviceCharacteristics.h>
#include <CoreFoundation/CoreFoundation.h>

#define kATADefaultSectorSize                             512

@implementation SMARTQuery

#if defined(__BIG_ENDIAN__)
#define		SwapASCIIHostToBig(x,y)
#elif defined(__LITTLE_ENDIAN__)
#define		SwapASCIIHostToBig(x,y)				SwapASCIIString( ( UInt16 * ) x,y)
#else
#error Unknown endianness.
#endif

// This constant comes from the SMART specification.  Only 30 values are allowed in any of the structures.
#define kSMARTAttributeCount	30


typedef struct IOATASmartAttribute
{
    UInt8 			attributeId;
    UInt16			flag;  
    UInt8 			current;
    UInt8 			worst;
    UInt8 			rawvalue[6];
    UInt8 			reserv;
}  __attribute__ ((packed)) IOATASmartAttribute;

typedef struct IOATASmartVendorSpecificData
{
    UInt16 					revisonNumber;
    IOATASmartAttribute		vendorAttributes [kSMARTAttributeCount];
} __attribute__ ((packed)) IOATASmartVendorSpecificData;

/* Vendor attribute of SMART Threshold */
typedef struct IOATASmartThresholdAttribute
{
    UInt8 			attributeId;
    UInt8 			ThresholdValue;
    UInt8 			Reserved[10];
} __attribute__ ((packed)) IOATASmartThresholdAttribute;

typedef struct IOATASmartVendorSpecificDataThresholds
{
    UInt16							revisonNumber;
    IOATASmartThresholdAttribute 	ThresholdEntries [kSMARTAttributeCount];
} __attribute__ ((packed)) IOATASmartVendorSpecificDataThresholds;


void SwapASCIIString(UInt16 *buffer, UInt16 length)
{
	int	index;
	
	for ( index = 0; index < length / 2; index ++ ) {
		buffer[index] = OSSwapInt16 ( buffer[index] );
	}	
}


int VerifyIdentifyData(UInt16 *buffer)
{
	UInt8		checkSum		= -1;
	UInt32		index			= 0;
	UInt8 *		ptr				= ( UInt8 * ) buffer;
	
	require_string(((buffer[255] & 0x00FF) == kChecksumValidCookie), ErrorExit, "WARNING: Identify data checksum cookie not found");

	checkSum = 0;
		
	for (index = 0; index < 512; index++)
		checkSum += ptr[index];
	
ErrorExit:
	return checkSum;
}


+ (BOOL) getMandatoryData: ( IOATASMARTInterface **) smartInterface withResultsDict:(NSMutableDictionary *) ret
{
	IOReturn	error				= kIOReturnSuccess;
	UInt8 *		buffer				= NULL;
	UInt32		length				= kATADefaultSectorSize;
	
	UInt16 *	words				= NULL;
	int			checksum			= 0;
	
	BOOL		isSMARTSupported	= NO;
	
	buffer = (UInt8 *) malloc(kATADefaultSectorSize);
	require_string((buffer != NULL), ErrorExit, "malloc(kATADefaultSectorSize) failed");
	
	bzero(buffer, kATADefaultSectorSize);
	
	error = (*smartInterface)->GetATAIdentifyData(	smartInterface,
													buffer,
													kATADefaultSectorSize,
													&length );
	
	require_string((error == kIOReturnSuccess), ErrorExit, "GetATAIdentifyData failed");

	checksum = VerifyIdentifyData(( UInt16 * ) buffer);
	require_string((checksum == 0), ErrorExit, "Identify data verified. Checksum is NOT correct");
	
	// Terminate the strings with 0's
	// This changes the identify data, so we MUST do this part last.
	buffer[94] = 0;
	buffer[40] = 0;
	
	// Model number runs from byte 54 to 93 inclusive - byte 94 is set to 
	// zero to terminate that string.
	SwapASCIIHostToBig (&buffer[54], 40);
	[ret setObject:[NSString stringWithCString:(char *)&buffer[54] encoding:NSUTF8StringEncoding] forKey:kWindowSMARTsModelKeyString];
	
	// Now that we have made a deep copy of the model string, poke a 0 into byte 54 
	// in order to terminate the fw-vers string which runs from bytes 46 to 53 inclusive.
	buffer[54] = 0;
	
	SwapASCIIHostToBig (&buffer[46], 8);
	[ret setObject:[NSString stringWithCString:(char *)&buffer[46] encoding:NSUTF8StringEncoding] forKey:kWindowSMARTsFirmwareKeyString];

	SwapASCIIHostToBig (&buffer[20], 20);
	[ret setObject:[NSString stringWithCString:(char *)&buffer[20] encoding:NSUTF8StringEncoding] forKey:kWindowSMARTsSerialNumberKeyString];
	
	words = (UInt16 *) buffer;
	
	isSMARTSupported = words[kATAIdentifyCommandSetSupported] & kATASupportsSMARTMask;
		
	[ret setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsSMARTMask] forKey:kWindowSMARTsSMARTSupportKeyString];
	[ret setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsWriteCacheMask] forKey:kWindowSMARTsWriteCacheSupportKeyString];
	[ret setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsPowerManagementMask] forKey:kWindowSMARTsPMSupportKeyString];
	[ret setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsCompactFlashMask] forKey:kWindowSMARTsCFSupportKeyString];
	[ret setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsAdvancedPowerManagementMask] forKey:kWindowSMARTsAPMSupportKeyString];
	[ret setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupports48BitAddressingMask] forKey:kWindowSMARTs48BitAddressingSupportKeyString];
	[ret setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsFlushCacheMask] forKey:kWindowSMARTsFlushCacheCommandSupportKeyString];
	[ret setObject:[NSNumber numberWithBool:words[kATAIdentifyCommandSetSupported] & kATASupportsFlushCacheExtendedMask] forKey:kWindowSMARTsFlushCacheExtCommandSupportKeyString];
	[ret setObject:[NSNumber numberWithInt:(words[kATAIdentifyQueueDepth] & 0x001F) + 1] forKey:kWindowSMARTsQueueDepthKeyString];
		
	if ((words[76] != 0) && (words[76] != 0xFFFF)) {
		[ret setObject:[NSNumber numberWithBool:words[76] & (1 << 8)] forKey:kWindowSMARTsNCQSupportKeyString];
		[ret setObject:[NSNumber numberWithBool:words[78] & (1 << 3)] forKey:kWindowSMARTsDeviceInitiatedPMKeyString];
		[ret setObject:[NSNumber numberWithBool:words[76] & (1 << 9)] forKey:kWindowSMARTsHostInitiatedPMKeyString];
		[ret setObject:[NSNumber numberWithFloat:( words[76] & (1 << 2) ) ? 3.0 : 1.5] forKey:kWindowSMARTsInterfaceSpeedKeyString];
	}
		
	if (((words[kATAIdentifyCommandSetSupported2] & (1 << 1)) == 0) && ((words[76] & (1 << 8)) == 0)) {
		require_string((words[kATAIdentifyQueueDepth] != 0), ErrorExit, "\n WARNING! Found inconsistency with queue depth!\n\n");
	}
	
ErrorExit:
	if (buffer)
		free(buffer);

	return isSMARTSupported;
}

+(void) getOptionalData:(IOATASMARTInterface **) smartInterface withResultsDict:(NSMutableDictionary *) ret attributes:(NSDictionary*)attributes
{
	
	IOReturn									error				= kIOReturnSuccess;
	Boolean										conditionExceeded	= false;
	ATASMARTData								smartData;
	IOATASmartVendorSpecificData				smartDataVendorSpecifics;
	ATASMARTDataThresholds						smartThresholds;
	IOATASmartVendorSpecificDataThresholds		smartThresholdVendorSpecifics;
	ATASMARTLogDirectory						smartLogDirectory;

	bzero(&smartData, sizeof(smartData));
	bzero(&smartDataVendorSpecifics, sizeof(smartDataVendorSpecifics));
	bzero(&smartThresholds, sizeof(smartThresholds));
	bzero(&smartThresholdVendorSpecifics, sizeof(smartThresholdVendorSpecifics));
	bzero(&smartLogDirectory, sizeof(smartLogDirectory));

	// Default the results for safety.
	[ret setObject:[NSNumber numberWithBool:NO] forKey:kWindowSMARTsDeviceOkKeyString];


	// Start by enabling S.M.A.R.T. reporting for this disk.
	error = (*smartInterface)->SMARTEnableDisableOperations(smartInterface, true);
	require_string((error == kIOReturnSuccess), ErrorExit, "SMARTEnableDisableOperations failed");
	
	error = (*smartInterface)->SMARTEnableDisableAutosave(smartInterface, true);
	require_string((error == kIOReturnSuccess), ErrorExit, "SMARTEnableDisableAutosave failed");


	// In most cases, this value will be all that you require.  As most of the
	// S.M.A.R.T reporting attributes are vendor-specific, the only part you can
	// always count on being implemented and accurate is the overall T.E.C
	// (Threshold Exceeded Condition) status report.
	error = (*smartInterface)->SMARTReturnStatus(smartInterface, &conditionExceeded);
	require_string((error == kIOReturnSuccess), ErrorExit, "SMARTReturnStatus failed" );
	
	if (!conditionExceeded)	[ret setObject:[NSNumber numberWithBool:YES] forKey:kWindowSMARTsDeviceOkKeyString];

	// NOTE:
	// The rest of the diagnostics gathering involves using portions of the API that is considered
	// optional for a drive vendor to implement.  Most vendors now do, but be warned not to rely
	// on it.  In particular, the attribute codes are usually considered vendor specific and
	// proprietary, although some codes (ie. drive temperature) are almost always present.


	// Ask the device to start collecting S.M.A.R.T. data immediately.  We are not asking
	// for an extended test to be performed at this point
	error = (*smartInterface)->SMARTExecuteOffLineImmediate (smartInterface, false);
	if (error != kIOReturnSuccess)
		printf("SMARTExecuteOffLineImmediate failed: %s(%x)\n", mach_error_string(error), error);
    
    
    for (NSString *key in attributes) {
        int attribute = [[attributes objectForKey:key] intValue];

        // Next, a demonstration of how to extract the raw S.M.A.R.T. data attributes.
        // A drive can report up to 30 of these, but all are optional and varry by vendor.
        error = (*smartInterface)->SMARTReadData(smartInterface, &smartData);
        if (error != kIOReturnSuccess) {
            printf("SMARTReadData failed: %s(%x)\n", mach_error_string(error), error);
        } else {
            error = (*smartInterface)->SMARTValidateReadData(smartInterface, &smartData);
            if (error != kIOReturnSuccess) {
                printf("SMARTValidateReadData failed for attributes: %s(%x)\n", mach_error_string(error), error);
            } else {
                smartDataVendorSpecifics = *((IOATASmartVendorSpecificData *)&(smartData.vendorSpecific1));
                
                int currentAttributeIndex = 0;
                for (currentAttributeIndex = 0; currentAttributeIndex < kSMARTAttributeCount; currentAttributeIndex++) {
                    IOATASmartAttribute currentAttribute = smartDataVendorSpecifics.vendorAttributes[currentAttributeIndex];
                    
                    // Grab and use the drive temperature if it's present.  Don't freak out if it isn't, as
                    // this is an optional behaviour although most drives do support this.
                    if (currentAttribute.attributeId == attribute) {
                        UInt8 temp = currentAttribute.rawvalue[0];
                        [ret setObject:[NSNumber numberWithUnsignedInt:temp] forKey:key];  
                        break;
                    }
                }
            }
        }
        
        // Now, grab the corresponding threshold value(s) for the data attributes we have.  A
        // threshold of zero indicates that this is not used as part of the T.E.C. calculations.
        error = (*smartInterface)->SMARTReadDataThresholds(smartInterface, &smartThresholds);
        if (error != kIOReturnSuccess) {
            printf("SMARTReadDataThresholds failed for threshold data: %s(%x)\n", mach_error_string(error), error);
        } else {
            // The validation scheme used by S.M.A.R.T. is a checksum byte added to the end to make
            // the entire block add to 0x00.  This validation works for both the attribute data and
            // the threshold data, although the prototype for SMARTValidateReadData takes a pointer
            // to a ATASMARTData structure.  As a result, we can safely call it here with a typecast.
            error = (*smartInterface)->SMARTValidateReadData(smartInterface, (ATASMARTData *)&smartThresholds);
            if (error != kIOReturnSuccess) {
                printf("SMARTValidateReadData failed for threshold data: %s(%x)\n", mach_error_string(error), error);
            } else {
                smartThresholdVendorSpecifics = *((IOATASmartVendorSpecificDataThresholds *)&(smartThresholds.vendorSpecific1));
                
                int currentAttributeIndex = 0;
                for (currentAttributeIndex = 0; currentAttributeIndex < kSMARTAttributeCount; currentAttributeIndex++) {
                    IOATASmartThresholdAttribute currentAttribute = smartThresholdVendorSpecifics.ThresholdEntries[currentAttributeIndex];
                    
                    // Grab and use the drive temperature if it's present.  Don't freak out if it isn't, as
                    // this is an optional behaviour although most drives do support this
                    if (currentAttribute.attributeId == attribute) {
                        UInt8 temp = currentAttribute.ThresholdValue;
                        NSString *treshold = [NSString stringWithFormat:@"%@Treshold",key];
                        [ret setObject:[NSNumber numberWithUnsignedInt:temp] forKey:treshold];
                    }
                }
            }
        }        
        
    }


ErrorExit:
	// Now that we're done, shut down the S.M.A.R.T.  If we don't, storage takes a big performance hit.
	// We should be able to ignore any error conditions here safely
	(*smartInterface)->SMARTEnableDisableAutosave(smartInterface, false);
	(*smartInterface)->SMARTEnableDisableOperations(smartInterface, false);
}


+ (NSDictionary*) getSMARTData:(io_service_t) service
{
			
	IOCFPlugInInterface **		cfPlugInInterface	= NULL;
	IOATASMARTInterface **		smartInterface		= NULL;
	SInt32						score				= 0;
	HRESULT						herr				= S_OK;
	IOReturn					err					= kIOReturnSuccess;
	NSMutableDictionary *		ret	= [NSMutableDictionary dictionaryWithCapacity:1];
		
	err = IOCreatePlugInInterfaceForService (	service,
												kIOATASMARTUserClientTypeID,
												kIOCFPlugInInterfaceID,
												&cfPlugInInterface,
												&score );
    
    if (err != kIOReturnSuccess ) {
        NSLog(@"IOCreatePlugInInterfaceForService failed with error %i",err);
        return nil;
    }
	
	herr = ( *cfPlugInInterface )->QueryInterface (
										cfPlugInInterface,
										CFUUIDGetUUIDBytes ( kIOATASMARTInterfaceID ),
										( LPVOID ) &smartInterface );
	
    if (herr != S_OK) {
        NSLog(@"QueryInterface failed with error %i",(int)herr);
        IODestroyPlugInInterface ( cfPlugInInterface );
        cfPlugInInterface = NULL;        
        return nil;
    }
	
	// get the mandatory data, and if we succeed also try to get optional
	if ([SMARTQuery getMandatoryData:smartInterface withResultsDict:ret]){;
        NSDictionary *attribs = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSString stringWithFormat:@"%i",kWindowSMARTsTempAttribute],kWindowSMARTsTempKeyString,
                                 [NSString stringWithFormat:@"%i",kWindowSMARTsStartStopCountAttribute],kWindowSMARTsStartStopCountKeyString,
                                 [NSString stringWithFormat:@"%i",kWindowSMARTsReallocatedSectorsCountAttribute],kWindowSMARTsReallocatedSectorsCountKeyString,
                                 [NSString stringWithFormat:@"%i",kWindowSMARTsLoadCycleCountAttribute],kWindowSMARTsLoadCycleCountKeyString,                      
                                 nil];
		[SMARTQuery getOptionalData:smartInterface withResultsDict:ret attributes:attribs];
    }
	
	( *smartInterface )->Release ( smartInterface );
	smartInterface = NULL;   
    
    IODestroyPlugInInterface ( cfPlugInInterface );
    cfPlugInInterface = NULL;         
	return ret;	
}


@end

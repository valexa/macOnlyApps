//
//  FilesTable.m
//  OSXCommander
//
//  Created by Vlad Alexa on 11/7/09.
//  Copyright 2009 NextDesign. All rights reserved.
//

#import "FilesTable.h"


@implementation FilesTable

- (void)awakeFromNib {
		
	NSLog(@"Awake FilesTable");		
	
	AppDelegate *appDel = (AppDelegate *)[[NSApplication sharedApplication] delegate];
	CFShow(appDel.leftPane);
	CFShow(appDel.rightPane);	
	CFShow(appDel.left.paneName);	
	CFShow(appDel.right.paneName);
	
	sysDict = [[NSMutableDictionary alloc] init];	
	
	NSDate *oldtime = [NSDate date];
	//NSDictionary *dict = [self listDir:@"/Users/valexa/Desktop/test"]; //get basic file listing
	NSDictionary *dict = [self travPath:@"/Users/valexa/Desktop/test"];	//get extended file listing
	NSLog(@"got listing for %i items in %f sec",[dict count],[[NSDate date] timeIntervalSinceDate:oldtime]);
	
	//put data in dict for table
	for (id key in dict) {
		//if getting nil ends adding, NOTE!
		[sysDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
							key, @"one",
							[[[dict objectForKey:key] objectForKey:@"dfork"] valueForKey:@"NSFileCreationDate"], @"two",
							[[[dict objectForKey:key] objectForKey:@"dfork"] valueForKey:@"NSFileType"], @"three",
							[[[dict objectForKey:key] objectForKey:@"URLattr"] valueForKey:@"NSURLLinkCountKey"], @"four",							
							[[[dict objectForKey:key] objectForKey:@"URLattr"] valueForKey:@"NSURLTypeIdentifierKey"], @"five",
							nil] forKey:[NSString stringWithFormat:@"%i",[sysDict count]]];
	}
}

#pragma mark delegates

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn{
	NSLog(@"clicked column %@",[tableColumn identifier]);
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{      
	NSTableView *theTableView = [aNotification object];
	NSLog(@"selected %i",[theTableView selectedRow]);
}

- (int)numberOfRowsInTableView:(NSTableView *)theTableView {
	return [sysDict count];
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(int)rowIndex {
	NSString *row = [NSString stringWithFormat:@"%d",rowIndex];
	return [[sysDict objectForKey:row] objectForKey:[theColumn identifier]];
}

#pragma mark functions

-(NSDictionary *)travPath:(NSString *)path{
	
	NSMutableDictionary *retDict = [NSMutableDictionary dictionaryWithCapacity:1];	

	NSURL *directoryURL = [[NSURL alloc] initWithString:path];
	
	NSArray *keys = [NSArray arrayWithObjects:
					 NSURLNameKey,
					 NSURLLocalizedNameKey,
					 NSURLIsRegularFileKey,
					 NSURLIsDirectoryKey,
					 NSURLIsSymbolicLinkKey,
					 NSURLIsVolumeKey,
					 NSURLIsPackageKey,
					 NSURLIsSystemImmutableKey,
					 NSURLIsUserImmutableKey,
					 NSURLIsHiddenKey,
					 NSURLHasHiddenExtensionKey,
					 NSURLCreationDateKey,
					 NSURLContentAccessDateKey,
					 NSURLContentModificationDateKey,
					 NSURLAttributeModificationDateKey,
					 NSURLLinkCountKey,
					 NSURLParentDirectoryURLKey,
					 NSURLVolumeURLKey,
					 NSURLTypeIdentifierKey,
					 NSURLLocalizedTypeDescriptionKey,
					 NSURLLabelNumberKey,
					 NSURLLabelColorKey,
					 //NSURLLocalizedLabelKey, bugged
					 NSURLEffectiveIconKey,
					 NSURLCustomIconKey,					 
					 nil];
	
					/*
					 NSFileType;
					 NSFileSize;
					 NSFileModificationDate;
					 NSFileReferenceCount;
					 NSFileDeviceIdentifier;
					 NSFileOwnerAccountName;
					 NSFileGroupOwnerAccountName;
					 NSFilePosixPermissions;
					 NSFileSystemNumber;
					 NSFileSystemFileNumber;
					 NSFileExtensionHidden;
					 NSFileHFSCreatorCode;
					 NSFileHFSTypeCode;
					 NSFileImmutable;
					 NSFileAppendOnly;
					 NSFileCreationDate;
					 NSFileOwnerAccountID;
					 NSFileGroupOwnerAccountID;
					 NSFileBusy;		 
					 */	
	
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
										 enumeratorAtURL:directoryURL
										 includingPropertiesForKeys:keys
										 options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsPackageDescendants)
										 errorHandler:^(NSURL *url, NSError *error) {
											 CFShow(error);
											 // Return YES if the enumeration should continue after the error.
											 return YES;
										 }];
	
	for (NSURL *url in enumerator) {
			
		NSMutableDictionary *urlDict = [NSMutableDictionary dictionaryWithCapacity:1];	
		NSMutableDictionary *vaDict = [NSMutableDictionary dictionaryWithCapacity:1];			
		
		//add this url dict
		[urlDict setObject:[url resourceValuesForKeys:keys error:NULL] forKey:@"URLattr"];	
		
		NSDictionary *dfork = [self fileInfo:[NSString stringWithFormat:@"%@",[url path]]];
		//add dfork to this url dict
		[urlDict setObject:dfork forKey:@"dfork"];
		
		NSDictionary *rfork = [self fileInfo:[NSString stringWithFormat:@"%@/rsrc",[url path]]];	
		//add rfork to this url dict
		[urlDict setObject:rfork forKey:@"rfork"];
		
		
		//get api filtered xattrib list
		NSArray *someXatt = [dfork objectForKey:@"NSFileExtendedAttributes"];
		if ([someXatt count] > 0) {		
			NSString *xatStr = @"";
			for (id key in someXatt) {	
				xatStr = [xatStr stringByAppendingString:[NSString stringWithFormat:@"%@ ",key]];				
			}	
			//NSLog(@"got %i (%@) api xattrs for : %@",[someXatt count],xatStr,[url path]);			
		}
		//add someXatt to this url dict
		if (!someXatt) someXatt = [NSArray array];
		[urlDict setObject:someXatt forKey:@"someXatt"];		
		
		//read xattrs directly from B-tree
		NSArray *allXatt = [UKXattrMetadataStore allKeysAtPath:[url path] traverseLink:FALSE];
		if ([allXatt count] > 0) {		
			NSString *xatStr = @"";
			for (id key in allXatt) {	
				xatStr = [xatStr stringByAppendingString:[NSString stringWithFormat:@"%@ ",key]];				
			}	
			//NSLog(@"read %i (%@) b-tree xattrs for : %@",[allXatt count],xatStr,[url path]);			
		}		
		//add allXatt to this url dict
		if (!allXatt) allXatt = [NSArray array];		
		[urlDict setObject:allXatt forKey:@"allXatt"];		
		
		//the file has a resource fork	
		NSComparisonResult result = [[rfork objectForKey:@"NSFileSize"] compare:[NSNumber numberWithInt:0]];
		if(result == NSOrderedDescending){			
  		    //NSLog(@"found file with rfork: %@ : %i",[url path],[rfork valueForKey:@"NSFileSize"]);
			
			//the file has preview
			if ([self hasResource:'pnot' path:[url path]]){		
					[vaDict setObject:@"PNOT" forKey:@"VANotPreview"];					
					//NSLog(@"file with preview : %@",[url path]);
			}	

			//the file is a alias
			if ([self hasResource:'alis' path:[url path]]){
				//resolve it
				NSString *result = [self resolveAlias:[url path]];
				if (result){
					[vaDict setObject:result forKey:@"VAAliasTarget"];					
					//NSLog(@"got alias file : %@ : %@",[url path],result);			
				}else{
					[vaDict setObject:@"BROKEN" forKey:@"VAAliasTarget"];					
					//NSLog(@"got BROKEN alias file : %@",[url path]);		
				}				
			}				
			
		}			
		
		if ([url baseURL]) {
			NSLog(@"URL NOT absolute : %@",[url absoluteString]);
		}
			
		NSString *rawName = nil;
		[url getResourceValue:&rawName forKey:NSURLNameKey error:NULL];		
		NSString *localizedName = nil;
		[url getResourceValue:&localizedName forKey:NSURLLocalizedNameKey error:NULL];			
		if (![rawName isEqualToString:localizedName]){
			NSLog(@"got localized : %@",[url path]);
		}
		
		NSNumber *isRegular = nil;
		[url getResourceValue:&isRegular forKey:NSURLIsRegularFileKey error:NULL];	
		if ([isRegular boolValue]) {
			//NSLog(@"got regular file : %@",[url path]);	
		}		
		
		NSNumber *isSymlink = nil;
		[url getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:NULL];	
		if ([isSymlink boolValue]) {
			//resolve it
			NSString *result=[self resolveSymlink:[url path]];
			if (result){
				[vaDict setObject:result forKey:@"VASymlinkTarget"];				
				//NSLog(@"got link file : %@ : %@",[url path],result);			
			}else {
				[vaDict setObject:@"BROKEN" forKey:@"VASymlinkTarget"];					
				//NSLog(@"got BROKEN link file : %@",[url path]);					
			}
		}		
		
		NSNumber *isDirectory = nil;		
		[url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];		
		if ([isDirectory boolValue]) {
			NSNumber *isPackage = nil;
			[url getResourceValue:&isPackage forKey:NSURLIsPackageKey error:NULL];	
			if ([isPackage boolValue]) {
				//NSLog(@"got package at %@", localizedName);
			}
			else {
				//NSLog(@"got directory at %@", localizedName);
			}
		}
		
		NSNumber *isVolume = nil;
		[url getResourceValue:&isVolume forKey:NSURLIsVolumeKey error:NULL];	
		if ([isVolume boolValue]) {
				NSLog(@"got volume : %@",[url path]);
		}
		
		NSNumber *isSysImm = nil;
		[url getResourceValue:&isSysImm forKey:NSURLIsSystemImmutableKey error:NULL];	
		if ([isSysImm boolValue]) {
			//NSLog(@"got sys immutable : %@",[url path]);
		}
		
		NSNumber *isUsrImm = nil;
		[url getResourceValue:&isUsrImm forKey:NSURLIsUserImmutableKey error:NULL];	
		if ([isUsrImm boolValue]) {
			//NSLog(@"got usr immutable : %@",[url path]);
		}			
		
		NSNumber *isHidden = nil;
		[url getResourceValue:&isHidden forKey:NSURLIsHiddenKey error:NULL];	
		if ([isHidden boolValue]) {
			//NSLog(@"got hidden : %@",[url path]);	
		}		

		NSNumber *isHiddenExt = nil;
		[url getResourceValue:&isHiddenExt forKey:NSURLHasHiddenExtensionKey error:NULL];	
		if ([isHiddenExt boolValue]) {
			//NSLog(@"got hidden extension : %@",[url path]);	
		}		

		NSDate *createDate = nil;
		[url getResourceValue:&createDate forKey:NSURLCreationDateKey error:NULL];	
		if (!createDate) {
			NSLog(@"didn't get create date for %@",[url path]);
		}
		
		NSDate *accDate = nil;
		[url getResourceValue:&accDate forKey:NSURLContentAccessDateKey error:NULL];	
		if (!accDate) {
			NSLog(@"didn't get access date for %@",[url path]);
		}
		
		NSDate *modDate = nil;
		[url getResourceValue:&modDate forKey:NSURLContentModificationDateKey error:NULL];	
		if (!modDate) {
			NSLog(@"didn't get modif date for %@",[url path]);
		}	
		
		NSDate *amodDate = nil;
		[url getResourceValue:&amodDate forKey:NSURLAttributeModificationDateKey error:NULL];	
		if (!amodDate) {
			NSLog(@"didn't get attribs modif date for %@",[url path]);
		}	
		
		NSNumber *linkCount = nil;
		[url getResourceValue:&linkCount forKey:NSURLLinkCountKey error:NULL];	
		if (!linkCount) {
			NSLog(@"didn't get link count for %@",[url path]);
		}		
		
		NSURL *parentDir = nil;
		[url getResourceValue:&parentDir forKey:NSURLParentDirectoryURLKey error:NULL];	

		NSURL *parentVol = nil;
		[url getResourceValue:&parentVol forKey:NSURLVolumeURLKey error:NULL];
		
		/*bugged
		NSURL *localLbl = nil;
		[url getResourceValue:&localLbl forKey:NSURLLocalizedLabelKey error:NULL];
		*/
		
		NSString *typeId = nil;
		[url getResourceValue:&typeId forKey:NSURLTypeIdentifierKey error:NULL];	
		if (!typeId) {
			NSLog(@"didn't get type identifier for %@",[url path]);
		}	
		
		NSString *localDesc = nil;
		[url getResourceValue:&localDesc forKey:NSURLLocalizedTypeDescriptionKey error:NULL];	
		if (!localDesc) {
			NSLog(@"didn't get localized description for %@",[url path]);
		}		
		
		NSNumber *lblNum = nil;
		[url getResourceValue:&lblNum forKey:NSURLLabelNumberKey error:NULL];	
		if (!lblNum) {
			NSLog(@"didn't get label number for %@",[url path]);
		}		
		
		NSString *lblColor = nil;
		[url getResourceValue:&lblColor forKey:NSURLLabelColorKey error:NULL];	
		if (lblColor) {
			//NSLog(@"got label color for %@",[url path]);
		}	
		
		NSImage *effIcon = nil;
		[url getResourceValue:&effIcon forKey:NSURLEffectiveIconKey error:NULL];	
		if (!effIcon) {
			NSLog(@"didn't get effective icon for %@",[url path]);
		}
			
		NSImage *custIcon = nil;
		[url getResourceValue:&custIcon forKey:NSURLCustomIconKey error:NULL];	
		if (custIcon) {
			NSLog(@"got custom icon for %@",[url path]);
		}	
		
		//add vadict to this url dict
		[urlDict setObject:vaDict forKey:@"VAattr"];		
		
		//add this url dict to return		
		[retDict setObject:urlDict forKey:[url lastPathComponent]];	
					
	}
	
	return retDict;
	
}

-(NSDictionary *)listDir:(NSString *)path{
	NSMutableDictionary *retDict = [NSMutableDictionary dictionaryWithCapacity:1];	
	NSArray *contentsAtPath = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
	if (contentsAtPath) {
	    for (NSString *filename in contentsAtPath) {
			//NSLog(@"found : %@",filename);
			[retDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:[self fileInfo:[NSString stringWithFormat:@"%@/%@",path,filename]],@"dfork",nil] forKey:filename];			
		}
	} else {
		NSLog(@"cant read %@",path);
	}
	return retDict;
}

-(NSDictionary *)listDirRec:(NSString *)path{
	NSMutableDictionary *retDict = [NSMutableDictionary dictionaryWithCapacity:1];
	NSDirectoryEnumerator *contentsAtPath = [[NSFileManager defaultManager] enumeratorAtPath:path];
	if (contentsAtPath) {
	    for (NSString *filename in contentsAtPath) {
			//NSLog(@"found : %@",filename);			
			[retDict setObject:[NSDictionary dictionaryWithObjectsAndKeys:[contentsAtPath fileAttributes],@"dfork",nil] forKey:filename];				
		}
	} else {
		NSLog(@"cant read %@",path);
	}
	return retDict;
}

-(NSString *)resolveAlias:(NSString *)path{
	NSString *resolvedPath = nil;
	
	CFURLRef url = CFURLCreateWithFileSystemPath
	(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, NO);
	if (url != NULL)
	{
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef))
		{
			Boolean targetIsFolder, wasAliased;
			OSErr err = FSResolveAliasFile (&fsRef, true, &targetIsFolder, &wasAliased);
			if ((err == noErr) && wasAliased)
			{
				CFURLRef resolvedUrl = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsRef);
				if (resolvedUrl != NULL)
				{
					resolvedPath = (NSString*)CFURLCopyFileSystemPath(resolvedUrl, kCFURLPOSIXPathStyle);
					CFRelease(resolvedUrl);
				}
			}
		}
		CFRelease(url);
	}
	
	return resolvedPath;
}

-(NSString *)resolveSymlink:(NSString *)path{
	NSString *resolvedPath = nil;
	resolvedPath = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:path error:NULL];
	//now check that file exists
	if (![[NSFileManager defaultManager] fileExistsAtPath:resolvedPath]){
		return nil;
	}	
	return resolvedPath;
}

-(NSDictionary *)fileInfo:(NSString *)path{
	NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
	if (dict){
		//wasting cpu and mem here , TODO!
		return [NSDictionary dictionaryWithDictionary:dict];
	}else {
		return [NSMutableDictionary dictionaryWithCapacity:1];
	}
	
}

-(BOOL)hasResource:(ResType)type path:(NSString *)path{
	FSRef       myRef;
    SInt16      refNum;
    char **     creatorRsrc;
	
    if ( FSPathMakeRef((const UInt8 *)[path UTF8String], &myRef, NULL) == noErr ){

		refNum = FSOpenResFile(&myRef, fsRdPerm);
		if (refNum != -1){
			SetResLoad(FALSE);
			creatorRsrc = Get1Resource(type, 0);
			if (creatorRsrc != NULL){
				//NSLog(@"read alis for %@",path);
				assert( ResError() == 0 );	
				return TRUE;
			}										
		}
	}else{
		NSLog(@"couldn't make FSRef for %@", path);
	}	
	return FALSE;
}

- (void)makeAliasToFolder:(NSString *)destFolder inFolder:(NSString *)parentFolder withName:(NSString *)name{
	
    // Create a resource file for the alias.
    FSRef parentRef;
    CFURLGetFSRef((CFURLRef)[NSURL fileURLWithPath:parentFolder], &parentRef);
    HFSUniStr255 aliasName;
    FSGetHFSUniStrFromString((CFStringRef)name, &aliasName);
    FSRef aliasRef;
    FSCreateResFile(&parentRef, aliasName.length, aliasName.unicode, 0, NULL, &aliasRef, NULL);
	
    // Construct alias data to write to resource fork.
    FSRef targetRef;
    CFURLGetFSRef((CFURLRef)[NSURL fileURLWithPath:destFolder], &targetRef);
    AliasHandle aliasHandle = NULL;
    FSNewAlias(NULL, &targetRef, &aliasHandle);
	
    // Add the alias data to the resource fork and close it.
    ResFileRefNum fileReference = FSOpenResFile(&aliasRef, fsRdWrPerm);
    UseResFile(fileReference);
    AddResource((Handle)aliasHandle, 'alis', 0, NULL);
    CloseResFile(fileReference);
	
    // Update finder info.
    FSCatalogInfo catalogInfo;
    FSGetCatalogInfo(&aliasRef, kFSCatInfoFinderInfo, &catalogInfo, NULL, NULL, NULL);
    FileInfo *theFileInfo = (FileInfo*)(&catalogInfo.finderInfo);
    theFileInfo->finderFlags |= kIsAlias; // Set the alias bit.
    theFileInfo->finderFlags &= ~kHasBeenInited; // Clear the inited bit to tell Finder to recheck the file.
    theFileInfo->fileType = kContainerFolderAliasType;
    FSSetCatalogInfo(&aliasRef, kFSCatInfoFinderInfo, &catalogInfo);
}

@end

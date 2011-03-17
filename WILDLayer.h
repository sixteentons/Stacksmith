//
//  WILDLayer.h
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WILDScriptContainer.h"
#import "WILDObjectID.h"


@class ULIMultiMap;
@class WILDStack;
@class WILDPart;
@class WILDPartContents;
@class WILDCard;
@class WILDBackground;


@interface WILDLayer : NSObject <WILDScriptContainer>
{
	WILDObjectID				mID;				// Unique ID number of this background/card.
	NSString*					mName;				// Name of this background/card.
	NSString*					mScript;			// Script text.
	BOOL						mShowPict;			// Should we draw mPicture or not?
	BOOL						mDontSearch;		// Do not include this card in searches.
	BOOL						mCantDelete;		// Prevent scripts from deleting this card?
	NSImage*					mPicture;			// Card/background picture.
	NSMutableArray*				mParts;				// Array of parts on this card.
	NSMutableArray*				mAddColorParts;		// Array of parts for which we have AddColor color information. May contain parts that are already in mParts.
	NSMutableDictionary*		mContents;			// Dictionary of part ID -> contents mappings
	ULIMultiMap*					mButtonFamilies;	// Family ID as key, and arrays of button parts belonging to these families.
	WILDStack*					mStack;
	
	WILDObjectID				mPartIDSeed;
}

-(id)							initForStack: (WILDStack*)theStack;
-(id)							initWithXMLDocument: (NSXMLDocument*)elem
										forStack: (WILDStack*)theStack;

-(void)							loadAddColorObjects: (NSXMLElement*)theElem;

-(WILDObjectID)					backgroundID;

-(NSImage*)						picture;
-(BOOL)							showPicture;

-(NSArray*)						parts;
-(NSArray*)						addColorParts;
-(WILDPartContents*)			contentsForPart: (WILDPart*)thePart;
-(WILDPart*)					partWithID: (WILDObjectID)theID;
-(WILDObjectID)					uniqueIDForPart;

-(void)							updatePartOnClick: (WILDPart*)thePart withCard: (WILDCard*)inCard background: (WILDBackground*)inBackground;

-(NSString*)					partLayer;

-(void)							createNewButton: (id)sender;
-(void)							createNewField: (id)sender;
-(void)							addNewPartFromXMLTemplate: (NSURL*)xmlFile;

-(WILDStack*)					stack;
-(void)							updateChangeCount: (NSDocumentChangeType)inChange;

-(NSString*)					script;
-(void)							setScript: (NSString*)theScript;

-(NSString*)					xmlStringForWritingToURL: (NSURL*)packageURL error: (NSError**)outError;
-(void)							appendInnerAddColorObjectXmlToString: (NSMutableString*)theString;
-(void)							appendInnerXmlToString: (NSMutableString*)theString;	// Hook-in point for subclasses like WILDCard.

@end
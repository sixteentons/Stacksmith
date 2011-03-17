//
//  WILDPart.m
//  Propaganda
//
//  Created by Uli Kusterer on 28.02.10.
//  Copyright 2010 The Void Software. All rights reserved.
//

#import "WILDPart.h"
#import "WILDXMLUtils.h"
#import "WILDLayer.h"
#import "WILDStack.h"
#import "WILDPartContents.h"
#import "WILDNotifications.h"


static NSInteger UKMinimum( NSInteger a, NSInteger b )
{
	return ((a < b) ? a : b);
}


static NSInteger UKMaximum( NSInteger a, NSInteger b )
{
	return ((a > b) ? a : b);
}


@implementation WILDPart

@synthesize dontWrap = mDontWrap;
@synthesize autoTab = mAutoTab;
@synthesize dontSearch = mDontSearch;
@synthesize lockText = mLockText;
@synthesize wideMargins = mWideMargins;
@synthesize fixedLineHeight = mFixedLineHeight;
@synthesize showLines = mShowLines;
@synthesize sharedText = mSharedText;

-(id)	initWithXMLElement: (NSXMLElement*)elem forStack: (WILDStack*)inStack
{
	if(( self = [super init] ))
	{
		mStack = inStack;
		mID = WILDIntegerFromSubElementInElement( @"id", elem );
		mRectangle = WILDRectFromSubElementInElement( @"rect", elem );
		mName = [WILDStringFromSubElementInElement( @"name", elem ) retain];
		mScript = [WILDStringFromSubElementInElement( @"script", elem ) retain];
		mStyle = [WILDStringFromSubElementInElement( @"style", elem ) retain];
		mType = [WILDStringFromSubElementInElement( @"type", elem ) retain];
		mVisible = (!elem) ? YES : WILDBoolFromSubElementInElement( @"visible", elem );
		mDontWrap = WILDBoolFromSubElementInElement( @"dontWrap", elem );
		mDontSearch = WILDBoolFromSubElementInElement( @"dontSearch", elem );
		mSharedText = WILDBoolFromSubElementInElement( @"sharedText", elem );
		mFixedLineHeight = WILDBoolFromSubElementInElement( @"fixedLineHeight", elem );
		mAutoTab = WILDBoolFromSubElementInElement( @"autoTab", elem );
		mLockText = WILDBoolFromSubElementInElement( @"lockText", elem );
		mAutoSelect = WILDBoolFromSubElementInElement( @"autoSelect", elem );
		mShowLines = WILDBoolFromSubElementInElement( @"showLines", elem );
		mAutoHighlight = WILDBoolFromSubElementInElement( @"autoHighlight", elem );
		mWideMargins = WILDBoolFromSubElementInElement( @"wideMargins", elem );
		mMultipleLines = WILDBoolFromSubElementInElement( @"multipleLines", elem );
		mShowName = WILDBoolFromSubElementInElement( @"showName", elem );
		mSelectedLines = [WILDIndexSetFromSubElementInElement( @"selectedLines", elem, -1 ) retain];
		mTitleWidth = WILDIntegerFromSubElementInElement( @"titleWidth", elem );
		mHighlight = WILDBoolFromSubElementInElement( @"highlight", elem );
		mSharedHighlight = WILDBoolFromSubElementInElement( @"sharedHighlight", elem );
		mEnabled = WILDBoolFromSubElementInElement( @"enabled", elem );
		mFamily = WILDIntegerFromSubElementInElement( @"family", elem );
		
		NSString*		alignStr = WILDStringFromSubElementInElement( @"textAlign", elem );
		if( [alignStr isEqualToString: @"forceLeft"] )
			mTextAlignment = NSLeftTextAlignment;
		else if( [alignStr isEqualToString: @"center"] )
			mTextAlignment = NSCenterTextAlignment;
		else if( [alignStr isEqualToString: @"right"] )
			mTextAlignment = NSRightTextAlignment;
		else if( [alignStr isEqualToString: @"justified"] )	// Not available in HC.
			mTextAlignment = NSJustifiedTextAlignment;
		else //if( [alignStr isEqualToString: @"left"] )
			mTextAlignment = NSNaturalTextAlignment;
		
		mTextFontName = [WILDStringFromSubElementInElement( @"font", elem ) retain];
		mTextFontSize = WILDIntegerFromSubElementInElement( @"textSize", elem );
		mTextHeight = WILDIntegerFromSubElementInElement( @"textHeight", elem );
		mTextStyles = [WILDStringsFromSubElementInElement( @"textStyle", elem ) retain];
		mIconID = WILDIntegerFromSubElementInElement( @"icon", elem );
	}
	
	return self;
}


-(void)	dealloc
{
	[mName release];
	mName = nil;
	[mScript release];
	mScript = nil;
	[mStyle release];
	mStyle = nil;
	[mType release];
	mType = nil;
	[mLayer release];
	mLayer = nil;
	[mTextFontName release];
	mTextFontName = nil;
	[mTextStyles release];
	mTextStyles = nil;
	[mFillColor release];
	mFillColor = nil;
	
	mStack = nil;
	
	[super dealloc];
}


-(BOOL)	toggleHighlightAfterTracking
{
	return [mStyle isEqualToString: @"checkbox"] || [mStyle isEqualToString: @"radiobutton"]
			 || mFamily != 0;
}


-(void)	setFlippedRectangle: (NSRect)theBox
{
	mRectangle = theBox;
}


-(NSRect)	flippedRectangle
{
	return mRectangle;
}


-(NSRect)	rectangle
{
	NSRect		resultRect = mRectangle;
	resultRect.origin.y = [mStack cardSize].height -NSMaxY( mRectangle );
	return resultRect;
}


-(NSRect)	setRectangle: (NSRect)theBox
{
	theBox.origin.y = [mStack cardSize].height -NSMaxY( theBox );
	mRectangle = theBox;
}


-(void)	setName: (NSString*)theStr
{
	if( mName != theStr )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"name"
																forKey: WILDAffectedPropertyKey]];
		[mName release];
		mName = [theStr retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"name"
																forKey: WILDAffectedPropertyKey]];
		[self updateChangeCount: NSChangeDone];
	}
}


-(NSString*)	name
{
	return mName;
}


-(NSString*)	style
{
	return mStyle;
}


-(void)	setStyle: (NSString*)theStyle
{
	if( mStyle != theStyle )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"style"
																forKey: WILDAffectedPropertyKey]];
		[mStyle release];
		mStyle = [theStyle retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"style"
																forKey: WILDAffectedPropertyKey]];
		[self updateChangeCount: NSChangeDone];
	}
}


-(NSString*)	partType
{
	return mType;
}


-(void)	setPartType: (NSString*)partType
{
	if( mType != partType )
	{
		[mType release];
		mType = [partType retain];
	}
}


-(WILDObjectID)	partID
{
	return mID;
}


-(void)	setPartID: (WILDObjectID)inID
{
	mID = inID;
}


-(NSInteger)	partNumber
{
	return [[mOwner parts] indexOfObject: self];
}


-(NSInteger)	partNumberAmongPartsOfType: (NSString*)partType
{
	NSInteger		pbn = -1;
	for( WILDPart* currPart in [mOwner parts] )
	{
		if( [[currPart partType] isEqualToString: partType] )
			pbn++;
		if( currPart == self )
			break;
	}
	
	return pbn;
}


-(void)		setPartLayer: (NSString*)theLayer
{
	if( theLayer != mLayer )
	{
		[mLayer release];
		mLayer = [theLayer retain];
	}
}

-(NSString*)	partLayer
{
	return mLayer;
}


-(void)	setPartOwner: (WILDLayer*)cardOrBg
{
	mOwner = cardOrBg;
}


-(WILDLayer*)	partOwner
{
	return mOwner;
}


-(NSFont*)	textFont
{
	NSFont*		theFont = [NSFont fontWithName: mTextFontName size: mTextFontSize];
	if( !theFont && ([mTextFontName isEqualToString: @"Chicago"] || [mTextFontName isEqualToString: @"Charcoal"]) )
		theFont = [NSFont boldSystemFontOfSize: mTextFontSize];
	if( !theFont )
		theFont = [NSFont fontWithName: @"Geneva" size: mTextFontSize];
	if( !theFont )
		theFont = [NSFont userFontOfSize: mTextFontSize];

	if( [mTextStyles containsObject: @"bold"] )
	{
		NSFont*	boldFont = [[NSFontManager sharedFontManager] convertWeight: YES ofFont: theFont];
		if( boldFont )
			theFont = boldFont;
	}

	if( [mTextStyles containsObject: @"italic"] )
	{
		NSFont*	italicFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSItalicFontMask];
		if( italicFont )
			theFont = italicFont;
	}

	if( [mTextStyles containsObject: @"condense"] )
	{
		NSFont*	condensedFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSCondensedFontMask];
		if( condensedFont )
			theFont = condensedFont;
	}

	if( [mTextStyles containsObject: @"extend"] )
	{
		NSFont*	expandedFont = [[NSFontManager sharedFontManager] convertFont: theFont toHaveTrait: NSExpandedFontMask];
		if( expandedFont )
			theFont = expandedFont;
	}
	
	return theFont;
}


-(NSMutableDictionary*)	textAttributes
{
	NSMutableDictionary*	attrs = [NSMutableDictionary dictionary];
	if( [mTextStyles containsObject: @"shadow"] )
	{
		NSShadow*	theShadow = [[[NSShadow alloc] init] autorelease];
		[theShadow setShadowColor: [NSColor grayColor]];
		[theShadow setShadowBlurRadius: 1.0];
		[theShadow setShadowOffset: NSMakeSize(0.0,-1.0)];
		[attrs setObject: theShadow forKey: NSShadowAttributeName];
		[attrs setObject: [NSNumber numberWithInt: 1.0] forKey: NSStrokeWidthAttributeName];
		[attrs setObject: [NSColor clearColor] forKey: NSForegroundColorAttributeName];
	}
	else if( [mTextStyles containsObject: @"outline"] )
	{
		[attrs setObject: [NSNumber numberWithInt: 1.0] forKey: NSStrokeWidthAttributeName];
		[attrs setObject: [NSColor clearColor] forKey: NSForegroundColorAttributeName];
	}
	else if( [mTextStyles containsObject: @"underline"] )
	{
		[attrs setObject: [NSNumber numberWithInt: NSUnderlineStyleSingle] forKey: NSUnderlineStyleAttributeName];
	}
	else if( [mTextStyles containsObject: @"group"] )
	{
		[attrs setObject: [NSNumber numberWithInt: NSUnderlineStyleThick] forKey: NSUnderlineStyleAttributeName];
		[attrs setObject: [NSColor grayColor] forKey: NSUnderlineColorAttributeName];
	}
	
	NSMutableParagraphStyle*	paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paraStyle setAlignment: mTextAlignment];
	if( mFixedLineHeight )
	{
		[paraStyle setMinimumLineHeight: mTextHeight];
		[paraStyle setMaximumLineHeight: mTextHeight];
	}
	[attrs setObject: paraStyle forKey: NSParagraphStyleAttributeName];
	
	[attrs setObject: [self textFont] forKey: NSFontAttributeName];
	
	return attrs;
}


-(NSTextAlignment)	textAlignment
{
	return mTextAlignment;
}


-(BOOL)	showName
{
	return mShowName;
}


-(void)		setShowName: (BOOL)theState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"showName"
															forKey: WILDAffectedPropertyKey]];
	mShowName = theState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"showName"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(BOOL)	isEnabled
{
	return mEnabled;
}


-(void)		setEnabled: (BOOL)theState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"enabled"
															forKey: WILDAffectedPropertyKey]];
	mEnabled = theState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"enabled"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(BOOL)	visible
{
	return mVisible;
}


-(void)		setVisible: (BOOL)theState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"visible"
															forKey: WILDAffectedPropertyKey]];
	mVisible = theState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"visible"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(NSInteger)	popupTitleWidth
{
	return mTitleWidth;
}


-(void)	setIconID: (NSInteger)theID
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"iconID"
															forKey: WILDAffectedPropertyKey]];
	mIconID = theID;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"iconID"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(NSInteger)	iconID
{
	return mIconID;
}


-(NSImage*)	iconImage
{
	if( [mType isEqualToString: @"picture"] )
		return [[mStack document] pictureOfType: @"picture" name: mName];
	else if( mIconID == -1 )
		return [[mStack document] pictureOfType: @"picture" name: mName];
	else if( mIconID == 0 )
		return nil;
	else
		return [[mStack document] pictureOfType: @"icon" id: mIconID];
}


-(BOOL)	wideMargins
{
	return mWideMargins;
}


-(void)	setHighlighted: (BOOL)inState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"highlighted" forKey: WILDAffectedPropertyKey]];
	mHighlight = inState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"highlighted" forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(BOOL)	highlighted
{
	return mHighlight;
}


-(void)	setAutoHighlight: (BOOL)inState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"autoHighlight" forKey: WILDAffectedPropertyKey]];
	mAutoHighlight = inState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"autoHighlight" forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(BOOL)	autoHighlight
{
	return mAutoHighlight;
}


-(BOOL)	sharedText
{
	return mSharedText;
}


-(BOOL)	sharedHighlight
{
	return mSharedHighlight;
}


-(void)	setSharedHighlight: (BOOL)inState
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"sharedHighlight" forKey: WILDAffectedPropertyKey]];
	mSharedHighlight = inState;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"sharedHighlight" forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(void)	setHighlightedForTracking: (BOOL)inState
{
	mHighlightedForTracking = inState;
}


-(BOOL)	highlightedForTracking
{
	return mHighlightedForTracking;
}


-(NSInteger)	family
{
	return mFamily;
}


-(void)	setFamily: (NSInteger)inFamilyNumber
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"family" forKey: WILDAffectedPropertyKey]];
	mFamily = inFamilyNumber;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"family" forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(void)	setFillColor: (NSColor*)theColor
{
	if( mFillColor != theColor )
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"fillColor"
																forKey: WILDAffectedPropertyKey]];
		[mFillColor release];
		mFillColor = [theColor retain];
		[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
								object: self userInfo: [NSDictionary dictionaryWithObject: @"fillColor"
																forKey: WILDAffectedPropertyKey]];
		[self updateChangeCount: NSChangeDone];
	}
}


-(NSColor*)		fillColor
{
	if( !mFillColor )
		return [NSColor whiteColor];
	return mFillColor;
}


-(void)		setBevel: (NSInteger)theBevel
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"bevel"
															forKey: WILDAffectedPropertyKey]];
	mBevel = theBevel;
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"bevel"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(NSInteger)	bevel
{
	return mBevel;
}


-(NSString*)	script
{
	return mScript;
}


-(void)	setScript: (NSString*)theScript
{
	if( mScript != theScript )
	{
		[mScript release];
		mScript = [theScript retain];
		[self updateChangeCount: NSChangeDone];
	}
}


-(NSString*)	displayName
{
	NSString*	theFmt = @"part ID %1$d";
	BOOL		haveName = mName && [mName length] > 0;
	BOOL		isField = [mType isEqualToString: @"field"];
	
	if( isField && haveName )
		theFmt = @"field “%2$@” (ID %1$d)";
	else if( isField && !haveName )
		theFmt = @"field ID %1$d";
	else if( !isField && haveName )
		theFmt = @"button “%2$@” (ID %1$d)";
	else if( !isField && !haveName )
		theFmt = @"button ID %1$d";
	
	return [NSString stringWithFormat: theFmt, mID, mName];
}


-(NSImage*)	displayIcon
{
	BOOL		isField = [mType isEqualToString: @"field"];
	
	if( isField )
		return [NSImage imageNamed: @"FieldIconSmall"];
	else
		return [NSImage imageNamed: @"ButtonIconSmall"];
}


-(NSIndexSet*)	selectedListItemIndexes
{
	return mSelectedLines;
}


-(void)	setSelectedListItemIndexes: (NSIndexSet*)newSelection
{
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartWillChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"selectedListItemIndexes"
															forKey: WILDAffectedPropertyKey]];
	[mSelectedLines removeAllIndexes];
	[mSelectedLines addIndexes: newSelection];
	[[NSNotificationCenter defaultCenter] postNotificationName: WILDPartDidChangeNotification
							object: self userInfo: [NSDictionary dictionaryWithObject: @"selectedListItemIndexes"
															forKey: WILDAffectedPropertyKey]];
	[self updateChangeCount: NSChangeDone];
}


-(BOOL)	autoSelect
{
	return mAutoSelect;
}


-(void)	setAutoSelect: (BOOL)inState
{
	[self updateChangeCount: NSChangeDone];
	mAutoSelect = inState;
}


-(BOOL)			canSelectMultipleLines
{
	return mMultipleLines;
}


-(void)			setCanSelectMultipleLines: (BOOL)inState
{
	mMultipleLines = inState;
	[self updateChangeCount: NSChangeDone];
}


-(BOOL)		showLines
{
	return mShowLines;
}


-(NSInteger)	titleWidth
{
	return mTitleWidth;
}


-(BOOL)			fixedLineHeight
{
	return mFixedLineHeight;
}


-(NSInteger)	textHeight
{
	return mTextHeight;
}


-(WILDStack*)	stack
{
	return mStack;
}


-(void)	updateViewOnClick: (NSView*)sender withCard: (WILDCard*)inCard background: (WILDBackground*)inBackground
{
	[[self partOwner] updatePartOnClick: self withCard: inCard background: inBackground];
}


-(BOOL)	searchForPattern: (NSString*)inPattern withContext: (WILDSearchContext*)inContext
			flags: (WILDSearchFlags)inFlags
{
	// We only know how to search fields at the moment:
	if( mDontSearch || ![[self partType] isEqualToString: @"field"]
		|| ![self visible] )
	{
		;//NSLog( @"Skipping %@", [self displayName] );
		return NO;
	}
	
	// Fetch the correct text for this field:
	NSString*	myText = nil;
	if( [self sharedText] )
		myText = [[mOwner contentsForPart: self] text];
	else
		myText = [[inContext.currentCard contentsForPart: self] text];
	
	if( [myText length] == 0 )
	{
		//NSLog( @"No text in %@", [self displayName] );
		return NO;
	}
	
	// Are we just starting to search?
	if( inContext.currentPart != self )
	{
		inContext.currentPart = self;
		if( inFlags & WILDSearchBackwards )
			inContext.currentResultRange = NSMakeRange([myText length], 0);
		else
			inContext.currentResultRange = NSMakeRange(0, 0);
	}
	
	// Determine what text range we still have to search through:
	NSRange searchRange = { 0, 0 };
	if( inFlags & WILDSearchBackwards )
	{
		searchRange.location = 0;
		searchRange.length = inContext.currentResultRange.location +UKMaximum(0,inContext.currentResultRange.length -1);
	}
	else
	{
		// We advance by 1 only, so searches for "aaa" in "aaaa" give two results:
		searchRange.location = inContext.currentResultRange.location +UKMinimum(1,inContext.currentResultRange.length);
		searchRange.length = [myText length] -searchRange.location;
	}
	
	if( searchRange.length == 0 )
	{
		//NSLog( @"Last result at %@ was already at end", [self displayName] );
		return NO;
	}
	
	// Actually find the string:
	NSStringCompareOptions		compareOptions = 0;
	if( inFlags & WILDSearchCaseInsensitive )
		compareOptions |= NSCaseInsensitiveSearch;
	if( inFlags & WILDSearchBackwards )
		compareOptions |= NSBackwardsSearch;
	NSRange foundRange = [myText rangeOfString: inPattern options: compareOptions range: searchRange];
	if( foundRange.location != NSNotFound )
	{
		inContext.currentResultRange = foundRange;
		//NSLog( @"Found %@ in range %@ of %@", NSStringFromRange( foundRange ), NSStringFromRange( searchRange ), [self displayName] );
		return YES;
	}
	else
		;//NSLog( @"Found nothing in %@", [self displayName] );
	
	return NO;
}


-(void)	updateChangeCount: (NSDocumentChangeType)inChange
{
	[mOwner updateChangeCount: inChange];
}


-(NSString*)	xmlString
{
	NSMutableString*	outString = [[[NSMutableString alloc] init] autorelease];
	
	[outString appendString: @"\t<part>\n"];
	
	[outString appendFormat: @"\t\t<id>%ld</id>\n", mID];
	[outString appendFormat: @"\t\t<type>%@</type>\n", [self partType]];
	[outString appendFormat: @"\t\t<layer>%@</layer>\n", mLayer];
	[outString appendFormat: @"\t\t<visible>%@</visible>\n", (mVisible ? @"<true />" : @"<false />")];
	[outString appendFormat: @"\t\t<enabled>%@</enabled>\n", (mEnabled ? @"<true />" : @"<false />")];
	[outString appendFormat: @"\t\t<rect>\n\t\t\t<left>%d</left>\n\t\t\t<top>%d</top>\n\t\t\t<right>%d</right>\n\t\t\t<bottom>%d</bottom>\n\t\t</rect>\n",
								(int)NSMinX(mRectangle), (int)NSMinY(mRectangle), (int)NSMaxX(mRectangle), (int)NSMaxY(mRectangle)];
	[outString appendFormat: @"\t\t<style>%@</style>\n", [self style]];
	[outString appendFormat: @"\t\t<showName>%@</showName>\n", (mShowName ? @"<true />" : @"<false />")];
	[outString appendFormat: @"\t\t<highlight>%@</highlight>\n", (mHighlight ? @"<true />" : @"<false />")];
	[outString appendFormat: @"\t\t<autoHighlight>%@</autoHighlight>\n", (mAutoHighlight ? @"<true />" : @"<false />")];
	[outString appendFormat: @"\t\t<sharedHighlight>%@</sharedHighlight>\n", (mSharedHighlight ? @"<true />" : @"<false />")];
	[outString appendFormat: @"\t\t<family>%d</family>\n", mFamily];
	[outString appendFormat: @"\t\t<titleWidth>%d</titleWidth>\n", mTitleWidth];
	[outString appendFormat: @"\t\t<icon>%ld</icon>\n", mIconID];
	NSString*	textAlignment = @"left";
	if( mTextAlignment == NSCenterTextAlignment )
		textAlignment = @"center";
	if( mTextAlignment == NSRightTextAlignment )
		textAlignment = @"right";
	[outString appendFormat: @"\t\t<textAlign>%@</textAlign>\n", textAlignment];
	[outString appendFormat: @"\t\t<font>%@</font>\n", mTextFontName];
	[outString appendFormat: @"\t\t<textSize>%d</textSize>\n", mTextFontSize];
	for( NSString* styleName in mTextStyles )
		[outString appendFormat: @"\t\t<textStyle>%@</textStyle>\n", styleName];
	
	NSMutableString*	nameStr = WILDStringEscapedForXML(mName);
	[outString appendFormat: @"\t\t<name>%@</name>\n", nameStr];
	
	NSMutableString*	scriptStr = WILDStringEscapedForXML(mScript);
	[outString appendFormat: @"\t\t<script>%@</script>\n", scriptStr];
	
	[outString appendString: @"\t</part>\n"];
	
	return outString;
}

@end
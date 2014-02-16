//
//  WILDStackWindowController.mm
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#include "WILDStackWindowController.h"
#include "CStackMac.h"
#include "CCard.h"
#include "CBackground.h"
#include "CDocument.h"
#include "CMacPartBase.h"
#include "CAlert.h"
#import "WILDCustomWidgetWindow.h"
#import "ULIHighlightingButton.h"
#import "WILDCardInfoViewController.h"
#import "WILDBackgroundInfoViewController.h"


NSString*	WILDStackToolbarItemIdentifier = @"WILDStackToolbarItemIdentifier";
NSString*	WILDCardToolbarItemIdentifier = @"WILDCardToolbarItemIdentifier";
NSString*	WILDBackgroundToolbarItemIdentifier = @"WILDBackgroundToolbarItemIdentifier";
NSString*	WILDEditBackgroundToolbarItemIdentifier = @"WILDEditBackgroundToolbarItemIdentifier";

NSString*	WILDPrevCardToolbarItemIdentifier = @"WILDPrevCardToolbarItemIdentifier";
NSString*	WILDNextCardToolbarItemIdentifier = @"WILDNextCardToolbarItemIdentifier";


static void FillFirstFreeOne( const char ** a, const char ** b, const char ** c, const char ** d, const char* theAppendee )
{
	if( *a == nil )
		*a = theAppendee;
	else if( *b == nil )
		*b = theAppendee;
	else if( *c == nil )
		*c = theAppendee;
	else if( *d == nil )
		*d = theAppendee;
}


using namespace Carlson;


@interface WILDStackWindowController () <NSPopoverDelegate,NSToolbarDelegate>

@end


@implementation WILDFlippedContentView

@synthesize stack = mStack;
@synthesize owningStackWindowController = mOwningStackWindowController;

-(BOOL)	isFlipped
{
	return YES;
}


-(NSView *)	hitTest: (NSPoint)aPoint
{
	NSView	*	hitView = [super hitTest: aPoint];
	bool	isEditing = mStack ? mStack->GetTool() != EBrowseTool : false;
	bool	isPeeking = mStack ? mStack->GetPeeking() : false;
	if( (isEditing || isPeeking) && hitView != nil )
		return self;
	return hitView;
}


-(void)	mouseDown: (NSEvent*)theEvt
{
	bool	isEditing = mStack->GetTool() != EBrowseTool;
	bool	isPeeking = mStack->GetPeeking();
	CScriptableObject	*hitObject = NULL;
	CCard	*	theCard = mStack->GetCurrentCard();
	const char*	dragMessage = NULL, *upMessage = NULL, *doubleUpMessage = NULL;
	if( isEditing || isPeeking )
	{
		NSPoint		hitPos = [self convertPoint: [theEvt locationInWindow] fromView: nil];
		bool		shiftKeyDown = [theEvt modifierFlags] & NSShiftKeyMask;
		size_t		numParts = 0;
		CPart*		hitPart = NULL;
		
		if( !mStack->GetEditingBackground() )
		{
			numParts = theCard->GetNumParts();
			for( size_t x = numParts; x > 0; x-- )
			{
				CPart	*	thePart = theCard->GetPart( x-1 );
				if( !hitPart && hitPos.x > thePart->GetLeft() && hitPos.x < thePart->GetRight()
					&& hitPos.y > thePart->GetTop() && hitPos.y < thePart->GetBottom() )
				{
					hitPart = thePart;
				}
			}
		}
		
		numParts = theCard->GetBackground()->GetNumParts();
		for( size_t x = numParts; x > 0; x-- )
		{
			CPart	*	thePart = theCard->GetBackground()->GetPart( x-1 );
			if( !hitPart && hitPos.x > thePart->GetLeft() && hitPos.x < thePart->GetRight()
				&& hitPos.y > thePart->GetTop() && hitPos.y < thePart->GetBottom() )
			{
				hitPart = thePart;
			}
		}
		
		if( !mStack->GetEditingBackground() )
		{
			numParts = theCard->GetNumParts();
			for( size_t x = numParts; x > 0; x-- )
			{
				CPart	*	thePart = theCard->GetPart( x-1 );
				if( thePart != hitPart )
				{
					if( !hitPart || (!shiftKeyDown && !hitPart->IsSelected()) )
						thePart->SetSelected(false);
				}
			}
		}
		
		const char*	mouseDownMessage = NULL;
		const char*	mouseDoubleDownMessage = NULL;
		
		if( isPeeking )
		{
			mouseDownMessage = "mouseDownWhilePeeking";
			mouseDoubleDownMessage = "mouseDoubleDownWhilePeeking";
			dragMessage = "mouseDragWhilePeeking";
			upMessage = "mouseUpWhilePeeking";
			doubleUpMessage = "mouseDoubleClickWhilePeeking";
		}
		else if( isEditing )
		{
			mouseDownMessage = "mouseDownWhileEditing";
			mouseDoubleDownMessage = "mouseDoubleDownWhileEditing";
			dragMessage = "mouseDragWhileEditing";
			upMessage = "mouseUpWhileEditing";
			doubleUpMessage = "mouseDoubleClickWhileEditing";
		
			numParts = theCard->GetBackground()->GetNumParts();
			for( size_t x = numParts; x > 0; x-- )
			{
				CPart	*	thePart = theCard->GetBackground()->GetPart( x-1 );
				if( thePart != hitPart )
				{
					if( !hitPart || (!shiftKeyDown && !hitPart->IsSelected()) )
						thePart->SetSelected(false);
				}
			}
		}
		
		if( !hitPart )
		{
			CAutoreleasePool	cppPool;
			theCard->SendMessage(NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, ([theEvt clickCount] % 2)?mouseDownMessage:mouseDoubleDownMessage );
			hitObject = theCard;
		}
		else
		{
			if( isEditing && !isPeeking )
			{
				if( !hitPart->IsSelected() )
					hitPart->SetSelected(true);
				else if( hitPart->IsSelected() && shiftKeyDown )
					hitPart->SetSelected(false);
			}
			CAutoreleasePool	cppPool;
			hitPart->SendMessage(NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, ([theEvt clickCount] % 2)?mouseDownMessage:mouseDoubleDownMessage );
			hitObject = hitPart;
		}
		
		[mOwningStackWindowController drawBoundingBoxes];
	}
	else
	{
		[self.window makeFirstResponder: self];
		hitObject = theCard;
		
		dragMessage = "mouseDrag";
		upMessage = "mouseUp";
		doubleUpMessage = "mouseDoubleClick";
		
		theCard->SendMessage(NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, ([theEvt clickCount] % 2)?"mouseDown":"mouseDoubleDown" );
	}

	NSAutoreleasePool	*	pool = [NSAutoreleasePool new];
	BOOL					keepGoing = YES;
	while( keepGoing )
	{
		NSEvent	*	loopEvt = [[NSApplication sharedApplication] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask untilDate: [NSDate distantFuture] inMode: NSEventTrackingRunLoopMode dequeue: YES];
		if( theEvt )
		{
			switch( loopEvt.type )
			{
				case NSLeftMouseUp:
					keepGoing = NO;
					break;
				case NSLeftMouseDragged:
				{
					CAutoreleasePool	cppPool;
					hitObject->SendMessage(NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, dragMessage );
					break;
				}
			}
			
			[pool release];
			pool = [NSAutoreleasePool new];
		}
		
		if( ([NSEvent pressedMouseButtons] & 1) == 0 )
			keepGoing = NO;
	}
	[pool release];

	CAutoreleasePool	cppPool;
	hitObject->SendMessage(NULL, [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); }, ([theEvt clickCount] % 2)?upMessage:doubleUpMessage );
}


- (BOOL)acceptsFirstResponder
{
	return YES;
}


- (BOOL)becomeFirstResponder
{
	return YES;
}


- (BOOL)resignFirstResponder
{
	return YES;
}


-(void)        keyDown: (NSEvent *)theEvent
{
	CCard *				theCard = mStack->GetCurrentCard();
	const char *        firstModifier = nil;
	const char *        secondModifier = nil;
	const char *        thirdModifier = nil;
	const char *        fourthModifier = nil;
	
	if( theEvent.modifierFlags & NSShiftKeyMask )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "shift" );
	else if( theEvent.modifierFlags & NSAlphaShiftKeyMask )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "shiftlock" );
	if( theEvent.modifierFlags & NSAlternateKeyMask )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "alternate" );
	if( theEvent.modifierFlags & NSControlKeyMask )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "control" );
	if( theEvent.modifierFlags & NSCommandKeyMask )
		FillFirstFreeOne( &firstModifier, &secondModifier, &thirdModifier, &fourthModifier, "command" );
	
	if( !firstModifier ) firstModifier = "";
	if( !secondModifier ) secondModifier = "";
	if( !thirdModifier ) thirdModifier = "";
	if( !fourthModifier ) fourthModifier = "";
	
	std::function<void(const char *, size_t, size_t, CScriptableObject *)>	errHandler = [](const char *errMsg, size_t inLine, size_t inOffs, CScriptableObject *obj){ CAlert::RunScriptErrorAlert( obj, errMsg, inLine, inOffs ); };
	
	theCard->SendMessage( NULL, errHandler, "keyDown %s,%s,%s,%s,%s", [[theEvent characters] UTF8String], firstModifier, secondModifier, thirdModifier, fourthModifier );

	if( theEvent.charactersIgnoringModifiers.length > 0 )
	{
		unichar theKey = [theEvent.charactersIgnoringModifiers characterAtIndex: 0];
		switch( theKey )
		{
			case '\t':
				theCard->SendMessage( NULL, errHandler, "tabKey %s,%s,%s,%s", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
			case 0x0019:	// Back tab
				theCard->SendMessage( NULL, errHandler, "tabKey %s,%s,%s,%s", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
				
			case NSLeftArrowFunctionKey:
				theCard->SendMessage( NULL, errHandler, "arrowKey %s,%s,%s,%s,%s", "left", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
			case NSRightArrowFunctionKey:
				theCard->SendMessage( NULL, errHandler, "arrowKey %s,%s,%s,%s,%s", "right", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
			case NSUpArrowFunctionKey:
				theCard->SendMessage( NULL, errHandler, "arrowKey %s,%s,%s,%s,%s", "up", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
			case NSDownArrowFunctionKey:
				theCard->SendMessage( NULL, errHandler, "arrowKey %s,%s,%s,%s,%s", "down", firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
			case NSF1FunctionKey ... NSF35FunctionKey:
				theCard->SendMessage( NULL, errHandler, "functionKey %d,%s,%s,%s,%s", (int)(theKey -NSF1FunctionKey +1), firstModifier, secondModifier, thirdModifier, fourthModifier );
				break;
		}
	}
}


//-(void)	resetCursorRects
//{
//	NSCursor	*	currentCursor = nil;
//	if( !currentCursor )
//	{
//		int			hotSpotLeft = 0, hotSpotTop = 0;
//		std::string	cursorURL = mStack->GetDocument()->GetMediaURLByIDOfType( 128, EMediaTypeCursor, &hotSpotLeft, &hotSpotTop );
//		if( cursorURL.length() > 0 )
//		{
//			NSImage	*			cursorImage = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: cursorURL.c_str()]]] autorelease];
//			NSCursor *			cursorInstance = [[NSCursor alloc] initWithImage: cursorImage hotSpot: NSMakePoint(hotSpotLeft,hotSpotTop)];
//			currentCursor = cursorInstance;
//		}
//	}
//	if( !currentCursor )
//		currentCursor = [NSCursor arrowCursor];
//	[self addCursorRect: [self bounds] cursor: currentCursor];
//}

@end


@implementation WILDStackWindowController

-(id)	initWithCppStack: (CStackMac*)inStack
{
	self = [super initWithWindowNibName: @""];
	if( self )
	{
		mStack = inStack;
	}
	
	return self;
}


-(void)	dealloc
{
	[mSelectionOverlay release];
	mSelectionOverlay = nil;
	[mPopover release];
	mPopover = nil;
	[mContentView release];
	mContentView = nil;
	
	[super dealloc];
}


-(void)	loadWindow
{
	[self updateStyle];
}

-(void)	removeAllViews
{
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;
	
	size_t	numParts = theCard->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theCard->GetPart(x));
		if( !currPart )
			continue;
		currPart->DestroyView();
	}

	CBackground	*	theBg = theCard->GetBackground();
	numParts = theBg->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theBg->GetPart(x));
		if( !currPart )
			continue;
		currPart->DestroyView();
	}
	
	[mSelectionOverlay removeFromSuperlayer];
	[mSelectionOverlay release];
	mSelectionOverlay = nil;
}


-(void)	createAllViews
{
	[mBackgroundImageView removeFromSuperview];
	[mBackgroundImageView release];
	mBackgroundImageView = nil;
	[mCardImageView removeFromSuperview];
	[mCardImageView release];
	mCardImageView = nil;
	
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;
	
	if( !mContentView )
	{
		mContentView = [[WILDFlippedContentView alloc] initWithFrame: NSMakeRect(0, 0, mStack->GetCardWidth(), mStack->GetCardHeight())];
		mContentView.stack = mStack;
		mContentView.owningStackWindowController = self;
		mContentView.wantsLayer = YES;
		[mContentView setLayerUsesCoreImageFilters: YES];
	}
	else
	{
		NSRect		box = [mContentView frame];
		box.size = NSMakeSize(mStack->GetCardWidth(), mStack->GetCardHeight() );
		[mContentView setFrame: box];
	}
	
	CBackground	*	theBackground = theCard->GetBackground();
	std::string		bgPictureURL( theBackground->GetPictureURL() );
	if( theBackground->GetShowPicture() && bgPictureURL.length() > 0 )
	{
		mBackgroundImageView = [[NSImageView alloc] initWithFrame: NSMakeRect(0,0,mStack->GetCardWidth(), mStack->GetCardHeight())];
		[mBackgroundImageView setWantsLayer: YES];
		mBackgroundImageView.image = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: bgPictureURL.c_str()]]] autorelease];
		[mContentView addSubview: mBackgroundImageView];
	}
	
	size_t	numParts = theBackground->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theBackground->GetPart(x));
		if( !currPart )
			continue;
		currPart->CreateViewIn( mContentView );
	}

	if( !theCard->GetStack()->GetEditingBackground() )
	{
		numParts = theCard->GetNumParts();
		std::string		cdPictureURL( theCard->GetPictureURL() );
		if( theCard->GetShowPicture() && cdPictureURL.length() > 0 )
		{
			mCardImageView = [[NSImageView alloc] initWithFrame: NSMakeRect(0,0,mStack->GetCardWidth(), mStack->GetCardHeight())];
			[mCardImageView setWantsLayer: YES];
			mCardImageView.image = [[[NSImage alloc] initByReferencingURL: [NSURL URLWithString: [NSString stringWithUTF8String: cdPictureURL.c_str()]]] autorelease];
			[mContentView addSubview: mCardImageView];
		}
		for( size_t x = 0; x < numParts; x++ )
		{
			CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theCard->GetPart(x));
			if( !currPart )
				continue;
			currPart->CreateViewIn( mContentView );
		}
	}
	
	[self drawBoundingBoxes];
}


-(void)	refreshExistenceAndOrderOfAllViews
{
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;
	
	size_t	numParts = theCard->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theCard->GetPart(x));
		if( !currPart )
			continue;
		currPart->CreateViewIn( mContentView );
	}

	CBackground	*	theBg = theCard->GetBackground();
	numParts = theBg->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CMacPartBase*	currPart = dynamic_cast<CMacPartBase*>(theBg->GetPart(x));
		if( !currPart )
			continue;
		currPart->CreateViewIn( mContentView );
	}
}


-(void)	drawBoundingBoxes
{
	[mSelectionOverlay removeFromSuperlayer];
	[mSelectionOverlay release];
	mSelectionOverlay = nil;
	
	CCard	*	theCard = mStack->GetCurrentCard();
	if( !theCard )
		return;
	
	CGColorSpaceRef	colorSpace = CGColorSpaceCreateWithName( kCGColorSpaceGenericRGB );
	CGContextRef	bmContext = CGBitmapContextCreate( NULL, mStack->GetCardWidth(), mStack->GetCardHeight(), 8, mStack->GetCardWidth() * 8 * 4, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little );
	CGColorSpaceRelease(colorSpace);
	NSGraphicsContext	*	cocoaContext = [NSGraphicsContext graphicsContextWithGraphicsPort: bmContext flipped: NO];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext: cocoaContext];
	
	static NSColor	*	sPeekColor = nil;
	if( !sPeekColor )
		sPeekColor = [[NSColor colorWithPatternImage: [NSImage imageNamed: @"PAT_22"]] retain];
	static NSColor	*	sSelectedColor = nil;
	if( !sSelectedColor )
		sSelectedColor = [[NSColor colorWithCalibratedRed: 0.102 green: 0.180 blue: 0.998 alpha: 1.000] retain];
	
	size_t		cardHeight = mStack->GetCardHeight();
	
	CBackground	*	theBackground = theCard->GetBackground();
	size_t	numParts = theBackground->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CPart*	currPart = theBackground->GetPart(x);
		if( currPart->IsSelected() )
		{
			NSRect		partRect = NSMakeRect(currPart->GetLeft() +0.5, cardHeight -currPart->GetBottom() +0.5, currPart->GetRight() -currPart->GetLeft() -1.0, currPart->GetBottom() -currPart->GetTop() -1.0 );
			NSRectFillUsingOperation( partRect, NSCompositeClear );
			[sSelectedColor set];
			NSRect		grabby = partRect;
			grabby.size.width = 8;
			grabby.size.height = 8;
			NSRectFill(grabby);
			grabby.origin.y = NSMaxY(partRect) -8;
			NSRectFill(grabby);
			grabby.origin.x = NSMaxX(partRect) -8;
			NSRectFill(grabby);
			grabby.origin.y = NSMinY(partRect);
			NSRectFill(grabby);
		}
		else if( mStack->GetPeeking() )
		{
			NSRect	partRect = NSMakeRect(currPart->GetLeft() +0.5, cardHeight -currPart->GetBottom() +0.5, currPart->GetRight() -currPart->GetLeft() -1.0, currPart->GetBottom() -currPart->GetTop() -1.0 );
			NSRectFillUsingOperation( partRect, NSCompositeClear );
			[sPeekColor set];
			[NSBezierPath strokeRect: partRect];
		}
	}

	numParts = theCard->GetNumParts();
	for( size_t x = 0; x < numParts; x++ )
	{
		CPart*	currPart = theCard->GetPart(x);
		if( currPart->IsSelected() )
		{
			NSRect		partRect = NSMakeRect(currPart->GetLeft() +0.5, cardHeight -currPart->GetBottom() +0.5, currPart->GetRight() -currPart->GetLeft() -1.0, currPart->GetBottom() -currPart->GetTop() -1.0 );
			NSRectFillUsingOperation( partRect, NSCompositeClear );
			[sSelectedColor set];
			NSRect		grabby = partRect;
			grabby.size.width = 8;
			grabby.size.height = 8;
			NSRectFill(grabby);
			grabby.origin.y = NSMaxY(partRect) -8;
			NSRectFill(grabby);
			grabby.origin.x = NSMaxX(partRect) -8;
			NSRectFill(grabby);
			grabby.origin.y = NSMinY(partRect);
			NSRectFill(grabby);
		}
		else if( mStack->GetPeeking() )
		{
			NSRect	partRect = NSMakeRect(currPart->GetLeft() +0.5, cardHeight -currPart->GetBottom() +0.5, currPart->GetRight() -currPart->GetLeft() -1.0, currPart->GetBottom() -currPart->GetTop() -1.0 );
			NSRectFillUsingOperation( partRect, NSCompositeClear );
			[sPeekColor set];
			[NSBezierPath strokeRect: partRect];
		}
	}

	if( !mSelectionOverlay )
		mSelectionOverlay = [[CALayer alloc] init];
	[[mContentView layer] addSublayer: mSelectionOverlay];
	[mSelectionOverlay setFrame: [mContentView layer].frame];
	
	[NSGraphicsContext restoreGraphicsState];
	CGImageRef	bmImage = CGBitmapContextCreateImage( bmContext );
	mSelectionOverlay.contents = [(id)bmImage autorelease];
	
	CFRelease(bmContext);
}


-(void)	updateStyle
{
	NSRect			wdBox = NSMakeRect(0,0,mStack->GetCardWidth(),mStack->GetCardHeight());
	NSWindow	*	prevWindow = nil;
	if( mWasVisible && !mPopover )
	{
		prevWindow = [self.window retain];
		wdBox = [prevWindow contentRectForFrameRect: prevWindow.frame];
	}
	
	TStackStyle		theStyle = mStack->GetStyle();
	switch( theStyle )
	{
		case EStackStyleStandard:
			self.window = [[[WILDCustomWidgetWindow alloc] initWithContentRect: wdBox styleMask: NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease];
			[self.window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
			break;
		
		case EStackStyleRectangle:
			self.window = [[[NSWindow alloc] initWithContentRect: wdBox styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease];
			[self.window setStyleMask: NSBorderlessWindowMask];
			[self.window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenAuxiliary];
			break;
		
		case EStackStylePalette:
			self.window = [[[NSPanel alloc] initWithContentRect: wdBox styleMask: NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSUtilityWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease];
			[self.window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenAuxiliary];
			[(NSPanel*)self.window setFloatingPanel: YES];
			break;
		
		case EStackStylePopup:
			self.window = [[[NSWindow alloc] initWithContentRect: NSMakeRect(wdBox.origin.x,wdBox.origin.y,10,10) styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease];
			[self.window setBackgroundColor: NSColor.redColor];
			//[self.window setLevel: NSFloatingWindowLevel];
			[self.window setAlphaValue: 0.0];
			break;
	}
	
	if( !mContentView )
	{
		NSRect		box = { NSZeroPoint, { (CGFloat)mStack->GetCardWidth(), (CGFloat)mStack->GetCardHeight() } };
		mContentView = [[WILDFlippedContentView alloc] initWithFrame: box];
		mContentView.stack = mStack;
		mContentView.owningStackWindowController = self;
		mContentView.wantsLayer = YES;
		[mContentView setLayerUsesCoreImageFilters: YES];
	}
	if( theStyle == EStackStylePopup )
	{
		mPopover = [[NSPopover alloc] init];
		mPopover.delegate = self;
		mPopover.contentSize = wdBox.size;
		NSViewController*	nsvc = [[[NSViewController alloc] init] autorelease];
		nsvc.view = mContentView;
		mPopover.contentViewController = nsvc;
	}
	else
	{
		self.window.contentView = mContentView;
		[self.window setTitle: [NSString stringWithUTF8String: mStack->GetName().c_str()]];
		[self.window setRepresentedURL: [NSURL URLWithString: [NSString stringWithUTF8String: mStack->GetURL().c_str()]]];
	}
	NSDisableScreenUpdates();
	if( !prevWindow )
		[self.window center];
	[self.window setDelegate: self];
	if( mWasVisible )
		[self.window orderFront: self];
	if( theStyle == EStackStylePopup )
	{
		[mPopover showRelativeToRect: NSMakeRect(0,0,10,10) ofView: self.window.contentView preferredEdge: NSMaxYEdge];
	}
	else
	{
		[mPopover close];
		[mPopover release];
		mPopover = nil;
	}
	[prevWindow release];
	NSEnableScreenUpdates();
}


-(void)	updateToolbarVisibility
{
	if( mStack->GetTool() != EBrowseTool )
	{
		NSToolbar	*editToolbar = [[[NSToolbar alloc] initWithIdentifier: @"WILDEditToolbar"] autorelease];
		[editToolbar setDelegate: self];
		[editToolbar setAllowsUserCustomization: NO];
		[editToolbar setVisible: NO];
		[self.window setToolbar: editToolbar];
		[self.window toggleToolbarShown: self];
	}
	else
	{
		[self.window toggleToolbarShown: self];
		[self.window setToolbar: nil];
		if( mStack->GetEditingBackground() )
			mStack->SetEditingBackground( false );	// Switch back to foreground.
	}
}


-(void)	showWindow: (id)sender
{
	[super showWindow: sender];
	if( mStack->GetStyle() == EStackStylePopup )
	{
		[mPopover showRelativeToRect: NSMakeRect(0,0,10,10) ofView: self.window.contentView preferredEdge: NSMaxYEdge];
	}
	mWasVisible = YES;
}


-(void)	showWindowOverPart: (CPart*)overPart
{
	[super showWindow: nil];
	if( mStack->GetStyle() == EStackStylePopup )
	{
		CMacPartBase	*	thePart = dynamic_cast<CMacPartBase*>(overPart);
		NSView			*	theView = thePart ? thePart->GetView() : self.window.contentView;
		[mPopover setBehavior: NSPopoverBehaviorTransient];
		[mPopover showRelativeToRect: theView.bounds ofView: theView preferredEdge: NSMaxYEdge];
	}
	mWasVisible = YES;
}


-(Carlson::CStackMac*)	cppStack
{
	return mStack;
}


-(void)	saveDocument: (id)sender
{
	mStack->GetDocument()->Save();
}


-(void)	windowDidBecomeKey: (NSNotification *)notification
{
	CStack::SetFrontStack( mStack );
	mWasVisible = YES;
	
	if( mStack->GetStyle() == EStackStylePopup )
	{
		[mPopover showRelativeToRect: NSMakeRect(0,0,10,10) ofView: self.window.contentView preferredEdge: NSMaxYEdge];
	}
}


-(void)	windowDidBecomeMain: (NSNotification *)notification
{
	CStack::SetFrontStack( mStack );
	mWasVisible = YES;
	
	if( mStack->GetStyle() == EStackStylePopup )
	{
		[mPopover showRelativeToRect: NSMakeRect(0,0,10,10) ofView: self.window.contentView preferredEdge: NSMaxYEdge];
	}
}


-(void)	windowWillClose: (NSNotification *)notification
{
	mWasVisible = NO;
}


-(void)	customWidgetWindowEditButtonClicked: (NSButton*)sender
{
	mStack->SetTool( ([sender state] == NSOnState) ? EPointerTool : EBrowseTool );
}


-(void)	popoverWillShow: (NSNotification *)notification
{
	if( notification.object == mPopover )
		;
}


-(void)	popoverDidShow: (NSNotification *)notification
{
	if( notification.object == mPopover )
	{
		CStack::SetFrontStack( mStack );
		mWasVisible = YES;
	}
}


-(void)	popoverWillClose: (NSNotification *)notification
{
	if( notification.object == mPopover )
	{
		mWasVisible = NO;
	}
}


-(IBAction)	showCardInfoPanel: (id)sender
{
	if( mCurrentPopover )
		[mCurrentPopover close];
	
	WILDCardInfoViewController*	cardInfo = [[[WILDCardInfoViewController alloc] initWithCard: mStack->GetCurrentCard()] autorelease];
	mCurrentPopover = [[NSPopover alloc] init];
	[mCurrentPopover setBehavior: NSPopoverBehaviorTransient];
	[mCurrentPopover setDelegate: self];
	[mCurrentPopover setContentViewController: cardInfo];
	[mCurrentPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMinYEdge];
}

-(IBAction)	showBackgroundInfoPanel: (id)sender
{
	if( mCurrentPopover )
		[mCurrentPopover close];
	
	WILDBackgroundInfoViewController*	backgroundInfo = [[[WILDBackgroundInfoViewController alloc] initWithBackground: mStack->GetCurrentCard()->GetBackground()] autorelease];
	mCurrentPopover = [[NSPopover alloc] init];
	[mCurrentPopover setBehavior: NSPopoverBehaviorTransient];
	[mCurrentPopover setDelegate: self];
	[mCurrentPopover setContentViewController: backgroundInfo];
	[mCurrentPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMinYEdge];
}

-(IBAction)	showStackInfoPanel: (id)sender
{
//	if( mCurrentPopover )
//		[mCurrentPopover close];
//	
//	WILDStackInfoViewController*	stackInfo = [[[WILDStackInfoViewController alloc] initWithStack: [mCurrentCard stack] ofCardView: (WILDCardView*) [self view]] autorelease];
//	mCurrentPopover = [[NSPopover alloc] init];
//	[mCurrentPopover setBehavior: NSPopoverBehaviorTransient];
//	[mCurrentPopover setDelegate: self];
//	[mCurrentPopover setContentViewController: stackInfo];
//	[mCurrentPopover showRelativeToRect: [sender bounds] ofView: sender preferredEdge: NSMinYEdge];
}


-(IBAction)	toggleBackgroundEditMode: (id)sender
{
	mStack->SetEditingBackground( !mStack->GetEditingBackground() );
}


-(IBAction)	goFirstCard: (id)sender
{
	mStack->GetCard(0)->GoThereInNewWindow( EOpenInSameWindow, mStack, NULL );
}


-(IBAction)	goPrevCard: (id)sender
{
	mStack->GetPreviousCard()->GoThereInNewWindow( EOpenInSameWindow, mStack, NULL );
}


-(IBAction)	goNextCard: (id)sender
{
	mStack->GetNextCard()->GoThereInNewWindow( EOpenInSameWindow, mStack, NULL );
}


-(IBAction)	goLastCard: (id)sender
{
	mStack->GetCard(mStack->GetNumCards() -1)->GoThereInNewWindow( EOpenInSameWindow, mStack, NULL );
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem	*	theItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
	
	if( [itemIdentifier isEqualToString: WILDCardToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[ULIHighlightingButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"CardIcon"]];
		[theButton setAction: @selector(showCardInfoPanel:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Card Info"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theButton.cell setButtonType: NSMomentaryChangeButton];
		[theItem setView: theButton];
	}
	else if( [itemIdentifier isEqualToString: WILDBackgroundToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[ULIHighlightingButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"BackgroundIcon"]];
		[theButton setAction: @selector(showBackgroundInfoPanel:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Background Info"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theButton.cell setButtonType: NSMomentaryChangeButton];
		[theItem setView: theButton];
	}
	else if( [itemIdentifier isEqualToString: WILDEditBackgroundToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[ULIHighlightingButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"BackgroundEditIcon"]];
		[theButton setAction: @selector(toggleBackgroundEditMode:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Edit Background"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theButton.cell setButtonType: NSMomentaryChangeButton];
		[theItem setView: theButton];
	}
	else if( [itemIdentifier isEqualToString: WILDStackToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[ULIHighlightingButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"StackIcon"]];
		[theButton setAction: @selector(showStackInfoPanel:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Stack Info"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theButton.cell setButtonType: NSMomentaryChangeButton];
		[theItem setView: theButton];
	}
	else if( [itemIdentifier isEqualToString: WILDPrevCardToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[ULIHighlightingButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"ICON_902"]];
		[theButton setAction: @selector(goPrevCard:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Previous Card"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theButton.cell setButtonType: NSMomentaryChangeButton];
		[theItem setView: theButton];
	}
	else if( [itemIdentifier isEqualToString: WILDNextCardToolbarItemIdentifier] )
	{
		NSButton	*	theButton = [[[ULIHighlightingButton alloc] initWithFrame: NSMakeRect(0,0,32,32)] autorelease];
		[theButton setBordered: NO];
		[theButton setImage: [NSImage imageNamed: @"ICON_26425"]];
		[theButton setAction: @selector(goNextCard:)];
		[theButton setImagePosition: NSImageOnly];
		[theItem setLabel: @"Next Card"];
		[theButton setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[theButton.cell setControlSize: NSSmallControlSize];
		[theButton.cell setImageScaling: NSImageScaleProportionallyUpOrDown];
		[theButton.cell setButtonType: NSMomentaryChangeButton];
		[theItem setView: theButton];
	}
	
	return theItem;
}
    
/* Returns the ordered list of items to be shown in the toolbar by default.   If during initialization, no overriding values are found in the user defaults, or if the user chooses to revert to the default items this set will be used. */
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return @[ WILDStackToolbarItemIdentifier, WILDBackgroundToolbarItemIdentifier, WILDCardToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, WILDEditBackgroundToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, WILDPrevCardToolbarItemIdentifier, WILDNextCardToolbarItemIdentifier ];
}

/* Returns the list of all allowed items by identifier.  By default, the toolbar does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed.  The set of allowed items is used to construct the customization palette.  The order of items does not necessarily guarantee the order of appearance in the palette.  At minimum, you should return the default item list.*/
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return @[ WILDStackToolbarItemIdentifier, WILDBackgroundToolbarItemIdentifier, WILDCardToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, WILDPrevCardToolbarItemIdentifier, WILDNextCardToolbarItemIdentifier ];
}

@end

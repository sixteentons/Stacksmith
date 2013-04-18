//
//  WILDWebBrowserPresenter.m
//  Stacksmith
//
//  Created by Uli Kusterer on 21.08.11.
//  Copyright 2011 Uli Kusterer. All rights reserved.
//

#import "WILDWebBrowserPresenter.h"
#import "WILDPart.h"
#import "WILDPartView.h"
#import <WebKit/WebKit.h>
#import "WILDDocument.h"
#import "WILDStack.h"
#import "UKHelperMacros.h"
#import "WILDPartContents.h"


@implementation WILDWebBrowserPresenter

-(void)	createSubviews
{
	if( !mWebView )
	{
		WILDPart	*	currPart = [mPartView part];
		NSRect			partRect = [currPart rectangle];
		[mPartView setWantsLayer: YES];
		partRect.origin = NSMakePoint( 2, 2 );
		
		mWebView = [[WebView alloc] initWithFrame: partRect];
		[mWebView setWantsLayer: YES];
				
		[mWebView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
		[mPartView addSubview: mWebView];
	}
	
	[self refreshProperties];
}


-(void)	refreshProperties
{
	WILDPart		*	currPart = [mPartView part];
	WILDPartContents*	contents = nil;
	WILDPartContents*	bgContents = nil;
	
	contents = [mPartView currentPartContentsAndBackgroundContents: &bgContents create: NO];

	[mPartView setHidden: ![currPart visible]];
	
	NSColor	*	shadowColor = [currPart shadowColor];
	if( [shadowColor alphaComponent] > 0.0 )
	{
		CGColorRef theColor = [shadowColor CGColor];
		[[mWebView layer] setShadowColor: theColor];
		[[mWebView layer] setShadowOpacity: 1.0];
		[[mWebView layer] setShadowOffset: [currPart shadowOffset]];
		[[mWebView layer] setShadowRadius: [currPart shadowBlurRadius]];
	}
	else
		[[mWebView layer] setShadowOpacity: 0.0];
	
	if( currPart.currentURL )
	{
		NSURLRequest	*	theRequest = [NSURLRequest requestWithURL: currPart.currentURL];
		[mWebView.mainFrame loadRequest: theRequest];
	}
	else
	{
		NSString	*	theText = [contents text];
		if( !theText )
			theText = @"";
		[mWebView.mainFrame loadHTMLString: theText baseURL: currPart.stack.document.fileURL];
	}
}


-(void)	textPropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	currentURLPropertyDidChangeOfPart: (WILDPart*)inPart
{
	[self refreshProperties];
}


-(void)	removeSubviews
{
	[mWebView removeFromSuperview];
	DESTROY(mWebView);
}


-(NSRect)	selectionFrame
{
	return [[mPartView superview] convertRect: [mWebView bounds] fromView: mWebView];
}

@end
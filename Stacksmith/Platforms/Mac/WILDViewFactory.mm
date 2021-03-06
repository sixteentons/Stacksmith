//
//  WILDViewFactory.m
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#import "WILDViewFactory.h"
#import "WILDButtonView.h"
#import "WILDTextView.h"
#import "WILDTableView.h"
#import "WILDScrollView.h"


static WILDViewFactory*		sViewFactory = nil;

@interface WILDViewFactory ()

@property (assign,nonatomic) IBOutlet NSButton* systemButton;
@property (assign,nonatomic) IBOutlet WILDButtonView* shapeButton;
@property (assign,nonatomic) IBOutlet WILDScrollView* textViewInContainer;
@property (assign,nonatomic) IBOutlet NSPopUpButton* popUpButton;
@property (assign,nonatomic) IBOutlet WILDScrollView* tableViewInContainer;

@end


@implementation WILDViewFactory

+(WILDViewFactory*)	sharedViewFactory
{
	if( !sViewFactory )
	{
		sViewFactory = [[WILDViewFactory alloc] initWithNibName: @"WILDViewFactory" bundle: nil];
		[sViewFactory view];
	}
	return sViewFactory;
}


+(id)	anotherInstanceOfView: (NSView*)inView
{
	return [NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: inView]];
}


+(WILDButtonView*)	systemButton
{
	return [self anotherInstanceOfView: [[self sharedViewFactory] systemButton]];
}


+(WILDButtonView*)	shapeButton
{
	return [self anotherInstanceOfView: [[self sharedViewFactory] shapeButton]];
}


+(WILDTextView*)		textViewInContainer
{
	WILDScrollView	*	scroller = [self anotherInstanceOfView: [[self sharedViewFactory] textViewInContainer]];
	return scroller.documentView;
}


+(NSPopUpButton*)	popUpButton
{
	return [self anotherInstanceOfView: [[self sharedViewFactory] popUpButton]];
}

+(WILDTableView*)	tableViewInContainer
{
	WILDScrollView	*	scroller = [self anotherInstanceOfView: [[self sharedViewFactory] tableViewInContainer]];
	return scroller.documentView;
}

@end

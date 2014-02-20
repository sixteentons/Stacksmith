//
//  CFieldPart.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CFieldPart__
#define __Stacksmith__CFieldPart__

#include "CVisiblePart.h"
#include <set>

namespace Carlson {


class CAttributedString;

typedef enum
{
	EFieldStyleTransparent,
	EFieldStyleOpaque,
	EFieldStyleRectangle,
	EFieldStyleShadow,
	EFieldStyleScrolling,
	EFieldStyleStandard,
	EFieldStylePopUp,
	EFieldStyle_Last
} TFieldStyle;


class CFieldPart : public CVisiblePart
{
public:
	explicit CFieldPart( CLayer *inOwner ) : CVisiblePart( inOwner ), mViewTextNeedsSync(false), mFieldStyle(EFieldStyleStandard), mDontWrap(false), mDontSearch(false), mSharedText(false), mFixedLineHeight(false), mAutoTab(false), mLockText(false), mAutoSelect(false), mMultipleLines(false), mShowLines(false), mWideMargins(false), mTextStyle(EPartTextStylePlain), mTextAlign(EPartTextAlignDefault), mTextSize(12), mTextHeight(0), mHasHorizontalScroller(false), mHasVerticalScroller(false)	 {};
	
	virtual bool			GetPropertyNamed( const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd, LEOContext* inContext, LEOValuePtr outValue );
	virtual bool			SetValueForPropertyNamed( LEOValuePtr inValue, LEOContext* inContext, const char* inPropertyName, size_t byteRangeStart, size_t byteRangeEnd );
	virtual void			SetViewTextNeedsSync( bool inNeeded )	{ mViewTextNeedsSync = inNeeded; };

	virtual bool			GetTextContents( std::string &outString );
	virtual bool			SetTextContents( const std::string &inString );

	virtual void			ClearSelectedLines()				{ mSelectedLines.clear(); IncrementChangeCount(); };
	virtual void			AddSelectedLine( size_t inLine )	{ mSelectedLines.insert(inLine); IncrementChangeCount(); };
	
	virtual bool			GetLockText()						{ return mLockText; };
	virtual void			SetLockText( bool inST )			{ mLockText = inST; };
	
	TFieldStyle				GetStyle()							{ return mFieldStyle; };
	virtual void			SetStyle( TFieldStyle s )			{ mFieldStyle = s; IncrementChangeCount(); };
	
	virtual bool			GetSharedText()					{ return mSharedText; };
	virtual void			SetSharedText( bool inST )		{ mSharedText = inST; IncrementChangeCount(); };
	
	virtual bool			GetAutoSelect()					{ return mAutoSelect; };
	virtual void			SetAutoSelect( bool inST )		{ mAutoSelect = inST; IncrementChangeCount(); };
	virtual bool			GetCanSelectMultipleLines()				{ return mMultipleLines; };
	virtual void			SetCanSelectMultipleLines( bool inST )	{ mMultipleLines = inST; IncrementChangeCount(); };
	
	virtual void			SetHasHorizontalScroller( bool inHS )	{ mHasHorizontalScroller = inHS; IncrementChangeCount(); };
	bool					GetHasHorizontalScroller()				{ return mHasHorizontalScroller; };
	virtual void			SetHasVerticalScroller( bool inHS )		{ mHasVerticalScroller = inHS; IncrementChangeCount(); };
	bool					GetHasVerticalScroller()				{ return mHasVerticalScroller; };

	virtual bool			GetDontWrap()					{ return mDontWrap; };
	virtual void			SetDontWrap( bool inST )		{ mDontWrap = inST; IncrementChangeCount(); };

	virtual bool			GetDontSearch()					{ return mDontSearch; };
	virtual void			SetDontSearch( bool inST )		{ mDontSearch = inST; IncrementChangeCount(); };
	
protected:
	~CFieldPart()	{};
	
	virtual void			LoadPropertiesFromElement( tinyxml2::XMLElement * inElement );
	virtual void			SavePropertiesToElementOfDocument( tinyxml2::XMLElement * inElement, tinyxml2::XMLDocument * inDocument );
	
	virtual void			LoadChangedTextStylesIntoView()			{ mViewTextNeedsSync = false; };
	virtual void			LoadChangedTextFromView()				{};
	virtual void			ApplyChangedSelectedLinesToView()		{};
	
	virtual const char*		GetIdentityForDump()	{ return "Field"; };
	virtual void			DumpProperties( size_t inIndent );

	static void				ApplyStyleStringToRangeOfAttributedString( const char* currStyleName, size_t byteRangeStart, size_t byteRangeEnd, CAttributedString& attrStr );
	static TFieldStyle		GetFieldStyleFromString( const char* inStyleStr );
	
protected:
	bool			mDontWrap;
	bool			mDontSearch;
	bool			mSharedText;
	bool			mFixedLineHeight;
	bool			mAutoTab;
	bool			mLockText;
	bool			mAutoSelect;
	bool			mMultipleLines;
	bool			mShowLines;
	bool			mWideMargins;
	TPartTextStyle	mTextStyle;
	TPartTextAlign	mTextAlign;
	std::string		mFont;
	int				mTextSize;
	int				mTextHeight;
	bool			mHasHorizontalScroller;
	bool			mHasVerticalScroller;
	bool			mViewTextNeedsSync;		// Did the text in the view change and we haven't updated the part contents yet?
	TFieldStyle		mFieldStyle;
	std::set<size_t>mSelectedLines;
};

}

#endif /* defined(__Stacksmith__CFieldPart__) */

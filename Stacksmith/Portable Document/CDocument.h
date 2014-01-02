//
//  CDocument.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-02.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CDocument__
#define __Stacksmith__CDocument__

#include "LEOContextGroup.h"
#include "CStack.h"
#include "CVisiblePart.h"


namespace Calhoun {

enum EMediaType
{
	CMediaTypeUnknown = 0,
	CMediaTypeIcon,
	CMediaTypePicture,
	CMediaTypeCursor,
	CMediaTypeSound
};
typedef enum EMediaType CMediaType;


class CMediaEntry
{
public:
	CMediaEntry() : mIconID(0), mMediaType(CMediaTypeUnknown), mHotspotLeft(0), mHotspotTop(0), mIsBuiltIn(false) {};
	CMediaEntry( int iconID, const std::string iconName, const std::string fileName, CMediaType mediaType, int hotspotLeft, int hotspotTop, bool isBuiltIn ) : mIconID(iconID), mIconName(iconName), mFileName(fileName), mMediaType(mediaType), mHotspotLeft(hotspotLeft), mHotspotTop(hotspotTop), mIsBuiltIn(isBuiltIn) {};
	
	void	Dump( size_t inIndentLevel = 0 )	{ const char* indentStr = CRefCountedObject::IndentString( inIndentLevel ); printf("%s{ id = %d, name = %s, file = %s, type = %u, hotspot = %d,%d, builtIn = %s }\n", indentStr, mIconID, mIconName.c_str(), mFileName.c_str(), mMediaType, mHotspotLeft, mHotspotTop, (mIsBuiltIn ? "true" : "false")); };
	
protected:
	int				mIconID;
	std::string		mIconName;
	std::string		mFileName;
	CMediaType		mMediaType;
	int				mHotspotLeft;
	int				mHotspotTop;
	bool			mIsBuiltIn;
};


class CTextStyleEntry
{
public:
	CTextStyleEntry() : mFontSize(12), mTextStyle(CPartTextStylePlain) {};
	CTextStyleEntry( std::string inFontName, int inFontSize, CPartTextStyle inTextStyle ) : mFontName(inFontName), mFontSize(inFontSize), mTextStyle(inTextStyle) {};

	void	Dump( size_t inIndentLevel = 0 )	{ const char* indentStr = CRefCountedObject::IndentString( inIndentLevel ); printf("%s{ font = %s, size = %d, style = %u }\n", indentStr, mFontName.c_str(), mFontSize, mTextStyle); };

protected:
	std::string		mFontName;
	int				mFontSize;
	CPartTextStyle	mTextStyle;
};


class CDocument
{
public:
	static void		SetStandardResourcesPath( const std::string& inStdResPath );

	CDocument() : mLoaded(false), mLoading(false) {};
	virtual ~CDocument();
	
	void				LoadFromURL( const std::string inURL, std::function<void(CDocument*)> inCompletionBlock );
	
	CStack*				GetStack( size_t inIndex )	{ if( inIndex >= mStacks.size() ) return NULL; return mStacks[inIndex]; };
	
	LEOContextGroup*	GetScriptContextGroupObject();
	
	virtual void		Dump();

protected:
	void				LoadMediaTableFromElementAsBuiltIn( tinyxml2::XMLElement * root, bool isBuiltIn );

	bool											mLoaded;
	bool											mLoading;
	std::string										mCreatedByVersion;
	std::string										mLastCompactedVersion;
	std::string										mFirstEditedVersion;
	std::string										mLastEditedVersion;
	std::map<int,std::string>						mFontIDTable;
	std::map<int,CTextStyleEntry>					mTextStyles;
	std::vector<CMediaEntry>						mMediaList;
	std::vector<CStackRef>							mStacks;
	std::vector<std::function<void(CDocument*)>>	mLoadCompletionBlocks;
	
	LEOContextGroup*								mContextGroup;
};

}

#endif /* defined(__Stacksmith__CDocument__) */
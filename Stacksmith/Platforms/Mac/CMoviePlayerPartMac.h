//
//  CMoviePlayerPartMac.h
//  Stacksmith
//
//  Created by Uli Kusterer on 2014-01-13.
//  Copyright (c) 2014 Uli Kusterer. All rights reserved.
//

#ifndef __Stacksmith__CMoviePlayerPartMac__
#define __Stacksmith__CMoviePlayerPartMac__


#include "CMoviePlayerPart.h"
#include "CMacPartBase.h"


@class ULIInvisiblePlayerView;


namespace Carlson {


class CMoviePlayerPartMac : public CMoviePlayerPart, public CMacPartBase
{
public:
	CMoviePlayerPartMac( CLayer *inOwner ) : CMoviePlayerPart( inOwner ), mView(nil) {};

	virtual void	CreateViewIn( NSView* inSuperView );
	virtual void	DestroyView();
	virtual void	SetPeeking( bool inState );

	virtual void		SetStarted( bool inStart );
	virtual void		SetMediaPath( const std::string& inPath );
	virtual void		SetCurrentTime( LEOInteger inTicks );
	virtual LEOInteger	GetCurrentTime();
	virtual void		SetControllerVisible( bool inStart );
	virtual void		SetRect( LEOInteger left, LEOInteger top, LEOInteger right, LEOInteger bottom );
	virtual void	SetVisible( bool visible )		{ CMoviePlayerPart::SetVisible(visible); [mView setHidden: !visible]; };

protected:
	~CMoviePlayerPartMac()	{ DestroyView(); };
	
	void			SetUpMoviePlayer();
	void			SetUpMoviePlayerControls();
	
	ULIInvisiblePlayerView	*	mView;
};


}

#endif /* defined(__Stacksmith__CMoviePlayerPartMac__) */

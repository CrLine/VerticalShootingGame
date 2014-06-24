//
//  HelloWorldLayer.h
//  VerticalShootingGame
//
//  Created by 李涛 on 10/8/13.
//  Copyright 李涛 2013年. All rights reserved.
//


#import <GameKit/GameKit.h>

#import "Cocos2D.h"


@interface HelloWorldLayer : CCLayer
{
    CCArray *_enemySprites;
    CGPoint _playerVelocity;
    
    BOOL _isTouchToShoot;
    CCSprite *_bulletSprite;
    
    CCLabelTTF *_lifeLabel;
    CCLabelTTF *_scoreLabel;
    int     _totalLives;
    int     _totalScore;
    
    CCLabelTTF *_gameEndLabel;
}


+(CCScene *) scene;

@end

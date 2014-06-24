//
//  HelloWorldLayer.m
//  VerticalShootingGame
//
//  Created by 李涛 on 10/8/13.
//  Copyright 李涛 2013年. All rights reserved.
//



#import "HelloWorldLayer.h"


#import "AppDelegate.h"
#import "SimpleAudioEngine.h"

#pragma mark - HelloWorldLayer

enum  {
    kTagPalyer = 1,
};

@interface HelloWorldLayer()
-(void) spawnEnemy;
-(CCSprite*) getAvailableEnemySprite;
-(void) updatePlayerPosition:(ccTime)dt;
-(void) updatePlayerShooting:(ccTime)dt;
-(void) bulletFinishedMoving:(id)sender;
-(void) collisionDetection:(ccTime)dt;
-(CGRect) rectOfSprite:(CCSprite*)sprite;
-(void) updateHUD:(ccTime)dt;
-(void) onRestartGame;
@end


@implementation HelloWorldLayer


+(CCScene *) scene
{
    CCScene *scene = [CCScene node];
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
    [scene addChild: layer];
	return scene;
}


-(id) init
{

	if( (self=[super init]) ) {

		CGSize winSize = [[CCDirector sharedDirector] winSize];

        CCSprite *bgSprite = [CCSprite spriteWithFile:@"background_1.jpg"];
        bgSprite.position = ccp(winSize.width / 2,winSize.height/2);
        [self addChild:bgSprite z:0];
        
        CCSprite *playerSprite = [CCSprite spriteWithFile:@"hero_1.png"];
        playerSprite.position = CGPointMake(winSize.width / 2, playerSprite.contentSize.height/2 + 20);
        [self addChild:playerSprite z:4 tag:kTagPalyer];
        _enemySprites = [[CCArray alloc] init];
        
        const int NUM_OF_ENEMIES = 10;
        for (int i=0; i < NUM_OF_ENEMIES; ++i) {
            CCSprite *enemySprite = [CCSprite spriteWithFile:@"enemy1.png"];
            enemySprite.position = ccp(0,winSize.height + enemySprite.contentSize.height + 10);
            enemySprite.visible = NO;
            [self addChild:enemySprite z:4];
            [_enemySprites addObject:enemySprite];
        }
        
         [self performSelector:@selector(spawnEnemy)
                   withObject:nil
                   afterDelay:1.0f];
        
         self.isAccelerometerEnabled = YES;
        
         [self scheduleUpdate];
        
          self.isTouchEnabled = YES;
        _isTouchToShoot = NO;
        
         _bulletSprite = [CCSprite spriteWithFile:@"bullet1.png"];
        _bulletSprite.visible = NO;
        [self addChild:_bulletSprite z:4];
        

       // [[SimpleAudioEngine sharedEngine] preloadEffect:@"bullet.mp3"];
       // [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"game_music.mp3" loop:YES];
       // [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:0.5];
        
        CCLabelTTF *lifeIndicator = [CCLabelTTF labelWithString:@"生命值:" fontName:@"Arial" fontSize:20];
        lifeIndicator.anchorPoint = ccp(0.0,0.5);
        lifeIndicator.position = ccp(20,winSize.height - 20);
        [self addChild:lifeIndicator z:10];
        _lifeLabel = [CCLabelTTF labelWithString:@"3" fontName:@"Arial" fontSize:20];
        _lifeLabel.position = ccpAdd(lifeIndicator.position, ccp(lifeIndicator.contentSize.width+10,0));
        [self addChild:_lifeLabel z:10];
        
        
        CCLabelTTF *scoreIndicator = [CCLabelTTF labelWithString:@"分数：" fontName:@"Arial" fontSize:20];
        scoreIndicator.anchorPoint = ccp(0.0,0.5f);
        scoreIndicator.position = ccp(winSize.width - 100,winSize.height - 20);
        [self addChild:scoreIndicator z:10];
        _scoreLabel = [CCLabelTTF labelWithString:@"00" fontName:@"Arial" fontSize:20];
        _scoreLabel.position = ccpAdd(scoreIndicator.position, ccp(scoreIndicator.contentSize.width+ 10,0));
        [self addChild:_scoreLabel z:10];
        
        _totalLives = 3;
        _totalScore = 0;
        
        _gameEndLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:40];
        _gameEndLabel.position = ccp(winSize.width/2,winSize.height/2);
        _gameEndLabel.visible = NO;
        [self addChild:_gameEndLabel z:10];
        
        
	}
	return self;
}



-(void) updateHUD:(ccTime)dt{
    [_lifeLabel setString:[NSString stringWithFormat:@"%2d",_totalLives]];
    [_scoreLabel setString:[NSString stringWithFormat:@"%04d",_totalScore]];
}


- (void) dealloc
{

	[_enemySprites release];
    _enemySprites = nil;
	[super dealloc];
}

#pragma mark - accelerometer callback
-(void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration{
    float deceleration = 0.4f;
    float sensitivity = 6.0f;
    
    float maxVelocity = 100;
    
    _playerVelocity.x = _playerVelocity.x * deceleration + acceleration.x * sensitivity;
    if (_playerVelocity.x > maxVelocity) {
        _playerVelocity.x = maxVelocity;
    }else if(_playerVelocity.x < -maxVelocity){
        _playerVelocity.x = -maxVelocity;
    }
    
    
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    CCLOG(@"touch!");
    _isTouchToShoot = YES;
}

-(void) update:(ccTime)dt{
    [self updatePlayerPosition:dt];
    [self updatePlayerShooting:dt];
    [self collisionDetection:dt];
    [self updateHUD:dt];
}

-(void) updatePlayerShooting:(ccTime)dt{
    if (_bulletSprite.visible || !_isTouchToShoot) {
        return;
    }
    
    CCSprite *playerSprite = (CCSprite*)[self getChildByTag:kTagPalyer];
    CGPoint pos = playerSprite.position;
    
    CGPoint bulletPos = CGPointMake(pos.x,
                                    pos.y + playerSprite.contentSize.height/ 2 + _bulletSprite.contentSize.height);
    _bulletSprite.position = bulletPos;
    _bulletSprite.visible = YES;
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    id moveBy = [CCMoveBy actionWithDuration:1.0 position:ccp(0,winSize.height - bulletPos.y)];
    id callback = [CCCallFuncN actionWithTarget:self selector:@selector(bulletFinishedMoving:)];
    id ac = [CCSequence actions:moveBy,callback, nil];
    [_bulletSprite runAction:ac];
    
    //[[SimpleAudioEngine sharedEngine] playEffect:@"bullet.mp3"];
    CCLOG(@"_bulletSprite runAction");
}

-(CGRect) rectOfSprite:(CCSprite*)sprite{
    return CGRectMake(sprite.position.x - sprite.contentSize.width / 2,
                      sprite.position.y - sprite.contentSize.height /2,
                      sprite.contentSize.width, sprite.contentSize.height);
}

-(void) collisionDetection:(ccTime)dt{
    
    CCSprite *enemy;
    CGRect bulletRect = [self rectOfSprite:_bulletSprite];
    CCARRAY_FOREACH(_enemySprites, enemy)
    {
        if (enemy.visible) {
          CGRect enemyRect = [self rectOfSprite:enemy];
            if (_bulletSprite.visible && CGRectIntersectsRect(enemyRect, bulletRect)) {
                enemy.visible = NO;
                _bulletSprite.visible = NO;
                
                _totalScore += 100;
                
                if (_totalScore >= 1000) {
                    [_gameEndLabel setString:@"游戏胜利！"];
                    _gameEndLabel.visible = YES;
                    
                    id scaleTo = [CCScaleTo actionWithDuration:1.0 scale:1.2f];
                    [_gameEndLabel runAction:scaleTo];
                    
                    [self unscheduleUpdate];
                    [self performSelector:@selector(onRestartGame) withObject:nil afterDelay:2.0f];
                }
                
                [_bulletSprite stopAllActions];
                [enemy stopAllActions];
                CCLOG(@"collision bullet");
                break;
            }
            
          
            CCSprite *playerSprite = (CCSprite*)[self getChildByTag:kTagPalyer];
            CGRect playRect = [self rectOfSprite:playerSprite];
            if (playerSprite.visible &&
                playerSprite.numberOfRunningActions == 0
                && CGRectIntersectsRect(enemyRect, playRect)) {
                enemy.visible = NO;
                
                _totalLives -= 1;
                
                if (_totalLives <= 0) {
                    [_gameEndLabel setString:@"游戏失败!"];
                    _gameEndLabel.visible = YES;
                    id scaleTo = [CCScaleTo actionWithDuration:1.0 scale:1.2f];
                    [_gameEndLabel runAction:scaleTo];
                    
                    [self unscheduleUpdate];
                    [self performSelector:@selector(onRestartGame) withObject:nil afterDelay:3.0f];
                }
                
                id blink = [CCBlink actionWithDuration:2.0 blinks:4];
                [playerSprite stopAllActions];
                [playerSprite runAction:blink];
                CCLOG(@"collision player");
                break;
            }
        }
    }
}

-(void) onRestartGame{
    [[CCDirector sharedDirector] replaceScene:[HelloWorldLayer scene]];
}

-(void) bulletFinishedMoving:(id)sender{
    _bulletSprite.visible = NO;
}

-(void) updatePlayerPosition:(ccTime)dt{
    CCSprite *playerSprite = (CCSprite*)[self getChildByTag:kTagPalyer];
    CGPoint pos = playerSprite.position;
    pos.x += _playerVelocity.x;
    
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    float imageWidthHavled = playerSprite.texture.contentSize.width * 0.5f;
    float leftBoderLimit = imageWidthHavled;
    float rightBoderLimit = screenSize.width - imageWidthHavled;
    
    if (pos.x < leftBoderLimit) {
        pos.x = leftBoderLimit;
        _playerVelocity = CGPointZero;
    }else if(pos.x > rightBoderLimit){
        pos.x = rightBoderLimit;
        _playerVelocity = CGPointZero;
    }
    
    playerSprite.position = pos;
}



#pragma mark - private methods
-(void) spawnEnemy{
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CCSprite *enemySprite = [self getAvailableEnemySprite];
    
    enemySprite.visible = YES;
    enemySprite.position = ccp( arc4random() % (int)(winSize.width - enemySprite.contentSize.width) + enemySprite.contentSize.width/2 , winSize.height + enemySprite.contentSize.height + 10);
    
    
    float durationTime = arc4random() % 4 + 1;
    id moveBy = [CCMoveBy actionWithDuration:durationTime
                                    position:ccp(0,-enemySprite.position.y-enemySprite.contentSize.height)];
    id callback = [CCCallBlockN actionWithBlock:^(id sender)
                   {
                       CCSprite *sp = (CCSprite*)sender;
                       sp.visible = NO;
                       sp.position = ccp(0,winSize.height + sp.contentSize.height + 10);
                       CCLOG(@"reset enemy plane!");
                   }];
    id action = [CCSequence actions:moveBy,callback, nil];
    
    
    CCLOG(@"enemySprite x = %f, y = %f",enemySprite.position.x, enemySprite.position.y);
    [enemySprite runAction:action];
    
    
    [self performSelector:_cmd withObject:nil afterDelay:arc4random()%3 + 1];
    
}

-(CCSprite*) getAvailableEnemySprite{
    CCSprite *result = nil;
    CCARRAY_FOREACH(_enemySprites, result)
    {
        if (!result.visible) {
            break;
        }
    }
    return result;
}
@end

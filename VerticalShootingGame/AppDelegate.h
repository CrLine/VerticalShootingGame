//
//  AppDelegate.h
//  VerticalShootingGame
//
//  Created by 李涛 on 10/8/13.
//  Copyright 李涛 2013年. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

// Added only for iOS 6 support


@interface AppController : NSObject <UIApplicationDelegate,CCDirectorDelegate>
{
	UIWindow *window_;
	UINavigationController *navController_;

	CCDirectorIOS	*director_;							// weak ref
}

@property (nonatomic, retain) UIWindow *window;
@property (readonly) UINavigationController *navController;
@property (readonly) CCDirectorIOS *director;

@end

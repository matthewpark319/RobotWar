//
//  ScannerBot.m
//  RobotWar
//
//  Created by Grace Park on 7/1/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "ScannerBot.h"
#import "CCNode.h"

typedef NS_ENUM(NSInteger, RobotState) {
    RobotStateDefault,
    RobotStateTurnaround,
    RobotStateFiring,
    RobotStateFleeing,
};

@implementation ScannerBot{
    RobotState _currentRobotState;
    
    CGPoint _lastKnownPosition;
    CGFloat _lastKnownPositionTimestamp;
    CGFloat _lastHitTimestamp;
    CGFloat _lastHitEnemyTimestamp;
    CGSize _screenSize;
    BOOL _leftSide;
    int _screenWidth;
    int _screenHeight;
    int _health;
    int _opponentHealth;
}

- (void)declareVariables {
    _screenSize = [[CCDirector sharedDirector] viewSize];
    _screenHeight = _screenSize.height;
    _screenWidth = _screenSize.width;
    _currentRobotState = RobotStateDefault;
    _health = 20;
    _opponentHealth = 20;
    if (self.position.y == 50) {
        _leftSide = FALSE;
    } else if (self.position.y == _screenWidth - 50){
        _leftSide = TRUE;
    }
}

- (void)run {
    [self declareVariables];
    [self turnRobotRight:90];
    [self moveAhead: 150];
    while (TRUE) {
        // The default state is where the robot runs around in a square, searching for the opponent.
        if (_currentRobotState == RobotStateDefault) {
            [self moveInSquare];
        }
        if (_currentRobotState == RobotStateFleeing) {
            [self moveInSquare];
            while (abs(_lastHitEnemyTimestamp - [self currentTimestamp]) < 2.0) {
                if ([self distanceBetweenTwoPoints:self.position secondPoint:_lastKnownPosition] > 100) {
                    CGFloat angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:_lastKnownPosition];
                    if (angle >= 0)
                        [self turnGunRight:angle];
                    else
                        [self turnGunLeft: -angle];
                    [self shoot];
                }
            }
            _currentRobotState = RobotStateDefault;
        }
        if (_currentRobotState == RobotStateFiring) {
            CCLOG(@"Robot scanned");
            CGFloat angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:_lastKnownPosition];
            if (angle >= 0)
                [self turnGunRight: angle];
            else
                [self turnGunLeft: -angle];
            _currentRobotState = RobotStateDefault;
            [self shoot];
            if (self.currentTimestamp - _lastKnownPositionTimestamp > 3.0f) {
                _currentRobotState = RobotStateDefault;
            }
        }
    }
}

-(void)shootAtMidfield {
    float angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:CGPointMake(_screenWidth / 2, _screenHeight / 2)];
    if (angle >= 0)
        [self turnGunRight: angle];
    else
        [self turnGunLeft: -angle];
    [self shoot];
}

-(void)moveInSquare {
    CCLOG(@"RobotStateDefault");
    float distanceCornerOne = [self distanceBetweenTwoPoints:CGPointMake(0, 0) secondPoint:self.position];
    float distanceCornerTwo = [self distanceBetweenTwoPoints:CGPointMake(_screenWidth, 0) secondPoint:self.position];
    float distanceCornerThree = [self distanceBetweenTwoPoints:CGPointMake(0, _screenHeight) secondPoint:self.position];
    float distanceCornerFour = [self distanceBetweenTwoPoints:CGPointMake(_screenWidth, _screenHeight) secondPoint:self.position];
    if (distanceCornerOne < 150) {
        CCLOG(@"If statement reached 1");
        [self turnRobotLeft:90];
        while (distanceCornerTwo > 150){
            CCLOG(@"%.2f", distanceCornerTwo);
            [self moveAhead: 15];
            distanceCornerTwo = [self distanceBetweenTwoPoints:CGPointMake(_screenWidth, 0) secondPoint:self.position];
        }
        [self moveAhead:5];
        [self shootAtMidfield];
    } else if (distanceCornerTwo < 150) {
        CCLOG(@"If statement reached 2");
        [self turnRobotLeft:90];
        while (distanceCornerFour > 150){
            [self moveAhead: 15];
            distanceCornerFour = [self distanceBetweenTwoPoints:CGPointMake(_screenWidth, _screenHeight) secondPoint:self.position];
        }
        [self moveAhead:5];
        [self shootAtMidfield];
    } else if (distanceCornerFour < 150) {
        CCLOG(@"If statement reached 3");
        [self turnRobotLeft:90];
        while (distanceCornerThree > 150){
            CCLOG(@"%.2f", distanceCornerThree);
            [self moveAhead:15];
            distanceCornerThree = [self distanceBetweenTwoPoints:CGPointMake(0, _screenHeight) secondPoint:self.position];
        }
        [self moveAhead:5];
        [self shootAtMidfield];
    } else if (distanceCornerThree < 150) {
        CCLOG(@"If statement reached 4");
        [self turnRobotLeft:90];
        CCLOG(@"Turned robot 90 degrees");
        while (distanceCornerOne > 150){
            [self moveAhead:15];
            distanceCornerOne = [self distanceBetweenTwoPoints:CGPointMake(0, 0) secondPoint:self.position];
        }
        [self moveAhead:5];
        [self shootAtMidfield];
    } else {
        CCLOG(@"Moving ahead 10");
        [self moveAhead:15];
        [self shootAtMidfield];
    }
}

- (void)gotHit {
    _health--;
    _lastHitTimestamp = [self currentTimestamp];
    if (abs(_lastHitTimestamp - _lastHitEnemyTimestamp) < 2.0 && _health < _opponentHealth && [self distanceBetweenTwoPoints:self.position secondPoint:_lastKnownPosition] < 150) {
        _currentRobotState = RobotStateFleeing;
    }
}

- (float)distanceBetweenTwoPoints:(CGPoint)firstPoint secondPoint:(CGPoint)secondPoint {
    float xMinusXSquared = (firstPoint.x - secondPoint.x) * (firstPoint.x - secondPoint.x);
    float yMinusYSquared = (firstPoint.y - secondPoint.y) * (firstPoint.y - secondPoint.y);
    return sqrt(xMinusXSquared + yMinusYSquared);
}

- (void)bulletHitEnemy:(Bullet *)bullet {
    // There are a couple of neat things you could do in this handler
    _opponentHealth--;
    _lastHitEnemyTimestamp = [self currentTimestamp];
}

- (void)scannedRobot:(Robot *)robot atPosition:(CGPoint)position {
    if (_currentRobotState != RobotStateFleeing) {
        _lastKnownPosition = position;
        _currentRobotState = RobotStateFiring;
        _lastKnownPositionTimestamp = [self currentTimestamp];
    }
}

- (void)hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)angle {
    if (_currentRobotState != RobotStateTurnaround) {
        [self cancelActiveAction];
        
        RobotState previousState = _currentRobotState;
        _currentRobotState = RobotStateTurnaround;
        
        // always turn to head straight away from the wall
        if (angle >= 0) {
            [self turnRobotLeft:abs(angle)];
        } else {
            [self turnRobotRight:abs(angle)];
            
        }
        
        [self moveAhead:20];
        
        _currentRobotState = previousState;
    }
}

@end

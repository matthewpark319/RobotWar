#import "Opponent1.h"


typedef NS_ENUM(NSInteger, RobotState) {
    RobotStateMoving,
    RobotStateFighting
};





@implementation Opponent1 {
    
    RobotState _currentRobotState;
    
    CGPoint _lastEnemyPosition;
    CGFloat _lastEnemyPositionTimestamp;
    
    NSInteger _health;
    NSInteger _enemyHealth;
    
    BOOL _forward;
    BOOL _inAimingLoop;
}

- (void) run {
    _currentRobotState = RobotStateMoving;
    _forward = true;
    
    [self moveBack:15];
    [self turnRobotLeft:90];
    [self moveAhead:60];
    [self turnRobotRight:90];
    [self turnGunRight:90];
    
    while (true) {
        
        if (_currentRobotState == RobotStateMoving) {
            [self moveBasedOnStatus: 50];
        }
        
        if (_currentRobotState == RobotStateFighting) {
            CGFloat angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:_lastEnemyPosition];
            
            if (angle >= 0 && angle < 90) {
                [self turnGunRight:abs(angle)];
                [self shoot];
                [self moveBasedOnStatus:80];
            } else if (angle < 0 && angle > -90) {
                [self turnGunLeft:abs(angle)];
                [self shoot];
                [self moveBasedOnStatus:80];
            } else {
                while (angle > 90 || angle < -90) {
                    [self moveOppositeToStatus:20];
                    angle = [self angleBetweenGunHeadingDirectionAndWorldPosition:_lastEnemyPosition];
                }
                if (angle >= 0) {
                    [self turnGunRight:abs(angle)];
                } else if (angle < 0) {
                    [self turnGunLeft:abs(angle)];
                }
                [self shoot];
            }
        }
    }
}


- (void) scannedRobot:(Robot *)robot atPosition:(CGPoint)position {
    if (_currentRobotState != RobotStateFighting) {
        [self cancelActiveAction];
    }
    
    _lastEnemyPosition = position;
    _lastEnemyPositionTimestamp = self.currentTimestamp;
    _currentRobotState = RobotStateFighting;
}


- (void) hitWall:(RobotWallHitDirection)hitDirection hitAngle:(CGFloat)angle {
    [self cancelActiveAction];
    _forward = !_forward;
}


- (void) gotHit {
    
}


- (void) moveBasedOnStatus:(NSInteger)distanceToMove {
    if (_forward) {
        [self moveAhead:distanceToMove];
    } else {
        [self moveBack:distanceToMove];
    }
}


- (void) moveOppositeToStatus:(NSInteger)distanceToMove {
    if (_forward) {
        [self moveBack:distanceToMove];
    } else {
        [self moveAhead:distanceToMove];
    }
}



@end

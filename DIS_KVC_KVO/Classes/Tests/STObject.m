//
//  STObject.m
//  RunTestsOnIOS
//
//  Created by stone on 2021/3/15.
//  Copyright © 2021 JK. All rights reserved.
//

#import "STObject.h"
#import "NSObject+DSKeyValueObserverRegistration.h"

@interface STObserver : NSObject
@property (nonatomic, strong) NSString *name;
@end

@implementation STObserver


@end

@implementation STObject

static STObject *__object1;
static STObserver *_observer;

- (void)dealloc {
    [super dealloc];
    NSLog(@"STObject dealloc");
}


+ (void)test {
    __object1 = [[STObject alloc] init];
    STObserver *observer = [[STObserver alloc] init];
    [observer d_addObserver:__object1 forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
    __object1.name = @"123";
    _observer = observer;

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"观察回调开始～～～～～～～～～～～～～～～～～");
    NSLog(@"keyPath = %@", keyPath);
    NSLog(@"object = %@", object);
    NSLog(@"change = %@", change);
    NSLog(@"context = %@", context);
    NSLog(@"观察回调结束～～～～～～～～～～～～～～～～～");
}

@end

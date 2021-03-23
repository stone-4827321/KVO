//
//  STObject.m
//  KVO
//
//  Created by stone on 2021/2/2.
//

#import "Person.h"

@interface Person () 
@end
@implementation Person

- (void)dealloc {
    NSLog(@"Person dealloc %@", self);
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"testNotification" object:@"2"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
};

- (void)testNotification {
//    [[NSNotificationCenter defaultCenter] addObserverForName:@"testNotification" object:@"2" queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
//        NSLog(@"haha %@", self);
//    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:@"testNotification" object:@"2"];
}

- (void)notification:(id)note {
    NSLog(@"haha %@", note);

}






@end


@implementation Non_Autonotifying_Person
- (void)setName:(NSString *)name {
    [self willChangeValueForKey:@"name"];
    _name = name;
    [self didChangeValueForKey:@"name"];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"name"]) {
        return NO;
    }
    else {
        return [super automaticallyNotifiesObserversForKey:key];
    }
}
@end

@implementation Overrides_ObservationInfo_Person
- (void)setObservationInfo:(void *)observationInfo {
    _st_observationInfo = observationInfo;
}

- (void *)observationInfo {
    return _st_observationInfo;
}
@end

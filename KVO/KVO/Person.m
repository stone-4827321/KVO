//
//  STObject.m
//  KVO
//
//  Created by stone on 2021/2/2.
//

#import "Person.h"


@implementation Person

- (void)dealloc {
    NSLog(@"Person dealloc %@", self);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
};






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

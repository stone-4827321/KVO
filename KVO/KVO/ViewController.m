//
//  ViewController.m
//  KVO
//
//  Created by stone on 2021/2/2.
//

#import "ViewController.h"
#import "Person.h"
#import "STViewController.h"
#import "FBKVOController.h"
#import "NSObject+FBKVOController.h"
#import "CrashViewController.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *list;

@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;

@property (nonatomic, strong) NSString *name;
@property (nonatomic) NSInteger age;

@property (nonatomic, strong) Person *person;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)base:(id)sender {
    STViewController *vc = [[STViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - 容器观察

- (IBAction)observeList:(id)sender {
    self.list = [NSMutableArray array];
    
    [self addObserver:self forKeyPath:@"list" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
    
    [[self mutableArrayValueForKey:@"list"] addObject:@"1"];
    
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:0] forKey:@"list"];
    [self.list insertObject:@"2" atIndex:0];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:0] forKey:@"list"];
}

#pragma mark - 依赖观察

- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@ %@",_firstName,_lastName];
}

- (IBAction)observePath:(id)sender {
    self.firstName = @"wang";
    self.lastName = @"lei";
    NSLog(@"full name = %@", self.fullName);
    [self addObserver:self forKeyPath:@"fullName" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
    self.lastName = @"jin";
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    // 会调用keyPathsForValuesAffectingFullName方法
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"fullName"]) {
        NSArray *affectingKeys = @[@"firstName"];
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
    return keyPaths;
}

+ (NSSet *)keyPathsForValuesAffectingFullName {
    return [NSSet setWithObjects:@"lastName", nil];
}

#pragma mark - 自定义

//- (IBAction)custom:(id)sender {
//    self.name = @"wanglei";
//    [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
//    self.name = @"wangjin";
//}
//
//- (void)setName:(NSString *)name {
//    [self willChangeValueForKey:@"name"];
//    _name = name;
//    [self didChangeValueForKey:@"name"];
//}
//
//+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
//    if ([key isEqualToString:@"name"]) {
//        return NO;
//    }
//    else {
//        return [super automaticallyNotifiesObserversForKey:key];
//    }
//}

#pragma mark - Non-autonotifying & Unregistration Automatic
- (IBAction)custom_Non_Autonotifying:(id)sender {
    Non_Autonotifying_Person *p = [[Non_Autonotifying_Person alloc] init];
    p.name = @"Non_Autonotifying_Person_wanglei";
    [p addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
    p.name = @"Non_Autonotifying_Person_wangjin";
}

#pragma mark - Overrides observationInfo & Unregistration Automatic

- (IBAction)overrides_ObservationInfo_Person:(id)sender {
    Overrides_ObservationInfo_Person *p = [[Overrides_ObservationInfo_Person alloc] init];
    p.name = @"Overrides_ObservationInfo_Person_wanglei";
    [p addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
    p.name = @"Overrides_ObservationInfo_Person _wangjin";
}

#pragma mark - observationInfo

- (IBAction)observationInfo:(id)sender {
    self.person = [[Person alloc] init];
    [self.person addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
    NSLog(@"%@", self.person.observationInfo);

    id aInstance = (__bridge id)self.person.observationInfo;
    NSArray *list = [aInstance valueForKey:@"_observances"];
    for (id object in list) {
        id observer = [object valueForKey:@"_observer"];
        id property = [object valueForKey:@"_property"];
        NSString *keyPath = [property valueForKey:@"_keyPath"];
        NSLog(@"!!!%@ %@", observer, keyPath);
    }
}

- (IBAction)fb:(id)sender {
    

//被观察者提前释放
//    Person *observed = [[Person alloc] init];
//    observed.name = @"123";
//    FBKVOController *KVOController = [[FBKVOController alloc] initWithObserver:self];
//    self.KVOController = KVOController;
//    [KVOController observe:observed
//                   keyPath:@"name"
//                   options:NSKeyValueObservingOptionNew
//                     block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
//        NSLog(@"observer = %@", observer);
//        NSLog(@"object = %@", object);
//        NSLog(@"change = %@", change);
//    }];
//    //observed.name = @"123";
//    observed = nil;

//观察者提前释放
//    Person *observe = [[Person alloc] init];
//    FBKVOController *KVOController = [[FBKVOController alloc] initWithObserver:observe];
//    self.KVOController = KVOController;
//    [KVOController observe:self
//                   keyPath:@"name"
//                   options:NSKeyValueObservingOptionNew
//                     block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
//        NSLog(@"observer = %@", observer);
//        NSLog(@"object = %@", object);
//        NSLog(@"change = %@", change);
//    }];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        self.name = @"new";
//    });
    
    
    Person *observe = [[Person alloc] init];
    observe.name = @"stone";

    FBKVOController *KVOController = [[FBKVOController alloc] initWithObserver:self];
    [KVOController observe:observe
                   keyPath:@"name"
                   options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                     block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
        NSLog(@"observer = %@", observer);
        NSLog(@"object = %@", object);
        NSLog(@"change = %@", change);
    }];
    observe.name = @"yuan";
    [KVOController unobserve:observe keyPath:@"name"];
    observe.name = @"jin";
}

#pragma mark - 闪退

- (IBAction)crash:(id)sender {
    CrashViewController *vc = [[CrashViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - 观察回调

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"观察回调开始～～～～～～～～～～～～～～～～～");
    NSLog(@"keyPath = %@", keyPath);
    NSLog(@"object = %@", object);
    NSLog(@"change = %@", change);
    NSLog(@"context = %@", context);
    NSLog(@"观察回调结束～～～～～～～～～～～～～～～～～");
}

@end

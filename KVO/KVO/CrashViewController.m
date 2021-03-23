//
//  CrashViewController.m
//  KVO
//
//  Created by stone on 2021/3/11.
//

#import "CrashViewController.h"

@interface CrashObject : NSObject

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) CrashViewController *vc;


@end

@implementation CrashObject

- (void)dealloc {
    NSLog(@"CrashObject dealloc %@", self);
//    id aInstance = (__bridge id)self.observationInfo;
//    NSArray *list = [aInstance valueForKey:@"_observances"];
    NSLog(@"");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"！！！观察回调开始～～～～～～～～～～～～～～～～～");
    NSLog(@"keyPath = %@", keyPath);
    NSLog(@"object = %@", object);
    NSLog(@"change = %@", change);
    NSLog(@"context = %@", context);
    NSLog(@"观察回调结束～～～～～～～～～～～～～～～～～");
}

@end

@interface CrashViewController ()

@property (nonatomic, strong) NSString *age;

@end

@implementation CrashViewController

- (void)dealloc {
    NSLog(@"CrashViewController dealloc %@", self);
}

static CrashObject *__object;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    button1.frame = CGRectMake(100,100,200,50);
    [button1 setTitle:@"被观察者提前被释放" forState:UIControlStateNormal];
    button1.backgroundColor = [UIColor redColor];
    [self.view addSubview:button1];
    [button1 addTarget:self action:@selector(crash1) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    button2.frame = CGRectMake(100,200,200,50);
    [button2 setTitle:@"观察者提前释放" forState:UIControlStateNormal];
    button2.backgroundColor = [UIColor redColor];
    [self.view addSubview:button2];
    [button2 addTarget:self action:@selector(crash2) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeSystem];
    button3.frame = CGRectMake(100,300,200,50);
    [button3 setTitle:@"移除不存在的观察者" forState:UIControlStateNormal];
    button3.backgroundColor = [UIColor redColor];
    [self.view addSubview:button3];
    [button3 addTarget:self action:@selector(crash3) forControlEvents:UIControlEventTouchUpInside];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {

    [self dismissViewControllerAnimated:YES completion:nil];
}

//被观察者提前被释放
- (void)crash1 {
    CrashObject *object = [[CrashObject alloc] init];
    [object addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
    object = nil;
    //object.name = @"new";
    id aInstance = (__bridge id)self.observationInfo;
    NSArray *list = [aInstance valueForKey:@"_observances"];
    NSLog(@"");
    //[object removeObserver:self forKeyPath:@"name"];
}

// 观察者提前被释放
static CrashObject *__object2;
- (void)crash2 {
    CrashObject *object = [[CrashObject alloc] init];
    NSLog(@"object %@", object);
    self.age = @"old";
    [self addObserver:object forKeyPath:@"age" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
    
    id aInstance = (__bridge id)self.observationInfo;
    NSArray *list = [aInstance valueForKey:@"_observances"];
    NSLog(@"list: %@", list);
    
    self.age = @"new1";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id aInstance = (__bridge id)self.observationInfo;
        NSArray *list = [aInstance valueForKey:@"_observances"];
        NSLog(@"list: %@", list);
        
        self.age = @"new";
    });
    __object2 = object;
    __object2 = nil;
    //[self removeObserver:object forKeyPath:@"age"];
}

//移除不存在的观察者
static CrashObject *__object3;
- (void)crash3 {
    CrashObject *object = [[CrashObject alloc] init];
    object.name = @"old";
    [object addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
    object.name = @"new";
    [object removeObserver:self forKeyPath:@"name" context:@"context"];
    [object removeObserver:self forKeyPath:@"name" context:@"context"];
    __object3 = object;
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

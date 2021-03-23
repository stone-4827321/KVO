//
//  STViewController.m
//  KVO
//
//  Created by stone on 2021/2/2.
//

#import "STViewController.h"
#import "Person.h"
#import <objc/runtime.h>



@implementation Instance

+ (instancetype)instance {
    static Instance *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[Instance alloc] init];
    });
    return _manager;}

@end

@interface STViewController ()
@property (nonatomic, strong) Person *stone;
@property (nonatomic, strong) Person *stone1;

@end

@interface STObservance : NSObject {
@public
    id _observer;
    id _property;
    void *_context;
}
@end
@implementation STObservance
@end

@implementation STViewController

- (void)dealloc {
    id aInstance = (__bridge id)self.stone.observationInfo;
    NSArray *list = [aInstance valueForKey:@"_observances"];
    for (id object in list) {
//        id observer = [object valueForKey:@"_observer"];
//        id property = [object valueForKey:@"_property"];
//        //NSString *keyPath = [property valueForKey:@"_keyPath"];
//        NSString *keyPath = [object valueForKeyPath:@"_property._keyPath"];

        STObservance *o = (STObservance *)object;
        id observer = o->_observer;
        id property = o->_property;
        NSString *keyPath = [property valueForKey:@"_keyPath"];
        void *context = o->_context;
        
        [self.stone removeObserver:observer forKeyPath:keyPath context:context];

        
        NSLog(@"!!!%@ %@", observer, keyPath);
    }
    //[self.stone removeObserver:self forKeyPath:@"age"];
    NSLog(@"STViewController dealloc");    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor yellowColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(100,100,100,100);
    button.backgroundColor = [UIColor redColor];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    

    dispatch_queue_t queue = dispatch_queue_create("Queue1", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        self.stone = [[Person alloc] init];
        self.stone.age = 1;

        NSLog(@"添加监听之前类名：%@ %@ %@", [self.stone class], object_getClass(self.stone), class_getSuperclass(object_getClass(self.stone)));
        NSLog(@"添加监听之前是否存在NSKVONotifying_xxx类：%@", NSClassFromString(@"NSKVONotifying_Person"));
        SEL sel1 = @selector(setAge:);
        IMP imp1 = [self.stone methodForSelector:sel1];
        NSLog(@"添加监听之前地址：%p %p", self.stone, imp1);
        
        [self.stone addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
        
        NSLog(@"添加监听之后是否存在NSKVONotifying_xxx类：%@", NSClassFromString(@"NSKVONotifying_Person"));
        NSLog(@"添加监听之后类名：%@ %@ %@", [self.stone class], object_getClass(self.stone), class_getSuperclass(object_getClass(self.stone)));
        SEL sel2 = @selector(setAge:);
        IMP imp2 = [self.stone methodForSelector:sel2];
        NSLog(@"添加监听之后地址：%p %p", self.stone, imp2);
        [self printMethods:object_getClass(self.stone)];
        [self printProperty:[self class]];
        [self printIvar:[self class]];
        NSLog(@"");
    });
}

- (void)click {    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    dispatch_queue_t queue = dispatch_queue_create("Queue2", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        self.stone.age = 2;
        NSLog(@"观察回调结束后才会执行");
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"观察回调开始～～～～～～～～～～～～～～～～～");
    dispatch_queue_t currentQueue = NSOperationQueue.currentQueue.underlyingQueue;
    const char *label = dispatch_queue_get_label(currentQueue);
    NSLog(@"queue = %s", label);
    NSLog(@"keyPath = %@", keyPath);
    NSLog(@"object = %@", object);
    NSLog(@"change = %@", change);
    NSLog(@"context = %@", context);
    NSLog(@"观察回调结束～～～～～～～～～～～～～～～～～");
}

#pragma mark - 打印

- (void)printMethods:(Class)cls {
    unsigned int count ;
    Method *methods = class_copyMethodList(cls, &count);
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"%@ Methods - ", cls];
    
    for (int i = 0 ; i < count; i++) {
        Method method = methods[i];
        NSString *methodName  = NSStringFromSelector(method_getName(method));
        
        [string appendString: methodName];
        [string appendString:@" "];
        
    }
    
    NSLog(@"%@",string);
    free(methods);
}

- (void)printProperty:(Class)cls {
    unsigned int count ;
    objc_property_t *propertyList = class_copyPropertyList(cls, &count);
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"%@ Property- ", cls];
    
    for (int i = 0 ; i < count; i++) {
        objc_property_t property = propertyList[i];
        const char *name = property_getName(property);
        [string appendString:[NSString stringWithFormat:@"%s",name]];
        [string appendString:@" "];
    }
    NSLog(@"%@",string);
    free(propertyList);
}

- (void)printIvar:(Class)cls {
    unsigned int count ;
    Ivar *ivarList = class_copyIvarList(cls, &count);
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"%@ Ivar - ", cls];
    
    for (int i = 0 ; i < count; i++) {
        Ivar ivar = ivarList[i];
        const char *name = ivar_getName(ivar);
        [string appendString:[NSString stringWithFormat:@"%s",name]];
        [string appendString:@" "];
    }
    NSLog(@"%@",string);
    free(ivarList);
}
@end

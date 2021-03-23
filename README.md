# 概述

- KVO 的全称 Key-Value Observing，俗称“**键值观察**”，可以用于观察某个对象属性值的改变。

- KVO 是 Objective-C 对**观察者设计模式**的一种实现（另外一种是通知机制）。

- KVO 对被观察对象无侵入性，不需要修改其内部代码即可实现观察。

## 属性观察

- 注册观察者：

  ```objective-c
  /**
   注册观察者，由被观察者调用
   @param observer 观察者，接收回调函数
   @param keyPath 观察的属性
   @param options 选项，可用或多选
   @param context 上下文，传递参数
   */
  - (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;
  
  typedef NS_OPTIONS(NSUInteger, NSKeyValueObservingOptions) {
      NSKeyValueObservingOptionNew = 0x01,     //提供更改后的值
      NSKeyValueObservingOptionOld = 0x02,     //提供更改前的值
      NSKeyValueObservingOptionInitial = 0x04, //观察最初的值（在注册观察服务时会调用一次触发方法）
      NSKeyValueObservingOptionPrior = 0x08    //分别在值修改前后触发方法（即一次修改有两次触发）
  };
  ```

  - 可以多次注册观察者，即使观察者，被观察者，观察属性等参数都一致。越后注册的观察者，越早收到回调。

- 添加回调方法：

  ```objective-c
  /**
   观察回调
   @param keyPath 观察的属性
   @param object 被观察对象
   @param change 属性改变的值
   @param context 上下文
   */
  - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context;
  
  NSString *const NSKeyValueChangeKindKey; //变化类型，如值的设置1，集合插入2、删除3、替换4
  NSString *const NSKeyValueChangeNewKey; //变化后的值；
  NSString *const NSKeyValueChangeOldKey; //变化前的值；
  NSString *const NSKeyValueChangeIndexesKey; //集合变化的项的下标；
  NSString *const NSKeyValueChangeNotificationIsPriorKey //在值修改前后触发方法时标识第一次触发。
  ```

  - **NSNotification、KVO、Delegate 在哪个线程中触发（发出通知、修改被观察值、执行代理等），就在哪个线程中响应，而且都是同步的，即发送通知/注册观察等方法会阻塞当前线程，直到回调处理完成后才会执行触发之后的代码。**

  ```objective-c
  // 添加观察
  dispatch_queue_t queue = dispatch_queue_create("Queue1", DISPATCH_QUEUE_CONCURRENT);
  dispatch_async(queue, ^{
      Person *stone = [[Person alloc] init];
      stone.age = 1;
   		[stone addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
  });
  
  // 触发
  dispatch_queue_t queue = dispatch_queue_create("Queue2", DISPATCH_QUEUE_CONCURRENT);
  dispatch_async(queue, ^{
      stone.age = 2;
      NSLog(@"观察回调结束后才会执行");
  });
  
  // 观察回调
  - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
      NSLog(@"观察回调开始～～～～～～～～～～～～～～～～～");
      dispatch_queue_t currentQueue = NSOperationQueue.currentQueue.underlyingQueue;
      const char *label = dispatch_queue_get_label(currentQueue);
      NSLog(@"queue = %s", label);
      NSLog(@"change = %@", change);
      NSLog(@"观察回调结束～～～～～～～～～～～～～～～～～");
  }
  
  /* 输出
  观察回调开始～～～～～～～～～～～～～～～～～
  queue = Queue2 -> 说明是在触发线程回调
  change = {
      kind = 1;
      new = 2;
      old = 1;
  }
  观察回调结束～～～～～～～～～～～～～～～～～
  观察回调结束后才会执行 -> 说明是同步
  */
  ```

- 移除观察者：

  ```objective-c
  /**
   移除观察
   @param observer 观察者
   @param keyPath 观察的属性
   @param context 上下文
   */
  - (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context;
  ```

- 添加观察后，相关的信息包括观察者，属性名称等信息被封装为 `NSKeyValueObservance` 对象，存储在被观察者的 `observationInfo` 属性中。

  - 所有对象的所有观察信息都被存储在一个全局的字典里：`self -> NSKeyValueObservance *observationInfo ` 。

  ```objective-c
  static CFMutableDictionaryRef _NSKeyValueGlobalObservationInfo = NULL;
  
  - (void *)observationInfo {
      // 从全局字典中获取，key为self
      return (void *)CFDictionaryGetValue(_NSKeyValueGlobalObservationInfo, self);
  }
  
  - (void)setObservationInfo:(void *)observationInfo {
      // 存入全局字典中，key为self
      CFDictionarySetValue(_NSKeyValueGlobalObservationInfo, self, (CFTypeRef)realInfoPtr);
  }
  
  - (void)addObserver:(id)observer forKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options context:(void*)context {
      // 生成NSKeyValueObservance对象
      NSKeyValueObservance *newObservance = [[NSKeyValueObservance alloc] initWithObserver:observer forProperty:property ofObject:targetObject context:context options:options];
    	
    	NSKeyValueObservationInfo *observationInfo = [self observationInfo];
      [observationInfo addObservance:newObservance];
  }
  ```

  - 获取被观察者的观察信息。

  ```objective-c
  id observationInfo = (__bridge id)observed.observationInfo;
  NSArray *list = [observationInfo valueForKey:@"_observances"];
  for (id object in list) {
      id observer = [object valueForKey:@"_observer"];
      id property = [object valueForKey:@"_property"];
      NSString *keyPath = [property valueForKey:@"_keyPath"];
      NSLog(@"%@ %@", observer, keyPath);
  }
  
  // 以上方式无法获取context信息，如需自动移除，使用以下方案
  @interface STObservance : NSObject {
  @public
      id _observer;
      id _property;
      void *_context;
  }
  @end  
  - (void)dealloc {
      id aInstance = (__bridge id)self.observationInfo;
      NSArray *list = [aInstance valueForKey:@"_observances"];
      for (id object in list) {
          STObservance *o = (STObservance *)object;
          id observer = o->_observer;
          id property = o->_property;
          NSString *keyPath = [property valueForKey:@"_keyPath"];
          void *context = o->_context;
          
          [self removeObserver:observer forKeyPath:keyPath context:context];
      } 
  }  
  ```

  - 重新 setter 和 getter 方法进行管理，可以提高性能。（不能影响对象的引用计数）。

  ```objective-c
  static NSMutableDictionary *observationInfos=nil;
  
  - (void*)observationInfo {
    	// 存地址而不存对象，不会影响对象的引用计数
      return [[observationInfos objectForKey:[NSValue valueWithPointer:self]] pointerValue];
  }
  
  - (void)setObservationInfo:(void*)info {
      if(!observationInfos) observationInfos=[NSMutableDictionary new];
  	  [observationInfos setObject:[NSValue valueWithPointer:info] forKey:[NSValue valueWithPointer:self]];
  }
  ```

  > 源码： <https://github.com/apportable/Foundation/blob/master/System/Foundation/src/NSKeyValueObserving.m>

## 容器观察

- 如果属性是容器对象，对容器对象进行 `add` 或 `remove` 操作，则不会触发观察回调方法。可以通过 KVC 对应的方法来获取容器对象，使容器对象内部发生改变时也能触发回调。

  ```objective-c
  - (NSMutableArray *)mutableArrayValueForKey:(NSString *)key;
  - (NSMutableOrderedSet *)mutableOrderedSetValueForKey:(NSString *)key;
  - (NSMutableSet *)mutableSetValueForKey:(NSString *)key;
  ```

- 注册观察者：

  ```objective-c
  // 数组list是self的属性
  [self addObserver:self forKeyPath:@"list" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"context"];
  ```

- 修改属性

  - 方式一：使用 `mutableArrayValueForKey:` 获取数组：

  ```objective-c
  [[self mutableArrayValueForKey:@"list"] addObject:@"1"];
  ```

  - 方式二：调用 willChange 和 didChange 方法：

  ```objective-c
  [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:0] forKey:@"list"];
  [self.list insertObject:@"1" atIndex:0];
  [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:0] forKey:@"list"];
  ```

## 依赖观察

- 观察的属性依赖于其他属性，即其他依赖属性改变时，就会收到通知回调。

  ```objective-c
  // 观察属性fullName，该属性依赖于firstName和lastName属性
  [self addObserver:self forKeyPath:@"fullName" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:@"context"];
  ```

- 添加观察方法会调用 **`keyPathsForValuesAffectingValueForKey:`** 方法，该方法返回观察属性的依赖集合。同时，其内部会调用 `keyPathsForValuesAffecting<Key>`（`<Key>`为属性名，比如 fullName）。

  ![](https://tva1.sinaimg.cn/large/008eGmZEgy1gnaaklo41dj315c07u40w.jpg)

- 重写以上两个系统方法即可（至少实现其中任意一个）。

  ```objective-c
  + (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
      // keyPathsForValuesAffectingFullName方法返回的结果
      NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
      if ([key isEqualToString:@"fullName"]) {
          NSArray *affectingKeys = @[@"firstName"];
          // keyPathsForValuesAffectingFullName方法返回的集合 + 此处新加的集合
          keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
      }
      return keyPaths;
  }
  ```

  ```objective-c
  + (NSSet *)keyPathsForValuesAffectingFullName {
      return [NSSet setWithObjects:@"lastName", nil];
  }
  ```

# 原理

- KVO 是通过 **isa-swizzling** 技术实现的：

   - 当 A 类对象 a 成为被观察者后，KVO 机制动态创建一个新的名为 `NSKVONotifying_A` 的新类，该类继承自类 A。

   - A 类对象 a 的` isa` 指针指向 `NSKVONotifying_A` 类，这个被观察的对象变成了 `NSKVONotifying_A` 类的对象。 

     > `isa` 指针的作用：每个对象都有 `isa` 指针，指向该对象的类，它告诉 Runtime 系统这个对象的类是什么。

- `NSKVONotifying_A` 只有四个方法：

  - `dealloc`：重写该方法以对 `observationInfo` 进行处理。

  ```objective-c
  - (void)dealloc {
      DSKVODeallocate()
  }
  ```

  - ` _isKVOA`：标识该类是一个 KVO 机制产生的类。

  - `class`：重写该方法以隐藏本类的存在。

  ```objective-c
  - (Class)class {
      // 原实现，返回 NSKVONotifying_A
    	//object_getClass(self) 
      // 类对象的父类
      return class_getSuperclass(object_getClass(self));
  }
  ```

  - `setAge:`：重写该方法以实现通知所有观察对象属性值的更改情况。
  
    - `willChangeValueForKey:` 和 `didChangeValueForKey:` 方法。

  ```objective-c
  // 重写的setter方法变为_NSSetObjectValueAndNotify()方法
  - (void)setAge:(NSInteger)age {
      _NSSetLongLongValueAndNotify();
  }
  
  void _NSSetLongLongValueAndNotify() { 
      [self willChangeValueForKey:@"age"];    
      // 调用父类的存取方法 
      [super setValue:age forKey:@"age"]; 
      [self didChangeValueForKey:@"age"];
      //-> _NSSetLongLongValueAndNotify() -> NSKeyValueNotifyObserver () -> observeValueForKeyPath:ofObject:change:context:
  }
  ```

  ![](https://tva1.sinaimg.cn/large/008eGmZEgy1gnaalxabj4j31080kkwqe.jpg)

## 源码实现

- 添加观察

  - 根据被观察者和 keyPath 生成 `NSKeyValueProperty` 对象。

  ```objective-c
  - (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
      Class receiverRealClass = object_getClass(self);
      NSKeyValueProperty *kvProperty = _NSKeyValuePropertyForIsaAndKeyPath(receiverRealClass, keyPath);
      [self addObserver:observer forProperty:kvProperty options:options context:context];
  }
  ```

  - 将本次观察的信息存储在 `observationInfo` 对象中。

  ```objective-c
  - (void)addObserver:(NSObject *)observer forProperty:(NSKeyValueProperty *)property options:(NSKeyValueObservingOptions)options context:(void *)context {
      NSString *keyPath = property.keyPath;
    	// NSKeyValueObservingOptionInitial时立即发出一次通知
      if (options & NSKeyValueObservingOptionInitial) {
          id newValue = nil;
          if (options & NSKeyValueObservingOptionNew) {
              newValue = [self valueForKeyPath:keyPath];
          }
          NSKeyValueChangeDetails changeDetails = {0};
          changeDetails.kind = NSKeyValueChangeSetting;
          changeDetails.newValue = newValue;
          _NSKeyValueNotifyObserver(observer, self, nil, keyPath, changeDetails, context, NO);
      }
    
    	// 获取NSKeyValueObservationInfo对象
      NSKeyValueObservationInfo *observationInfo = __NSKeyValueRetainedObservationInfoForObject(self, property.containerClass); 
    
      // 生成NSKeyValueObservance对象
      NSKeyValueObservance *newObservance = [[NSKeyValueObservance alloc] initWithObserver:observer forProperty:property ofObject:targetObject context:context options:options];
      [observationInfo addObservance:newObservance];
      [self setObservationInfo:observationInfo];
    
      // 利用runtime机制生成NSKVONotifying_xx类，生成上述四个方法的实现
      Class autonotifyingClass = [property isaForAutonotifying];
      if (autonotifyingClass != Nil && object_getClass(self) != autonotifyingClass) {
        	//将self设置为NSKVONotifying_xx类型
          object_setClass(self, autonotifyingClass);
      }
      [observationInfo release];
  }
  ```

  - 特别需要注意的是：获取对象的 `observationInfo` 属性时，是以对象的指针作为 key，从一个全局字典中获取。由此，**观察信息是存储在一个全局字典中，而不是存储在对象本身**。

  ```objective-c
  static CFMutableDictionaryRef _NSKeyValueGlobalObservationInfo = NULL;
  - (void *)observationInfo {
      if (_NSKeyValueGlobalObservationInfo == NULL) {
          return nil;
      }
      return (void *)CFDictionaryGetValue(_NSKeyValueGlobalObservationInfo, self);
  }
  ```

- 执行观察回调：通过以下路径最终调用到回调函数。

  ```objective-c
  didChangeValueForKey: ->
  _NSKeyValueDidChange ->
  _NSKeyValueNotifyObserver ->
  observeValueForKeyPath:ofObject:change:context:
  ```

- 被观察者释放时，调用 `NSKVODeallocate` 方法。

  ```objective-c
  // 将dealloc方法替换为NSKVODeallocate方法
  NSKVONotifyingSetMethodImplementation(indexedIvars, @selector(dealloc), (IMP)&NSKVODeallocate, nil);
  
  static void NSKVODeallocate(id self, SEL _cmd) {
      NSKeyValueObservationInfo *observationInfo = [self observationInfo];
      NSArray *observances = [[observationInfo observances] retain];
      struct objc_super super = {self, class_getSuperclass(object_getClass(self))};
      const char *name = object_getClassName(self);
      // 执行dealloc方法
      (void)(void (*)(id, SEL))objc_msgSendSuper(&super, _cmd);
      if (observances.count > 0) {
          // iOS11以前会抛出异常
          NSKVODeallocateBreak(self, name);
      }
      [observances release];
  }
  ```

## 自定义实现

- 仍然需要注册观察者。

- 在属性修改前后，依次调用 **`willChangeValueForKey:`** 和 **`didChangeValueForKey:`**：

  ```objective-c
  - (void)setAge:(NSInteger)age {
      [self willChangeValueForKey:@"age"];
      _age = age;
      [self didChangeValueForKey:@"age"];
  }
  ```

- 重写 **`automaticallyNotifiesObserversForKey:`** 方法，设置对该 key 不自动发送通知：

  ```objective-c
  + (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
      if ([key isEqualToString:@"age"]) {
          return NO;
      }
      else {
          return [super automaticallyNotifiesObserversForKey:key];
      }
  }
  ```


## 异常

- 移除观察次数多于注册观察的次数，或移除了未注册的观察，或移除观察者已经销毁的观察：

  ```
  Cannot remove an observer <ObserverClass 0x15ce94e80> for the key path "keyPath" from <ObservedClass 0x15cf399a0> because it is not registered as an observer.
  ```

  - 产生原因：当调用移除观察方法时，如果检测到 `observationInfo` 为空，或 `observationInfo.observances` 数组中不存在对应的 `NSKeyValueObservance` 对象，则抛出异常。

- 注册观察后，观察者未实现 `observeValueForKeyPath:ofObject:change:context:` 方法：

  ```
  <ObservedClass: 0x7fe96c51ae60>: An -observeValueForKeyPath:ofObject:change:context: message was received but not handled.
  ```

  添加观察时 `keyPath == nil`，导致崩溃。（移除观察时 `keyPath == nil` 则属于移除未注册的观察情况）

  ```
  Thread 1: EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0)
  
  CFHash() called with NULL
  ```

  - 产生原因：对 `NSKVONotifying_A` 对象生成 `setKeyPath:` 方法时，调用了 `FSetAddValue(list, keyPath)`，由于对数组添加 nil 产生异常。

- 被观察者提前被释放，即被观察者销毁时还存在观察者：

  ```
  An instance 0x13f0d4fa0 of class ObservedClass was deallocated while key value observers were still registered with it
  ```

  - 产生原因：被观察对象的 `dealloc` 方法中检测到 `observationInfo` 不为空，则抛出异常。

  - 在 iOS11 及以上版本中，系统会自动在被观察对象的 `dealloc` 方法中移除仍存在的观察者信息。但需满足两个前提条件：

    - 使用系统的 KVO 机制，而不是自定义 KVO；
    
    - 被观察者的 `observationInfo` 没有被重写。

    > <https://fpotter.org/posts/when-is-kvo-unregistration-automatic>

- 观察者提前被释放，被观察者的观察属性发生变化：

  ```
  -[ObserverClass retain]: message sent to deallocated instance 0x6000003eb3e0
  ```

  - 产生原因：观察者释放后，`observationInfo` 中对其的引用指向了一个僵尸对象，向其发送消息触发了野指针异常。

- 使用 `NSNotificationCenter` 添加通知时可能导致的闪退：

  ```
  Thread 1: EXC_BAD_ACCESS (code=2, address=0x7fff8df43da0)
  ```

  - 在 iOS9 以下系统时，使用 `addObserver:selector:name:object:` 添加通知后，当观察者释放时未移除通知，系统发送通知时会触发野指针异常。因为通知中心对观察者是 `unsafe_unretained` 引用，但 iOS9 及以上系统，通知中心对观察者是 `weak` 引用，固无需在观察者释放时移除通知。
  
  - 使用 `addObserverForName:object:queue:usingBlock:` 添加通知时，block 会引用其中包含的对象，如果对象释放后发送了通知，会触发野指针异常。

# FBKVOController

- `FBKVOController` 解决的问题及系统 KVO 存在的问题：

  - 可能会对同一个被观察的属性多次添加观察，导致收到多次回调；
  
  - 当观察者对多个对象的不同属性进行观察，在回调方法中需要根据条件判断来响应不同属性的修改；
  - 上文提及的异常导致闪退。

- 使用示例：

  ```objective-c
  Person *observe = [[Person alloc] init];
  observe.name = @"stone";
  
  // 注册观察
  FBKVOController *KVOController = [[FBKVOController alloc] initWithObserver:self];
  [KVOController observe:observe //原来的被观察者 
   							 keyPath:@"name" 
   							 options:NSKeyValueObservingOptionNew 
   								 block:^(id observer, id object, NSDictionary<NSKeyValueChangeKey,id> *change) {
      // 观察回调
  }];
  observe.name = @"yuan";
  
  // 移除观察
  [KVOController unobserve:observe keyPath:@"name"];
  ```

- 类说明：
  - `FBKVOController`：对外公开的类，提供了初始化，注册属性观察的方法。
  
    - `@property (nullable, nonatomic, weak) id observer;`  —> 观察者
    
    - `NSMapTable<id, NSMutableSet<_FBKVOInfo *> > *_objectInfosMap;` —> 被观察对象对应 `_FBKVOInfo` 对象的字典（去重，防止重复添加观察）
    
    - `dealloc` 方法中实现自动移除观察。
    
  - `_FBKVOInfo`：内部类，没有任何业务逻辑，纯粹记录单次观察所需的参数信息，如观察属性，自定义回调或 `block` 等，内部实现 `isEqual:` 和 `hash` 方法用于字典去重。
  
    - `__weak FBKVOController *_controller;`
    
    - `NSString *_keyPath;` —> 观察属性
    
  - `_FBKVOSharedController`：内部类，单例，真正的观察者，在收到回调后进行分发。
  
    - `NSHashTable<_FBKVOInfo *> *_infos;`  —> 执行观察回调时获取 `_FBKVOInfo` 对象，进而获取相关参数进行转发

- 流程说明：

  - 添加观察：

  ```objective-c
  - (void)observe:(nullable id)object keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(FBKVONotificationBlock)block {
      // 1.根据观察的属性生成_FBKVOInfo对象，self为FBKVOController
      _FBKVOInfo *info = [[_FBKVOInfo alloc] initWithController:self keyPath:keyPath options:options block:block];
  
      // 2.每个观察者object对应一个Set集合，该set集合中对象为_FBKVOInfo对象
      // 针对obejct和keyPath两个属性去重，修复多次添加多次回调的问题
      [self _observe:object info:info];
  }
  
  - (void)_observe:(id)object info:(_FBKVOInfo *)info {
      // 调用到_FBKVOSharedController类中
      [[_FBKVOSharedController sharedController] observe:object info:info];
  }
  - (void)observe:(id)object info:(nullable _FBKVOInfo *)info {
    	// NSHashTable<_FBKVOInfo *> *_infos中添加info，因为观察回调中需要获取info
    	[_infos addObject:info];
    	// 真正实现监听，_FBKVOSharedController才是观察者，被观察者不变
    	[object addObserver:self forKeyPath:info->_keyPath options:info->_options context:(void *)info];
  }
  ```

  - 观察回调：

  ```objective-c
  // _FBKVOSharedController内部实现系统KVO方法
  - (void)observeValueForKeyPath:(nullable NSString *)keyPath
                        ofObject:(nullable id)object
                          change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change
                         context:(nullable void *)context {
      // 获取info，在添加观察的时候context传递的参数就是info
      _FBKVOInfo *info = [_infos member:(__bridge id)context];
      FBKVOController *controller = info->_controller;
      id observer = controller.observer;
      if (nil != observer) {
          // 转发观察回调
          [observer observeValueForKeyPath:keyPath ofObject:object change:change context:info->_context];
      }
  }
  ```

  - 移除观察：
  
    - 相对于系统方法，原来的被观察者还是被观察者，但被观察者还被 `FBKVOController` 对象持有，而 `FBKVOController` 对象释放时会移除观察，因此不会触发闪退。
    
    - 相对于系统方法，原来的观察者并未真正添加观察，因此释放后不会触发闪退。

  ```objective-c
  - (void)unobserve:(nullable id)object keyPath:(NSString *)keyPath {
      _FBKVOInfo *info = [[_FBKVOInfo alloc] initWithController:self keyPath:keyPath];
      [self _unobserve:object info:info];
  }
  
  - (void)_unobserve:(id)object info:(_FBKVOInfo *)info {
      _FBKVOInfo *registeredInfo = [infos member:info];
      [infos removeObject:registeredInfo];
    	// 调用到_FBKVOSharedController类中
      [[_FBKVOSharedController sharedController] unobserve:object info:registeredInfo];
  }
  
  - (void)unobserve:(id)object info:(nullable _FBKVOInfo *)info {
      [_infos removeObject:info];
      [object removeObserver:self forKeyPath:info->_keyPath context:(void *)info];
  }
  
  // 当FBKVOController释放时，会主动调用移除观察方法
  - (void)dealloc {
      //****释放时，主动移除观察****
      [self unobserveAll];
  }
  ```

- 总结：`FBKVOController` 建立一个管理器，注册成为真正的观察者，在收到观察回调后，进行消息分发。自释放功能也由该管理器执行。
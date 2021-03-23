//
//  STViewController.h
//  KVO
//
//  Created by stone on 2021/2/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface STViewController : UIViewController


@end

@interface Instance : NSObject

@property (nonatomic, strong) NSString *name;

+ (instancetype)instance;

@end

NS_ASSUME_NONNULL_END

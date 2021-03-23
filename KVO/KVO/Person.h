//
//  STObject.h
//  KVO
//
//  Created by stone on 2021/2/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject

@property (nonatomic, strong) NSString *name;

@property (nonatomic) NSInteger age;

@property (nonatomic) NSInteger tag;

@end

@interface Non_Autonotifying_Person : NSObject
@property (nonatomic, strong) NSString *name;
@end

@interface Overrides_ObservationInfo_Person : NSObject
@property (nonatomic, strong) NSString *name;
@property (nullable) void *st_observationInfo;
@end

NS_ASSUME_NONNULL_END

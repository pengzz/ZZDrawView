//
//  ZZDrawCodingBaseModel.h
//  ZZ
//
//  Created by zz on 2018/12.
//  Copyright © 2018年 zz. All rights reserved.
//

#import "ZZDrawCodingBaseModel.h"
#import "YYModel.h"

@implementation ZZDrawCodingBaseModel

- (void)encodeWithCoder:(NSCoder *)aCoder {

    [self yy_modelEncodeWithCoder:aCoder];

}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    return [self yy_modelInitWithCoder:aDecoder];
    
}

- (id)copyWithZone:(NSZone *)zone {
    
    return [self yy_modelCopy];
    
}

-(NSUInteger)hash {
    
    return [self yy_modelHash];
    
}

- (BOOL)isEqual:(id)object {

    return [self yy_modelIsEqual:object];
    
}

//避开关键字
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"Id" : @"id",
             @"Description" : @"description",
             };
}

@end

@implementation ZZDrawModel


@end

@implementation ZZPointModel


@end

@implementation ZZBrushModel

/** 获取两个point便捷方法 */
- (CGPoint)beginPoint {
    return CGPointMake(self.beginPointM.xPoint,self.beginPointM.yPoint);
}
- (CGPoint)endPoint {
    return CGPointMake(self.endPointM.xPoint,self.endPointM.yPoint);
}

@end

@implementation ZZActionModel


@end

@implementation ZZDrawPackage


@end

@implementation ZZDrawFile


@end



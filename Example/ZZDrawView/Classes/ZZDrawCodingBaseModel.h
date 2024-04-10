//
//  ZZDrawCodingBaseModel.h
//  ZZ
//
//  Created by zz on 2018/12.
//  Copyright © 2018年 zz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** 绘画Coding基类（内部使用yy编码解码） */
@interface ZZDrawCodingBaseModel : NSObject<NSCopying,NSCoding>

-(void)encodeWithCoder:(NSCoder *)aCoder;

-(id)initWithCoder:(NSCoder *)aDecoder;

-(id)copyWithZone:(NSZone *)zone;

-(NSUInteger)hash;

-(BOOL)isEqual:(id)object;

@end



/** 绘画Draw基类模型 */
@interface ZZDrawModel : ZZDrawCodingBaseModel

/** 这个可用于快速判断model的type,而不用判断子类的class.（暂未设置） */
@property (nonatomic, assign) NSInteger modelType;

/** 时间偏移（用于回放） */
@property (nonatomic, assign) double timeOffset;

@end


/** 点point模型 */
@interface ZZPointModel : ZZDrawModel

/** x轴位置 */
@property (nonatomic, assign) CGFloat xPoint;

/** y轴位置 */
@property (nonatomic, assign) CGFloat yPoint;

/** 时间偏移（用于回放）。 如果是touchesBegan时的点则表示：前时间偏移（用于回放） */
//@property (nonatomic, assign) double timeOffset;

@end


/** 画笔brush模型 */
@interface ZZBrushModel : ZZDrawModel

/** 画笔颜色 */
@property (nonatomic, copy) UIColor *brushColor;

/** 画笔宽度 */
@property (nonatomic, assign) CGFloat brushWidth;

/** 形状（ZZShapeType） */
@property (nonatomic, assign) NSInteger shapeType;

/** 是否是橡皮擦 */
@property (nonatomic, assign) BOOL isEraser;

/** 起点模型 */
@property (nonatomic, copy) ZZPointModel *beginPointM;

/** 终点模型 */
@property (nonatomic, copy) ZZPointModel *endPointM;

/** 移动中间point集 */
@property (nonatomic, strong) NSMutableArray<ZZDrawModel*> *pointArray;

/** 临时路径（进度路径） */
@property (nonatomic, strong) UIBezierPath *bezierPath;


/** 获取两个point便捷方法 */
- (CGPoint)beginPoint;
- (CGPoint)endPoint;

@end



/** 绘画动作类型 */
typedef NS_ENUM(NSInteger, ZZDrawAction)
{
    ZZDrawActionUnKnown = 1,
    ZZDrawActionUndo,       /** 撤销      */
    ZZDrawActionRedo,       /** 重做      */
    ZZDrawActionSave,       /** 保存到相册 */
    ZZDrawActionClean,      /** 清除绘制   */
    ZZDrawActionOther,
};

/** 动作模型 */
@interface ZZActionModel : ZZDrawModel

/** 动作类型 */
@property (nonatomic, assign) ZZDrawAction ActionType;

@end



/** 绘画包裹模型（一个包裹就是一次笔刷绘画过程） */
@interface ZZDrawPackage : ZZDrawCodingBaseModel

/** '点或笔刷'数组 */
@property (nonatomic, strong) NSMutableArray<ZZDrawModel*> *pointOrBrushArray;

@end


/** 绘画文件模型（多个笔刷绘画的集合） */
@interface ZZDrawFile : ZZDrawCodingBaseModel

/** '包裹'数组 */
@property (nonatomic, strong) NSMutableArray<ZZDrawPackage*> *packageArray;

@end

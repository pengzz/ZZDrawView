//
//  ZZDrawCodingBaseModel.h
//  ZZ
//
//  Created by zz on 2018/12.
//  Copyright © 2018年 zz. All rights reserved.
//



/*
 这个demo主要是参考了下面两个项目
 
 https://github.com/WillieWu/HBDrawingBoardDemo
 https://github.com/Nicejinux/NXDrawKit
 也针对这两个demo做了相应的优化
 
 
 结构：由上至下
 1、最上层的UIView(ZZCanvas)
 使用CAShapeLayer，提高绘制时的效率
 2、第二层的UIImageview是用来合成ZZCanvas用的
 这样画很多次的时候，也不会占用很高的cpu
 3、第三层是UIImageview，是用来放背景图的
 
 ps:
 没使用drawrect
 
 关于录制脚本：
 1、//linyl 标记的代码都是跟录制脚本和绘制脚本相关
 2、录制后需要重新跑程序，因为这只是个demo
 
 还需要优化的地方：
 1、当前的记录方式是用归档的方式，每次有动作（撤销，重做，保存，清空）和每次的touchesend
 后，都会记录成一个ZZDrawPackage对象，如果想使用socket时，这里可以改为每0.5秒一个LSDrawPackage对象
 ，也就是说，每个ZZDrawPackage对象都是一段时间内的绘制和操作。
 2、线程处理
    demo中使用的是performselector的方式，这里还需要优化。
 3、当前的绘制端和显示端公用了很多的内部结构
 
 */


/** ★♡☆☀︎☁︎☂︎☺︎⚑✪◎❖☞✔︎⏏︎⌘♲☢︎♻︎☢️💯‼️🎶🎵 */
/** ZZ说明：本demo是LSDrawView深度改造而来 */


#import <UIKit/UIKit.h>
#import "ZZDrawCodingBaseModel.h"

#define kZZDEF_MAX_UNDO_COUNT   10

#define kZZDEF_BRUSH_COLOR [UIColor colorWithRed:255 green:0 blue:0 alpha:1.0]

#define kZZDEF_BRUSH_WIDTH 3

#define kZZDEF_BRUSH_SHAPE ZZShapeCurve


/////////////////////////////////////////////////////////////////////
/** 画笔形状 */
typedef NS_ENUM(NSInteger, ZZShapeType)
{
    /** 曲线(默认) */
    ZZShapeCurve = 0,
    /** 直线 */
    ZZShapeLine,
    /** 椭圆 */
    ZZShapeEllipse,
    /** 矩形 */
    ZZShapeRect,
};


////////////////////////////////////////////////////////////////////
/** 画布 */
@interface ZZCanvas : UIView

- (void)setBrush:(ZZBrushModel *)brush;

@end


/////////////////////////////////////////////////////////////////////

@interface ZZDrawView0 : UIView

//背景图
@property (assign, nonatomic) UIImage *backgroundImage;

//颜色
@property (strong, nonatomic) UIColor *brushColor;
//是否是橡皮擦
@property (assign, nonatomic) BOOL isEraser;
//宽度
@property (assign, nonatomic) NSInteger brushWidth;
//形状
@property (assign, nonatomic) ZZShapeType shapeType;

//撤销
- (void)unDo;
//重做
- (void)reDo;
//保存到相册
- (void)save;
//清除绘制
- (void)clean;


//录制脚本
- (void)testRecToFile;
//绘制脚本
- (void)testPlayFromFile;

//- (void)canUndo;
//
//- (void)canRedo;

@end

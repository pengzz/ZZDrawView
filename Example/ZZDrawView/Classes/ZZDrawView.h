//
//  ZZDrawCodingBaseModel.h
//  ZZ
//
//  Created by zz on 2018/12.
//  Copyright © 2018年 zz. All rights reserved.
//



/*
 这个demo主要是参考了其它一些项目
 
 使用CAShapeLayer，提高绘制时的效率
 ps:
 没使用drawrect
 
 还需要优化的地方：
 1、当前的记录方式是用归档的方式，每次有动作（撤销，重做，保存，清空）和每次的touchesend
 后，都会记录成一个ZZDrawPackage对象，如果想使用socket时，这里可以改为每0.5秒一个LSDrawPackage对象
 ，也就是说，每个ZZDrawPackage对象都是一段时间内的绘制和操作。
 2、线程处理
    demo中使用的是performselector的方式，这里还需要优化。
 
 */


/** ★♡☆☀︎☁︎☂︎☺︎⚑✪◎❖☞✔︎⏏︎⌘♲☢︎♻︎☢️💯‼️🎶🎵 */
/** ZZ说明：本demo是参照其它一些demo深度改造而来 */


#import <UIKit/UIKit.h>
#import "ZZDrawCodingBaseModel.h"


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

/////////////////////////////////////////////////////////////////////

@interface ZZDrawView : UIView

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

#pragma mark - ♻︎外部方法♻︎
///撤销
- (void)unDo;
///重做
- (void)reDo;
///保存到相册
- (void)save;
///清除绘制
- (void)clean;

#pragma mark - ♻︎外部方法♻︎ can
///能否撤销
- (BOOL)canUndo;
///能否重做
- (BOOL)canRedo;

#pragma mark - 录制&回放
///存储笔刷
- (BOOL)storeBrushes:(NSString*)filePath;
///重绘笔刷
- (BOOL)reDrawBrushes:(NSString*)filePath;
///录制脚本
- (BOOL)testRecToFile:(NSString*)filePath;
///绘制脚本
- (BOOL)testPlayFromFile:(NSString*)filePath;


#pragma mark - 合成brush的图片
///方式一：⚑合并当前图层去图片⚑
- (UIImage*)composeLayerToImage;
///方式二：⚑文件合成去图片⚑
+ (UIImage*)fileComposeToImage:(NSString*)filePath withSize:(CGSize)size;
///根据brushes数组合成图片
+ (UIImage*)composeBrushesToImage:(NSMutableArray<ZZBrushModel*> *)brushArray withSize:(CGSize)size;

@end


//参考链接：
//参考demo
//https://www.jianshu.com/p/bcd864c5dece
//https://www.jianshu.com/p/000780475024
//https://www.jianshu.com/p/b7213a14b471 //即：https://github.com/WillieWu/HBDrawingBoardDemo
//笔刷背景
//https://blog.csdn.net/sonysuqin/article/details/81092574
//https://segmentfault.com/q/1010000003976426
//https://github.com/bb-coder/BHBDrawBoarderDemo/issues/1
//删除CALayer的子layer的正确姿势
//https://www.jianshu.com/p/fd1036bd49eb

//其它一些相关功能demo
//http://www.code4app.com/thread-30059-1-1.html
//http://www.code4app.com/thread-29884-1-1.html
//http://www.code4app.com/thread-30530-1-1.html

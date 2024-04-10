//
//  ZZDrawCodingBaseModel.h
//  ZZ
//
//  Created by zz on 2018/12.
//  Copyright © 2018年 zz. All rights reserved.
//

#import "ZZDrawView.h"


@interface ZZDrawView()
{
    CGPoint pts[5];
    uint ctr;
}

/// current layer
@property (nonatomic, strong) CAShapeLayer *currentDrawLayer;
/// current path(start from touchesBegan)
//@property (nonatomic, strong) UIBezierPath *currentDrawPath;

/// save all layers
//@property (nonatomic, strong) NSMutableArray *drawLayerArray;
/// 重做图层容器
//@property (nonatomic, strong) NSMutableArray *redo_drawLayerArray;


//画笔容器(即'撤销容器')
@property (nonatomic, strong) NSMutableArray *brushArray;
//重做容器
@property (nonatomic, strong) NSMutableArray *redo_brushArray;

//每次touchesBegan的时间，后续为计算偏移量用
@property (nonatomic, strong) NSDate *beginDate;

//录制-记录脚本用
@property (nonatomic, strong) ZZDrawFile *dwawFile;
//回放-绘制脚本用
@property (nonatomic, strong) NSMutableArray *recPackageArray;

@end

@implementation ZZDrawView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        //设置背景
        [self setImageSome];
        
        //数组
        _brushArray = [NSMutableArray new];
        _redo_brushArray = [NSMutableArray new];
        
        //一些默认参数设值
        _brushColor = kZZDEF_BRUSH_COLOR;
        _brushWidth = kZZDEF_BRUSH_WIDTH;
        _isEraser = NO;
        _shapeType = kZZDEF_BRUSH_SHAPE;
        
        //记录脚本用
        _dwawFile = [ZZDrawFile new];
        _dwawFile.packageArray = [NSMutableArray new];

    }
    return self;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    if (backgroundImage) {
        [self setImageSome];
    }
}

- (void)setImageSome {
    //参考链接：
    //https://blog.csdn.net/sonysuqin/article/details/81092574
    //https://segmentfault.com/q/1010000003976426
    //https://github.com/bb-coder/BHBDrawBoarderDemo/issues/1
    //
    //https://www.jianshu.com/p/fd1036bd49eb
    //
    //https://www.jianshu.com/p/000780475024
    //https://www.jianshu.com/p/b7213a14b471

    //TO DO
    UIImage *image = self.backgroundImage;
#if DEBUG
    image = [UIImage imageNamed:@"zz_bg_image.png"];
#endif
    
    //创建一个新的Context
    UIGraphicsBeginImageContext(self.frame.size);
    //获得当前Context
    CGContextRef context = UIGraphicsGetCurrentContext();
    //CTM变换，调整坐标系，*重要*，否则橡皮擦使用的背景图片会发生翻转。
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -self.bounds.size.height);
    //图片适配到当前View的矩形区域，会有拉伸
    [image drawInRect:self.bounds];
    //获取拉伸并翻转后的图片
    UIImage *stretchedImg = UIGraphicsGetImageFromCurrentImageContext();
    //将变换后的图片设置为背景色
    [self setBackgroundColor:[[UIColor alloc] initWithPatternImage:stretchedImg]];
    //View的图层设置为原始图片，这里会自动翻转，经过这步后图层显示和橡皮背景都设置为正确的图片。
    self.layer.contents = (_Nullable id)image.CGImage;
    UIGraphicsEndImageContext();
    
}

#pragma mark - Getters / Setters
/*
- (NSMutableArray *)drawLayerArray {
    if (!_drawLayerArray) {
        _drawLayerArray = [NSMutableArray arrayWithCapacity:10];
    }
    return _drawLayerArray;
}

- (NSMutableArray *)redo_drawLayerArray {
    if (!_redo_drawLayerArray) {
        _redo_drawLayerArray = [NSMutableArray arrayWithCapacity:10];
    }
    return _redo_drawLayerArray;
}
*/

#pragma mark - custom methods

//★构造图层：一个新的绘画图层
- (CAShapeLayer *)makeDrawLayer:(ZZBrushModel *)brush {
    CAShapeLayer *drawLayer = [CAShapeLayer layer];
    drawLayer.frame = self.bounds;
    drawLayer.fillColor = [UIColor clearColor].CGColor;
    drawLayer.lineJoin = kCALineJoinRound;
    drawLayer.lineCap = kCALineCapRound;
    drawLayer.lineWidth = brush.brushWidth;
    //drawLayer.masksToBounds = YES;//这个解决超出问题
    if (!brush.isEraser) {
        drawLayer.strokeColor = brush.brushColor.CGColor;
    } else {
        drawLayer.strokeColor = self.backgroundColor.CGColor;//注意这里用了背景色
    }
    
    //添加
//    [self.layer insertSublayer:drawLayer atIndex:(unsigned)self.drawLayerArray.count];
//    [self.drawLayerArray addObject:drawLayer];
    [self.layer insertSublayer:drawLayer atIndex:(unsigned)self.layer.sublayers.count];

    //记录指针
    self.currentDrawLayer = drawLayer;
    //Xself.currentDrawPath = brush.bezierPath;
    
    return drawLayer;
}

//★刷新图层：当前绘画图层->刷新路径
- (void)currentDrawLayer_refreshPath {
    /*
    //‼️注意：因为"非线条"的ZZShapeType时，在touchesMove时使用了"brush.bezierPath = [UIBezierPath bezierPathWith..."的语句重新设置brush.bezierPath了，所以当前self.currentDrawPath应该同步更新。
    if (_shapeType!=ZZShapeCurve && _shapeType!=ZZShapeLine) {
        //ZZBrushModel *brush = [_brushArray lastObject];
        //self.currentDrawPath = brush.bezierPath;
    }
     */
    
    //当前笔刷
    ZZBrushModel *brush = [_brushArray lastObject];
    //刷新设置路径
    self.currentDrawLayer.path = brush.bezierPath.CGPath;
}

#pragma mark - dealloc

- (void)dealloc {
    [self just_clean];
}

//释放redo相关数组
- (void)release_redo_array
{
    /*
    //_redo_drawLayerArray
    [self.redo_drawLayerArray makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.redo_drawLayerArray removeAllObjects];
    */
    
    //_redo_brushArray
    [self.redo_brushArray removeAllObjects];
}

//释放所以图层
- (void)releaseAllLayers {
    /*
    [self.drawLayerArray makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.drawLayerArray removeAllObjects];
    
    [self.redo_drawLayerArray makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self.redo_drawLayerArray removeAllObjects];
     */
    
    //清理子图层
    while (self.layer.sublayers.count) {
        [self.layer.sublayers.firstObject removeFromSuperlayer];
    }
}

//释放所有brushes
- (void)releaseAllBrushes {
    [self.brushArray removeAllObjects];
    [self.redo_brushArray removeAllObjects];
}

//仅仅清理
- (void)just_release {
    [self releaseAllLayers];
    [self releaseAllBrushes];
}


#pragma mark - touches

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];
    [self brush_touchesBegan:point withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];
    [self brush_touchesMoved:point withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];
    [self brush_touchesEnded:point withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

#pragma mark - brush_touches...
- (void)brush_touchesBegan:(CGPoint)point withEvent:(UIEvent *)event {
    //★动手★
    if (event) {
        //每次画线前，都清除重做列表。
        [self release_redo_array];
    }
    
    //曲线临时变量此次记录
    ctr = 0;
    pts[0] = point;
    
    //记录下上次touchesEnd到这次touchesBegan之间的时间差值
    double last_timeOffset = fabs(_beginDate.timeIntervalSinceNow);
    //记录下此次touchesBegan开始时间值
    _beginDate = [NSDate date];
    
    ZZBrushModel *brushModel = ({
        ZZBrushModel *brushModel = [ZZBrushModel new];
        brushModel.brushColor = _brushColor;
        brushModel.brushWidth = _brushWidth;
        brushModel.shapeType = _shapeType;
        brushModel.isEraser = _isEraser;
        brushModel.beginPointM = [ZZPointModel new];
        brushModel.beginPointM.xPoint = point.x;
        brushModel.beginPointM.yPoint = point.y;
        brushModel.beginPointM.timeOffset = 0;
        brushModel.timeOffset = last_timeOffset;//时间偏移
        //路径
        brushModel.bezierPath = [UIBezierPath new];
        [brushModel.bezierPath moveToPoint:point];
        //
        brushModel;
    });
    
    //添加进数组
    [_brushArray addObject:brushModel];
    
    //★动手★
    if (event) {
        //添加进此次包
        [self addModelToPackage:brushModel];
    }
    
    //☆创建图层☆
    [self makeDrawLayer:brushModel];
}

- (void)brush_touchesMoved:(CGPoint)point withEvent:(UIEvent *)event {
    ZZBrushModel *brush = [_brushArray lastObject];
    
    //★动手★
    //添加一个点
    if (event) {
        //构造一个移动点
        ZZPointModel *pointModel = [ZZPointModel new];
        pointModel.xPoint = point.x;
        pointModel.yPoint = point.y;
        pointModel.timeOffset = fabs(_beginDate.timeIntervalSinceNow);//记录时间差值
        
        //目标brush对象 （或者：ZZBrushModel *brushModel = brush;）
        ZZBrushModel *brushModel = ({
            ZZDrawPackage *drawPackage = [_dwawFile.packageArray lastObject];
            (ZZBrushModel*)[drawPackage.pointOrBrushArray firstObject];//取出当前的brushModel
        });

        //构建可变数组点集
        if (!brushModel.pointArray) {
            brushModel.pointArray = [NSMutableArray new];
        }
        //加入'此次'数组
        [brushModel.pointArray addObject:pointModel];
    }
    
    //★路径显示★
    //进度路径
    if (_isEraser) {
        [brush.bezierPath addLineToPoint:point];
    }
    else {
        switch (_shapeType) {
            case ZZShapeCurve:
                //原始：[brush.bezierPath addLineToPoint:point];
                //每N次点平滑处理
                ctr++;
                pts[ctr] = point;
                if (ctr == 4) {
                    pts[3] = CGPointMake((pts[2].x + pts[4].x)/2.0, (pts[2].y + pts[4].y)/2.0);
                    //
                    [brush.bezierPath moveToPoint:pts[0]];
                    [brush.bezierPath addCurveToPoint:pts[3] controlPoint1:pts[1] controlPoint2:pts[2]];
                    pts[0] = pts[3]; 
                    pts[1] = pts[4]; 
                    ctr = 1;
                }
                break;
            case ZZShapeLine:
                [brush.bezierPath removeAllPoints];
                [brush.bezierPath moveToPoint:brush.beginPoint];
                [brush.bezierPath addLineToPoint:point];
                break;
            case ZZShapeEllipse:
                //‼️注意这里重新变更了brush的bezierPath对象！！！
                brush.bezierPath = [UIBezierPath bezierPathWithOvalInRect:[self getRectWithStartPoint:brush.beginPoint endPoint:point]];
                break;
            case ZZShapeRect:
                //‼️注意这里重新变更了brush的bezierPath对象！！！
                brush.bezierPath = [UIBezierPath bezierPathWithRect:[self getRectWithStartPoint:brush.beginPoint endPoint:point]];
                break;
            default:
                break;
        }
    }
    //☆刷新图层☆
    [self currentDrawLayer_refreshPath];
}

- (void)brush_touchesEnded:(CGPoint)point withEvent:(UIEvent *)event {
    //每N次点平滑处理->归正
    uint count = ctr;
    if (count <= 4 && _shapeType == ZZShapeCurve) {
        for (int i = 4; i > count; i--) {
            [self brush_touchesMoved:point withEvent:event];
        }
        ctr = 0;
    }
    else {
        [self brush_touchesMoved:point withEvent:event];
    }
    
    //★动手★
    //设置终点
    if (event) {
        //目标brush对象 （或者：ZZBrushModel *brushModel = brush;）
        ZZBrushModel *brushModel = ({
            ZZDrawPackage *drawPackage = [_dwawFile.packageArray lastObject];
            (ZZBrushModel*)[drawPackage.pointOrBrushArray firstObject];//取出当前的brushModel
        });
        brushModel.endPointM = [ZZPointModel new];
        brushModel.endPointM.xPoint = point.x;
        brushModel.endPointM.yPoint = point.y;
        brushModel.endPointM.timeOffset = fabs(_beginDate.timeIntervalSinceNow);
    }

    //☂︎
    //记录下此次touchesEnd终点时间值
    _beginDate = [NSDate date];
    
    //☂︎
    if (!event) {
        [self drawNextPackage];
    }
}

#pragma mark - 内部：辅助方法
//根据两个点弄出一个Rect
- (CGRect)getRectWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    CGFloat x = startPoint.x <= endPoint.x ? startPoint.x: endPoint.x;
    CGFloat y = startPoint.y <= endPoint.y ? startPoint.y : endPoint.y;
    CGFloat width = fabs(startPoint.x - endPoint.x);
    CGFloat height = fabs(startPoint.y - endPoint.y);
    
    return CGRectMake(x , y , width, height);
}

#pragma mark - 内部：辅助方法：添加Model进包
- (void)addModelToPackage:(ZZDrawModel*)drawModel
{
    //动作类型模型
    if ([drawModel isKindOfClass:[ZZActionModel class]]) {
        //记录下上次touchesEnd到这次touchesBegan之间的时间差值
        double last_timeOffset = fabs(_beginDate.timeIntervalSinceNow);
        //记录下此次'更新'时间值
        _beginDate = [NSDate date];
        ((ZZActionModel*)drawModel).timeOffset = last_timeOffset;
    }
    
    //添加
    ZZDrawPackage *drawPackage = [ZZDrawPackage new];
    drawPackage.pointOrBrushArray = [NSMutableArray new];
    [drawPackage.pointOrBrushArray addObject:drawModel];
    [_dwawFile.packageArray addObject:drawPackage];
}


#pragma mark - ♻︎外部方法♻︎
//♻︎撤销
- (void)unDo {
    if ([self just_unDo]) {
        ZZActionModel *actionModel = [ZZActionModel new];
        actionModel.ActionType = ZZDrawActionUndo;
        [self addModelToPackage:actionModel];
    }
}
//♻︎重做
- (void)reDo {
    if ([self just_reDo]) {
        ZZActionModel *actionModel = [ZZActionModel new];
        actionModel.ActionType = ZZDrawActionRedo;
        [self addModelToPackage:actionModel];
    }
}
//♻︎保存到相册
- (void)save {
    if ([self just_save]) {
        ZZActionModel *actionModel = [ZZActionModel new];
        actionModel.ActionType = ZZDrawActionSave;
        [self addModelToPackage:actionModel];
    }
}
//♻︎清除绘制
- (void)clean {
    if ([self just_clean]) {
        ZZActionModel *actionModel = [ZZActionModel new];
        actionModel.ActionType = ZZDrawActionClean;
        [self addModelToPackage:actionModel];
    }
}

#pragma mark - common methods 共有方法
- (BOOL)just_unDo {
    if (self.brushArray.count > 0) {
        if (0) {
            /*
            //brush
            ZZBrushModel *brushModel = [_brushArray lastObject];
            [_brushArray removeLastObject];
            [_redo_brushArray addObject:brushModel];

            //layer
            [self.drawLayerArray removeObject:self.currentDrawLayer];
            [self.redo_drawLayerArray addObject:self.currentDrawLayer];
            
            //layer 移除显示
            [self.currentDrawLayer removeFromSuperlayer];
            
            //
            //Xself.currentDrawPath = self.brushArray.count>0?((ZZBrushModel *)[self.brushArray lastObject]).bezierPath:nil;
            self.currentDrawLayer = self.drawLayerArray.count>0?[self.drawLayerArray lastObject]:nil;
            */
        }
        
        if (1) {
            //brush
            ZZBrushModel *brushModel = [_brushArray lastObject];
            [_brushArray removeLastObject];
            [_redo_brushArray addObject:brushModel];
            
            //layer
//            [self.drawLayerArray removeObject:self.currentDrawLayer];
            
            //layer 移除显示
            [self.currentDrawLayer removeFromSuperlayer];
            
            //
            //Xself.currentDrawPath = self.brushArray.count>0?((ZZBrushModel *)[self.brushArray lastObject]).bezierPath:nil;
//            self.currentDrawLayer = self.drawLayerArray.count>0?[self.drawLayerArray lastObject]:nil;
            self.currentDrawLayer = [self.layer.sublayers lastObject];
        }
        
        return YES;
    }
    
    return NO;
}

- (BOOL)just_reDo {
    if (self.redo_brushArray.count > 0) {
        if (0) {
            /*
            //brush
            ZZBrushModel *brush = [_redo_brushArray lastObject];
            [_redo_brushArray removeLastObject];
            [_brushArray addObject:brush];
            
            //layer
            CAShapeLayer *drawLayer = [self.redo_drawLayerArray lastObject];
            [self.redo_drawLayerArray removeLastObject];
            [self.drawLayerArray addObject:drawLayer];
            
            //添加
            [self.layer insertSublayer:drawLayer atIndex:(unsigned)self.drawLayerArray.count];
            
            //
            //Xself.currentDrawPath = brush.bezierPath;
            self.currentDrawLayer = drawLayer;
            */
        }
        
        if (1) {
            //brush
            ZZBrushModel *brush = [_redo_brushArray lastObject];
            [_redo_brushArray removeLastObject];
            [_brushArray addObject:brush];
            
            //layer 添加显示
            [self makeDrawLayer:brush];
            //☆刷新图层☆
            [self currentDrawLayer_refreshPath];
        }
        
        return YES;
    }
    
    return NO;
}

- (BOOL)just_save {
    if (1) {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        [self.layer renderInContext:context];
        
        UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIImageWriteToSavedPhotosAlbum(getImage, nil, nil, nil);
        UIGraphicsEndImageContext();
    }
    
    return YES;
}

- (BOOL)just_clean {
    if (1) {
        //仅仅清理
        [self just_release];
    }
    
    return YES;
}


#pragma mark - 回放相关
//录制脚本
- (void)testRecToFile
{
    NSString *filePath = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(), @"drawFile"];
    NSLog(@"drawfile:%@",filePath);
    
    BOOL bRet = [NSKeyedArchiver archiveRootObject:_dwawFile toFile:filePath];
    if (bRet) {
        NSLog(@"archive Succ");
    }
}

//绘制脚本
- (void)testPlayFromFile
{
    //仅仅清理
    [self just_release];
    
    //清除且还原
    _recPackageArray = nil;
    
    [self drawNextPackage];
}

//下一次：笔刷绘画过程
- (void)drawNextPackage
{
    //通过文件路径获取图形操作数组
    if (!_recPackageArray) {
        NSString *filePath = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(), @"drawFile"];
        ZZDrawFile *drawFile = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        if (drawFile) {
            _recPackageArray = drawFile.packageArray;
        }
    }
    
    //遍历处理过程
    if (_recPackageArray.count > 0)
    {
        //取出数组第一个
        ZZDrawPackage *pack = [_recPackageArray firstObject];
        //移除数组中第一个
        [_recPackageArray removeObjectAtIndex:0];
        
        //再遍历处理
        for (ZZDrawModel *drawModel in pack.pointOrBrushArray) {
            if (drawModel) {
                
//                dispatch_async(dispatch_get_main_queue(), ^{

                if([drawModel isKindOfClass:[ZZBrushModel class]]) {
                    ZZBrushModel *brushModel = (ZZBrushModel*)drawModel;
                    
                    double timeOffset = brushModel.timeOffset;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeOffset * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        //开始
                        if (brushModel.beginPointM) {
                            double packageOffset = 0*brushModel.beginPointM.timeOffset;
                            [self performSelector:@selector(drawWithBrushModel_begin:) withObject:drawModel afterDelay:packageOffset];
                        }
                        //中间点
                        if (brushModel.pointArray.count>0) {
                            for (ZZPointModel *pointModel  in brushModel.pointArray) {
                                double packageOffset = pointModel.timeOffset;
                                [self performSelector:@selector(drawWithPointModel:) withObject:pointModel afterDelay:packageOffset];
                            }
                        }
                        //结束
                        {
                            double packageOffset = brushModel.endPointM.timeOffset;
                            [self performSelector:@selector(drawWithBrushModel_end:) withObject:drawModel afterDelay:packageOffset];
                        }
                    });
                }
                
                else if([drawModel isKindOfClass:[ZZActionModel class]])
                {
                    ZZActionModel *actionModel = (ZZActionModel*)drawModel;
                    double packageOffset = actionModel.timeOffset;//0.5
                    switch (actionModel.ActionType) {
                        case ZZDrawActionRedo:
                            [self performSelector:@selector(drawActionReDo) withObject:nil afterDelay:packageOffset];
                            break;
                        case ZZDrawActionUndo:
                            [self performSelector:@selector(drawActionUnDo) withObject:nil afterDelay:packageOffset];
                            break;
                        case ZZDrawActionSave:
                            [self performSelector:@selector(drawActionSave) withObject:nil afterDelay:packageOffset];
                            break;
                        case ZZDrawActionClean:
                            [self performSelector:@selector(drawActionClean) withObject:nil afterDelay:packageOffset];
                            break;
                        default:
                            break;
                    }
                }
                
//                });
                
            }
        }
    }
}

- (void)drawWithBrushModel_begin:(ZZDrawModel*)drawModel {
    ZZBrushModel *brushModel = (ZZBrushModel*)drawModel;
    if (brushModel.beginPointM) {
        [self setDrawingBrush:brushModel];
        [self drawBeginPoint:brushModel.beginPoint];
    }
}

- (void)drawWithBrushModel_end:(ZZDrawModel*)drawModel {
    ZZBrushModel *brushModel = (ZZBrushModel*)drawModel;
    [self drawEndPoint:brushModel.endPoint];
}

- (void)drawWithPointModel:(ZZDrawModel*)drawModel {
    ZZPointModel *pointModel = (ZZPointModel*)drawModel;
    [self drawMovePoint:CGPointMake(pointModel.xPoint, pointModel.yPoint)];
}

- (void)setDrawingBrush:(ZZBrushModel*) brushModel {
    if (brushModel) {
        _brushColor = brushModel.brushColor;
        _brushWidth = brushModel.brushWidth;
        _shapeType  = brushModel.shapeType;
        _isEraser   = brushModel.isEraser;
    }
}

- (void)drawBeginPoint:(CGPoint) point {
    [self brush_touchesBegan:point withEvent:nil];
}

- (void)drawMovePoint:(CGPoint) point {
    [self brush_touchesMoved:point withEvent:nil];
}

- (void)drawEndPoint:(CGPoint) point {
     [self brush_touchesEnded:point withEvent:nil];
}

#pragma mark - 回放：drawAction
//回放-撤销
- (void)drawActionUnDo {
    if ([self just_unDo]) {
        [self drawNextPackage];
    }
}
//回放-重做
- (void)drawActionReDo {
    if ([self just_reDo]) {
        [self drawNextPackage];
    }
}
//回放-保存到相册
- (void)drawActionSave {
    if ([self just_save]) {
        [self drawNextPackage];
    }
}
//回放-清除绘制
- (void)drawActionClean {
    if ([self just_clean]) {
        [self drawNextPackage];
    }
}

//- (UIImage*)getAlphaImg
//{
//    UIColor *colorAlpha = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
//    CGRect rect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
//    UIGraphicsBeginImageContext(rect.size);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetFillColorWithColor(context, [colorAlpha CGColor]);
//    CGContextFillRect(context, rect);
//    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return img;
//}

@end




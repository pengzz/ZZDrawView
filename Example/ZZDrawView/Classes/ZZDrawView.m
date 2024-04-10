//
//  ZZDrawCodingBaseModel.h
//  ZZ
//
//  Created by zz on 2018/12.
//  Copyright © 2018年 zz. All rights reserved.
//

#import "ZZDrawView.h"

//最大undo次数
#define kZZDEF_MAX_UNDO_COUNT   10
//默认笔刷颜色
#define kZZDEF_BRUSH_COLOR [UIColor colorWithRed:255 green:0 blue:0 alpha:1.0]
//默认笔刷宽度
#define kZZDEF_BRUSH_WIDTH 3
//默认笔刷类型
#define kZZDEF_BRUSH_SHAPE ZZShapeCurve


@interface ZZDrawView()
{
    CGPoint pts[5];
    uint ctr;
}

//当前图层
@property (nonatomic, strong) CAShapeLayer *currentDrawLayer;

//画笔容器(即'撤销容器')
@property (nonatomic, strong) NSMutableArray<ZZBrushModel*> *brushArray;
//重做容器
@property (nonatomic, strong) NSMutableArray<ZZBrushModel*> *redo_brushArray;

//每次touchesBegan的时间，后续为计算偏移量用
@property (nonatomic, strong) NSDate *beginDate;

//录制-记录脚本用
@property (nonatomic, strong) ZZDrawFile *dwawFile;
//回放-绘制脚本用
@property (nonatomic, strong) NSMutableArray *recPackageArray;

@end

@implementation ZZDrawView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
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
    }
    return self;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImage = backgroundImage;
    if (backgroundImage) {
        [self setImageSome];
    }
}

- (void)setImageSome {
    UIImage *image = self.backgroundImage;
    
    CGSize size = self.frame.size;
    //创建一个新的Context
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    //获得当前Context
    CGContextRef context = UIGraphicsGetCurrentContext();
    //CTM变换，调整坐标系，*重要*，否则橡皮擦使用的背景图片会发生翻转。
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -size.height);
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
//记录脚本用
- (ZZDrawFile *)dwawFile {
    if (!_dwawFile) {
        _dwawFile = [ZZDrawFile new];
        _dwawFile.packageArray = [NSMutableArray new];
    }
    return _dwawFile;
}


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
    [self.layer insertSublayer:drawLayer atIndex:(unsigned)self.layer.sublayers.count];
    //记录指针
    self.currentDrawLayer = drawLayer;
    
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
    [self.redo_brushArray removeAllObjects];
}

//释放所以图层
- (void)releaseAllLayers {
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
        
        //目标brush对象
        //ZZBrushModel *brushModel = (ZZBrushModel*)[[self.dwawFile.packageArray lastObject].pointOrBrushArray firstObject];
        ZZBrushModel *brushModel = [self.brushArray lastObject];
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
        //目标brush对象
        //ZZBrushModel *brushModel = (ZZBrushModel*)[[self.dwawFile.packageArray lastObject].pointOrBrushArray firstObject];
        ZZBrushModel *brushModel = [self.brushArray lastObject];
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
    [self.dwawFile.packageArray addObject:drawPackage];
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

#pragma mark - ♻︎外部方法♻︎ can
//能否撤销
- (BOOL)canUndo {
    return self.brushArray.count > 0 ? YES : NO;
}
//能否重做
- (BOOL)canRedo {
    return self.redo_brushArray.count > 0 ? YES : NO;
}

#pragma mark - common methods 共有方法
- (BOOL)just_unDo {
    if (self.brushArray.count > 0) {
        if (1) {
            //brush
            ZZBrushModel *brushModel = [_brushArray lastObject];
            [_brushArray removeLastObject];
            [_redo_brushArray addObject:brushModel];

            //layer 移除显示
            [self.currentDrawLayer removeFromSuperlayer];
            //当前layer
            self.currentDrawLayer = [self.layer.sublayers lastObject];
        }
        
        return YES;
    }
    
    return NO;
}

- (BOOL)just_reDo {
    if (self.redo_brushArray.count > 0) {
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


#pragma mark - 录制&回放
//存储笔刷
- (BOOL)storeBrushes:(NSString*)filePath
{
    NSString *path = filePath;
    if (path.length==0) {
        path = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(), @"brushes_drawFile"];//默认文件路径
    }
    NSLog(@"drawfile:%@", path);
    
    if (self.brushArray.count==0) {
        NSLog(@"self.brushArray.count==0,即还没有需要保存的笔刷内容了...");
        return NO;
    }
    
    //构造一个file对象出来
    ZZDrawFile *brushes_drawFile = [ZZDrawFile new];
    brushes_drawFile.packageArray = [NSMutableArray new];
    [self.brushArray enumerateObjectsUsingBlock:^(ZZBrushModel * _Nonnull drawModel, NSUInteger idx, BOOL * _Nonnull stop) {
        ZZDrawPackage *drawPackage = [ZZDrawPackage new];
        drawPackage.pointOrBrushArray = [[NSMutableArray alloc] initWithObjects:drawModel, nil];
        [brushes_drawFile.packageArray addObject:drawPackage];
    }];
    
    //archive
    BOOL bRet = [NSKeyedArchiver archiveRootObject:brushes_drawFile toFile:path];
    if (!bRet) {
        NSLog(@"fail to archive");
    }
    return bRet;
}
//重绘笔刷
- (BOOL)reDrawBrushes:(NSString*)filePath
{
    //仅仅清理
    [self just_release];

    if (1) {
        NSString *path = filePath;
        if (path.length==0) {
            path = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(), @"brushes_drawFile"];//默认文件路径
        }
        NSLog(@"drawfile:%@", path);
        
        ZZDrawFile *drawFile = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (!drawFile) {
            NSLog(@"fail to unarchive");
            return NO;
        }
        if (drawFile) {
            NSMutableArray<ZZDrawPackage*> *packageArray = drawFile.packageArray;
            [packageArray enumerateObjectsUsingBlock:^(ZZDrawPackage * _Nonnull drawPackage, NSUInteger idx, BOOL * _Nonnull stop) {
                ZZBrushModel *brush = (ZZBrushModel*)[drawPackage.pointOrBrushArray firstObject];
                if (brush) {
                    //添加到「画笔容器」
                    [self.brushArray addObject:brush];
                    //layer 添加显示
                    [self makeDrawLayer:brush];
                    //☆刷新图层☆
                    [self currentDrawLayer_refreshPath];
                }
            }];
        }
    }
    return YES;
}

//录制脚本
- (BOOL)testRecToFile:(NSString*)filePath
{
    NSString *path = filePath;
    if (path.length==0) {
        path = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(), @"REC_drawFile"];//默认文件路径
    }
    NSLog(@"drawfile:%@", path);
    
    //archive
    BOOL bRet = [NSKeyedArchiver archiveRootObject:self.dwawFile toFile:path];
    if (!bRet) {
        NSLog(@"fail to archive");
    }
    return bRet;
}
//绘制脚本
- (BOOL)testPlayFromFile:(NSString*)filePath
{
    //仅仅清理
    [self just_release];
    
    //清除且还原
    self.recPackageArray = nil;
    //通过文件路径获取图形操作数组
    if (!self.recPackageArray) {
        NSString *path = filePath;
        if (path.length==0) {
            path = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(), @"REC_drawFile"];//默认文件路径
        }
        NSLog(@"drawfile:%@", path);
        
        ZZDrawFile *drawFile = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (!drawFile) {
            NSLog(@"fail to unarchive");
            return NO;
        }
        if (drawFile) {
            self.recPackageArray = drawFile.packageArray;
            [self drawNextPackage];
        }
    }
    return YES;
}

//下一次：笔刷绘画过程
- (void)drawNextPackage
{
    //遍历处理过程
    if (self.recPackageArray.count > 0)
    {
        //取出数组第一个
        ZZDrawPackage *pack = [self.recPackageArray firstObject];
        //移除数组中第一个
        [self.recPackageArray removeObjectAtIndex:0];
        
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
                
                else if([drawModel isKindOfClass:[ZZActionModel class]]) {
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


#pragma mark - 合成brush的图片

/**
 方式一：⚑合并当前图层去图片⚑

 @return 图片
 */
- (UIImage*)composeLayerToImage
{
    NSMutableArray<ZZBrushModel*> *brushArray = self.brushArray;
    return [ZZDrawView composeBrushesToImage:brushArray withSize:self.bounds.size];
    
    /*
    //下面这个有问题，橡皮擦时会背景上去
    {
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        //
        [self.layer renderInContext:context];
        //
        UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        //
        return getImage;
    }
     */
}

/**
 方式二：⚑文件合成去图片⚑
 即：根据文件路径取出->unarchive->合成笔刷图片

 @param filePath 文件路径
 @param size 先前环境size
 @return 图片
 */
+ (UIImage*)fileComposeToImage:(NSString*)filePath withSize:(CGSize)size
{
    NSString *path = filePath;
    if (path.length==0) {
        path = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(), @"brushes_drawFile"];//默认文件路径
    }
    NSLog(@"drawfile:%@", path);
    
    ZZDrawFile *drawFile = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    if (!drawFile) {
        NSLog(@"fail to unarchive");
        return nil;
    }
    if (drawFile) {
        NSMutableArray<ZZBrushModel*> *brushArray = [NSMutableArray new];
        //
        NSMutableArray<ZZDrawPackage*> *packageArray = drawFile.packageArray;
        [packageArray enumerateObjectsUsingBlock:^(ZZDrawPackage * _Nonnull drawPackage, NSUInteger idx, BOOL * _Nonnull stop) {
            ZZBrushModel *brush = (ZZBrushModel*)[drawPackage.pointOrBrushArray firstObject];
            if (brush) {
                [brushArray addObject:brush];
            }
        }];
        //
        return [ZZDrawView composeBrushesToImage:brushArray withSize:size];
    }
    return nil;
}

/**
 根据brushes数组合成图片

 @param brushArray brushes数组
 @param size 先前环境size
 @return 图片
 */
+ (UIImage*)composeBrushesToImage:(NSMutableArray<ZZBrushModel*> *)brushArray withSize:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    //CGContextRef context = UIGraphicsGetCurrentContext();
    {
        for (ZZBrushModel *brush in brushArray) {
            UIBezierPath *path = brush.bezierPath;
            //设置连接处的样式
            [path setLineJoinStyle:kCGLineJoinRound];
            //设置头尾的样式
            [path setLineCapStyle:kCGLineCapRound];
            //设置宽度
            path.lineWidth = brush.brushWidth;
            //设置fill与stroke颜色
            [brush.brushColor set];
            //设置线的颜色
            //[[UIColor redColor] setStroke];
            
            if (brush.isEraser) {
                //Sets the fill and stroke colors in the current drawing context
                [[UIColor clearColor] set];
                [path strokeWithBlendMode:kCGBlendModeClear alpha:1.0];//clear清理
                [path stroke];
            }
            {
                //渲染（注意这只进行stroke的）
                [path stroke];
                //这种是填充满
                //X[path fill];
            }
        }
    }
    UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return getImage;
}

@end




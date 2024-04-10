//
//  ZZDrawCodingBaseModel.h
//  ZZ
//
//  Created by zz on 2018/12.
//  Copyright © 2018年 zz. All rights reserved.
//

#import "ZZDrawView0.h"


/////////////////////////////////////////////////////////////////////////////////////
@implementation ZZCanvas

+ (Class)layerClass
{
    return ([CAShapeLayer class]);
}

- (void)setBrush:(ZZBrushModel *)brush
{
    CAShapeLayer *shapeLayer = (CAShapeLayer *)self.layer;
    
    shapeLayer.strokeColor = brush.brushColor.CGColor;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.lineJoin = kCALineJoinRound;
    shapeLayer.lineCap = kCALineCapRound;
    shapeLayer.lineWidth = brush.brushWidth;
    
    if (!brush.isEraser)
    {
        ((CAShapeLayer *)self.layer).path = brush.bezierPath.CGPath;
    }
}

@end


/////////////////////////////////////////////////////////////////////////////////////
@interface ZZDrawView0()
{
    CGPoint pts[5];
    uint ctr;
}

//背景iv
@property (nonatomic, strong) UIImageView *bgImgView;
//画板View
@property (nonatomic, strong) ZZCanvas *canvasView;
//合成View
@property (nonatomic, strong) UIImageView *composeView;
//画笔容器
@property (nonatomic, strong) NSMutableArray *brushArray;
//撤销容器
@property (nonatomic, strong) NSMutableArray *undoArray;
//重做容器
@property (nonatomic, strong) NSMutableArray *redoArray;

//每次touchesBegan的时间，后续为计算偏移量用
@property (nonatomic, strong) NSDate *beginDate;

//记录脚本用
@property (nonatomic, strong) ZZDrawFile *dwawFile;
//绘制脚本用
@property (nonatomic, strong) NSMutableArray *recPackageArray;

@end

@implementation ZZDrawView0

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        //背景iv
        _bgImgView = [UIImageView new];
        _bgImgView.frame = self.bounds;
        [self addSubview:_bgImgView];
        
        //合成视图imageView
        _composeView = [UIImageView new];
        _composeView.frame = self.bounds;
//        _composeView.image = [self getAlphaImg];
        [self addSubview:_composeView];
        
        //画布（添加进合成视图里面）
        _canvasView = [ZZCanvas new];
        _canvasView.frame = _composeView.bounds;
        [_composeView addSubview:_canvasView];
        
        //数组
        _brushArray = [NSMutableArray new];
        _undoArray = [NSMutableArray new];
        _redoArray = [NSMutableArray new];
        
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
        [self cleanRedoArray];
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
        brushModel.timeOffset = last_timeOffset;//前时间偏移
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
    
    //★作图★
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
    
    //★作图★
    //进度路径
    if (_isEraser) {
        [brush.bezierPath addLineToPoint:point];
        [self setEraserMode:brush];
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
                brush.bezierPath = [UIBezierPath bezierPathWithOvalInRect:[self getRectWithStartPoint:brush.beginPoint endPoint:point]];
                break;
            case ZZShapeRect:
                brush.bezierPath = [UIBezierPath bezierPathWithRect:[self getRectWithStartPoint:brush.beginPoint endPoint:point]];
                break;
            default:
                break;
        }
    }
    //在画布上画线
    [_canvasView setBrush:brush];
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

    //画布view与合成view 合成为一张图（使用融合卡）
    UIImage *img = [self composeBrushToImage];
    //保存到存储，撤销用。
    [self saveTempPic:img];
    
    //★作图★
    //清空画布
    [_canvasView setBrush:nil];
    
    
    //☂︎
    //记录下此次touchesEnd终点时间值
    _beginDate = [NSDate date];
    
    //☂︎
    if (!event) {
        [self drawNextPackage];
    }
}

#pragma mark - 辅助方法
//根据两个点弄出一个Rect
- (CGRect)getRectWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    CGFloat x = startPoint.x <= endPoint.x ? startPoint.x: endPoint.x;
    CGFloat y = startPoint.y <= endPoint.y ? startPoint.y : endPoint.y;
    CGFloat width = fabs(startPoint.x - endPoint.x);
    CGFloat height = fabs(startPoint.y - endPoint.y);
    
    return CGRectMake(x , y , width, height);
}

//擦除brush
- (void)setEraserMode:(ZZBrushModel*)brush
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0);
    
    [_composeView.image drawInRect:self.bounds];
    
    [[UIColor clearColor] set];//背景无色
    
    brush.bezierPath.lineWidth = _brushWidth;
    [brush.bezierPath strokeWithBlendMode:kCGBlendModeClear alpha:1.0];//clear清理
    
    [brush.bezierPath stroke];
    
    _composeView.image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
}

//合成image
- (UIImage *)composeBrushToImage
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [_composeView.layer renderInContext:context];
    
    UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    _composeView.image = getImage;
    
    return getImage;
}
//保存临时沙盒路径
- (void)saveTempPic:(UIImage*)img
{
    if (img) {
        //这里切换线程处理
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
            [dateformatter setDateFormat:@"HHmmssSSS"];
            NSString *now = [dateformatter stringFromDate:[NSDate date]];
            
            NSString *picPath = [NSString stringWithFormat:@"%@%@",[NSHomeDirectory() stringByAppendingFormat:@"/tmp/"], now];
            NSLog(@"存贮于   = %@",picPath);
            
            BOOL bSucc = NO;
            NSData *imgData = UIImagePNGRepresentation(img);
            if (imgData) {
                bSucc = [imgData writeToFile:picPath atomically:YES];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bSucc) {
                    [_undoArray addObject:picPath];
                }
            });
        });
    }
}


#pragma mark - 外部方法
- (void)unDo
{
    if (_undoArray.count > 0) {
        NSString *lastPath = [_undoArray lastObject];
        [_undoArray removeLastObject];
        [_redoArray addObject:lastPath];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *unDoImage = nil;
            if (_undoArray.count > 0) {
                NSString *unDoPicStr = [_undoArray lastObject];
                NSData *imgData = [NSData dataWithContentsOfFile:unDoPicStr];
                if (imgData) {
                    unDoImage = [UIImage imageWithData:imgData];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _composeView.image = unDoImage;
            });
        });
        
        //♻︎
        ZZActionModel *actionModel = [ZZActionModel new];
        actionModel.ActionType = ZZDrawActionUndo;
        [self addModelToPackage:actionModel];
    }
}

- (void)reDo
{
    if (_redoArray.count > 0) {
        NSString *lastPath = [_redoArray lastObject];
        [_redoArray removeLastObject];
        [_undoArray addObject:lastPath];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *unDoImage = nil;
            NSData *imgData = [NSData dataWithContentsOfFile:lastPath];
            if (imgData) {
                unDoImage = [UIImage imageWithData:imgData];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (unDoImage) {
                    _composeView.image = unDoImage;
                }
            });
        });
        
        //♻︎
        ZZActionModel *actionModel = [ZZActionModel new];
        actionModel.ActionType = ZZDrawActionRedo;
        [self addModelToPackage:actionModel];
    }
}

- (void)save
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.layer renderInContext:context];
    
    UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIImageWriteToSavedPhotosAlbum(getImage, nil, nil, nil);
    UIGraphicsEndImageContext();
    
    //♻︎
    ZZActionModel *actionModel = [ZZActionModel new];
    actionModel.ActionType = ZZDrawActionSave;
    [self addModelToPackage:actionModel];
}

- (void)clean
{
    _composeView.image = nil;

    [_brushArray removeAllObjects];
    //删除存储的文件
    [self cleanUndoArray];
    [self cleanRedoArray];
    
    //♻︎
    ZZActionModel *actionModel = [ZZActionModel new];
    actionModel.ActionType = ZZDrawActionClean;
    [self addModelToPackage:actionModel];
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

#pragma mark - 内部：辅助方法：清理辅助方法
- (void)deleteTempPic:(NSString *)picPath
{
    NSFileManager* fileManager=[NSFileManager defaultManager];
     [fileManager removeItemAtPath:picPath error:nil];
}

- (void)cleanUndoArray
{
    for (NSString *picPath in _undoArray) {
        [self deleteTempPic:picPath];
    }
    [_undoArray removeAllObjects];
}

- (void)cleanRedoArray
{
    for (NSString *picPath in _redoArray) {
        [self deleteTempPic:picPath];
    }
    [_redoArray removeAllObjects];
}

#pragma mark - dealloc
- (void)dealloc
{
    [self clean];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    if (backgroundImage) {
        _bgImgView.image = backgroundImage;
    }
}

- (void)layoutSubviews
{
    _bgImgView.frame = self.bounds;
    _composeView.frame = self.bounds;
    _canvasView.frame = self.bounds;
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
    {
        _composeView.image = nil;
        
        [_brushArray removeAllObjects];
        //删除存储的文件
        [self cleanUndoArray];
        [self cleanRedoArray];
    }
    //清除且还原
    _recPackageArray = nil;//zz
    
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
                            [self performSelector:@selector(actionReDo) withObject:nil afterDelay:packageOffset];
                            break;
                        case ZZDrawActionUndo:
                            [self performSelector:@selector(actionUnDo) withObject:nil afterDelay:packageOffset];
                            break;
                        case ZZDrawActionSave:
                            [self performSelector:@selector(actionSave) withObject:nil afterDelay:packageOffset];
                            break;
                        case ZZDrawActionClean:
                            [self performSelector:@selector(actionClean) withObject:nil afterDelay:packageOffset];
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

- (void)drawWithBrushModel_begin:(ZZDrawModel*)drawModel
{
    ZZBrushModel *brushModel = (ZZBrushModel*)drawModel;
    if (brushModel.beginPointM) {
        [self setDrawingBrush:brushModel];
        [self drawBeginPoint:brushModel.beginPoint];
    }
}

- (void)drawWithBrushModel_end:(ZZDrawModel*)drawModel
{
    ZZBrushModel *brushModel = (ZZBrushModel*)drawModel;
    [self drawEndPoint:brushModel.endPoint];
}

- (void)drawWithPointModel:(ZZDrawModel*)drawModel
{
    ZZPointModel *pointModel = (ZZPointModel*)drawModel;
    [self drawMovePoint:CGPointMake(pointModel.xPoint, pointModel.yPoint)];
}

- (void)setDrawingBrush:(ZZBrushModel*) brushModel
{
    if (brushModel) {
        _brushColor = brushModel.brushColor;
        _brushWidth = brushModel.brushWidth;
        _shapeType  = brushModel.shapeType;
        _isEraser   = brushModel.isEraser;
    }
}

- (void)drawBeginPoint:(CGPoint) point
{
    [self brush_touchesBegan:point withEvent:nil];
}

- (void)drawMovePoint:(CGPoint) point
{
    [self brush_touchesMoved:point withEvent:nil];
}

- (void)drawEndPoint:(CGPoint) point
{
     [self brush_touchesEnded:point withEvent:nil];
}

#pragma mark - 回放：Action

- (void)actionUnDo
{
    if (_undoArray.count > 0) {
        NSString *lastPath = [_undoArray lastObject];
        [_undoArray removeLastObject];
        [_redoArray addObject:lastPath];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *unDoImage = nil;
            if (_undoArray.count > 0) {
                NSString *unDoPicStr = [_undoArray lastObject];
                NSData *imgData = [NSData dataWithContentsOfFile:unDoPicStr];
                if (imgData) {
                    unDoImage = [UIImage imageWithData:imgData];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _composeView.image = unDoImage;
            });
        });
        
        [self drawNextPackage];
    }
}

- (void)actionReDo
{
    if (_redoArray.count > 0) {
        NSString *lastPath = [_redoArray lastObject];
        [_redoArray removeLastObject];
        [_undoArray addObject:lastPath];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *unDoImage = nil;
            NSData *imgData = [NSData dataWithContentsOfFile:lastPath];
            if (imgData) {
                unDoImage = [UIImage imageWithData:imgData];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (unDoImage) {
                    _composeView.image = unDoImage;
                }
            });
        });
    
        [self drawNextPackage];
    }
}
- (void)actionSave
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.layer renderInContext:context];
    
    UIImage *getImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIImageWriteToSavedPhotosAlbum(getImage, nil, nil, nil);
    UIGraphicsEndImageContext();
    
    
    [self drawNextPackage];
}

- (void)actionClean
{
    _composeView.image = nil;
    
    [_brushArray removeAllObjects];
    //删除存储的文件
    [self cleanUndoArray];
    [self cleanRedoArray];
    
    
    [self drawNextPackage];
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




//
//  ZZDrawViewSettingBoard.m
//  ZZDrawView_Example
//
//  Created by PengZhiZhong on 2018/12/17.
//  Copyright © 2018 pengzz. All rights reserved.
//

#import "ZZDrawViewSettingBoard.h"
#import "UIColor+help.h"
#import "YYModel.h"
#import "ZZBallColorModel.h"

#define kCollectionViewHeight 42
#define kBallViewHeight 30//15//69
#define kbuttonsView 100+10

#define kZZDrawViewSettingBoard_Height (kCollectionViewHeight+kBallViewHeight+kbuttonsView)

////16进制颜色值转换
//#define KUIColorFromRGB(rgbValue) [UIColor \
//colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
//green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
//blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
////16进制颜色值转换+alpha
//#define KUIColorFromARGB(argbValue) [UIColor \
//colorWithRed:((float)((argbValue & 0xFF0000) >> 16))/255.0 \
//green:((float)((argbValue & 0xFF00) >> 8))/255.0 \
//blue:((float)((argbValue & 0xFF) >> 0))/255.0 \
//alpha:((float)((argbValue & 0xFF000000) >> 24))/255.0]



@interface ZZDrawViewSettingBoard()<UICollectionViewDataSource,UICollectionViewDelegate>
{
    NSIndexPath *_lastIndexPath;
}
@property(nonatomic, strong)UICollectionView *collectionView;//主collectionView
@property(nonatomic, strong)NSMutableArray*dataArray;//存数据的数组

@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) NSArray *colorSelectModels;

@property (nonatomic, strong) ZZColorBall *ballView;

@property (nonatomic, strong) UISlider *sliderView;

////@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
//@property (weak, nonatomic) IBOutlet UICollectionView *collectionImageBoardView;
//@property (weak, nonatomic) IBOutlet UIButton *pickImageButton;
////@property (weak, nonatomic) IBOutlet HBBackImageBoard *backImageView;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttomViewH;
//@property (weak, nonatomic) IBOutlet UIView *buttomView;
////@property (nonatomic, copy) boardSettingBlock stype;
//@property (weak, nonatomic) IBOutlet UIView *centerView;
@end

@implementation ZZDrawViewSettingBoard

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    /*
//    CGFloat normalW = self.frame.size.width * 0.25;
//
//    UIButton *btn = [self.buttomView.subviews firstObject];
//
//    self.buttomViewH.constant = normalW * btn.currentImage.size.height / btn.currentImage.size.width;
    */
    
    if (!_lastIndexPath){
        //设置默认是属性
        [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        self.ballView.ballSize = 0;
    }
    
}


- (void)initSubViews {
    [self configCollectionView];
    
    [self initBallView];
    
    [self initButtons];
}

- (void)configCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];//UICollectionView需要在创建的时候传入一个布局参数，故在创建它之前，先创建一个布局，这里使用系统的布局就好
    [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];//设置滑动方向为水平方向，也可以设置为竖直方向
    layout.itemSize=CGSizeMake(kCollectionViewHeight, kCollectionViewHeight);//设置CollectionView中每个item及集合视图中每单个元素的大小，我们每个视图使用一页来显示，所以设置为当前视图的大小
    layout.minimumInteritemSpacing=10;//设置item之间最小间距
    layout.minimumLineSpacing=22;//设置item之间最下行距
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetMaxX(self.bounds), kCollectionViewHeight) collectionViewLayout:layout];//创建一个集合视图，设置其大小为当前view的大小，布局为上面我们创建的布局
    _collectionView.backgroundColor = [UIColor darkGrayColor];
    //_collectionView.contentInset = UIEdgeInsetsMake(3, 22, 13, 22);
    _collectionView.contentInset = UIEdgeInsetsMake(0, 22, 0, 22);
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.pagingEnabled = YES;
    _collectionView.scrollsToTop = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.alwaysBounceHorizontal = YES;//而如果不设置contentSize，也想要有弹簧效果，那么需要设置
    //_collectionView.alwaysBounceVertical = YES;  //而如果不设置contentSize，也想要有弹簧效果，那么需要设置
    _collectionView.contentOffset = CGPointMake(0, 0);
    //_collectionView.contentSize = CGSizeMake(self.dataArray.count * (self.view.frame.size.width + 20), 0);//这一句不要好像也可以的
    [self addSubview:_collectionView];
    //[_collectionView registerClass:[PDFCollectionViewCell class]forCellWithReuseIdentifier:@"PDFCollectionViewCell"];//为集合视图注册单元格
    
    [_collectionView registerClass:[UICollectionViewCell class]forCellWithReuseIdentifier:NSStringFromClass([UICollectionViewCell class])];//为集合视图注册单元格
}

#pragma mark - collectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.colorSelectModels.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([UICollectionViewCell class]) forIndexPath:indexPath];
    
    ZZBallColorModel *model = self.colorSelectModels[indexPath.item];
    cell.backgroundColor = [UIColor colorWithHexString:self.colors[[model.ballColor integerValue]]];
    cell.layer.cornerRadius = 3;
    if (model.isBallColor) {
        cell.layer.borderWidth = 3;
        cell.layer.borderColor = [UIColor purpleColor].CGColor;
    } else {
        cell.layer.borderWidth = 0;
    }
    cell.layer.masksToBounds = YES;
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_lastIndexPath) {
        ZZBallColorModel *lastModel = self.colorSelectModels[_lastIndexPath.item];
        lastModel.isBallColor = NO;
        [self.collectionView reloadItemsAtIndexPaths:@[_lastIndexPath]];
    }
    _lastIndexPath = indexPath;
    
    ZZBallColorModel *model = self.colorSelectModels[indexPath.item];
    self.ballView.ballColor = [UIColor colorWithHexString:self.colors[[model.ballColor integerValue]]];;
    model.isBallColor = YES;
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    //
    self.drawView.brushColor = self.ballView.ballColor;
}

#pragma mark - lazy
- (NSArray *)colorSelectModels
{
    if (!_colorSelectModels) {
        //        isBallColor
        NSDictionary *dic1 = [NSDictionary dictionaryWithObjectsAndKeys:@(0),@"ballColor", nil];
        NSDictionary *dic2 = [NSDictionary dictionaryWithObjectsAndKeys:@(1),@"ballColor", nil];
        NSDictionary *dic3 = [NSDictionary dictionaryWithObjectsAndKeys:@(2),@"ballColor", nil];
        NSDictionary *dic4 = [NSDictionary dictionaryWithObjectsAndKeys:@(3),@"ballColor", nil];
        NSDictionary *dic5 = [NSDictionary dictionaryWithObjectsAndKeys:@(4),@"ballColor", nil];
        NSDictionary *dic6 = [NSDictionary dictionaryWithObjectsAndKeys:@(5),@"ballColor", nil];
        NSDictionary *dic7 = [NSDictionary dictionaryWithObjectsAndKeys:@(6),@"ballColor", nil];
        /*
        NSArray *array = [NSArray arrayWithObjects:dic1,
                          dic2,
                          dic3,
                          dic4,
                          dic5,
                          dic6,
                          dic7,
                          nil];
        _colorSelectModels = [ZZBallColorModel objectArrayWithKeyValuesArray:array];
         */
        
        NSArray *array = [NSArray arrayWithObjects:
                          [ZZBallColorModel yy_modelWithDictionary:dic1],
                          [ZZBallColorModel yy_modelWithDictionary:dic2],
                          [ZZBallColorModel yy_modelWithDictionary:dic3],
                          [ZZBallColorModel yy_modelWithDictionary:dic4],
                          [ZZBallColorModel yy_modelWithDictionary:dic5],
                          [ZZBallColorModel yy_modelWithDictionary:dic6],
                          [ZZBallColorModel yy_modelWithDictionary:dic7],
                          nil];
        _colorSelectModels = array;
    }
    return _colorSelectModels;
}
- (NSArray *)colors
{
    if (!_colors) {
        _colors = [NSArray arrayWithObjects:
                   @"#ed4040",
                   @"#f5973c",
                   @"#efe82e",
                   @"#7ce331",
                   @"#48dcde",
                   @"#2877e3",
                   @"#9b33e4",
                   nil];
    }
    return _colors;
}

#pragma mark - initBallView
- (void)initBallView {
    //
    self.ballView = [[ZZColorBall alloc] initWithFrame:CGRectMake(10, kCollectionViewHeight, kBallViewHeight, kBallViewHeight)];
    [self addSubview:self.ballView];
    
    //
    self.sliderView = [[UISlider alloc] initWithFrame:CGRectMake(10+CGRectGetMaxX(self.ballView.frame), kCollectionViewHeight, CGRectGetMaxX(self.bounds)-CGRectGetMaxX(self.ballView.frame)-10-10, kBallViewHeight)];
    self.sliderView.minimumValue = 0;
    self.sliderView.maximumValue = 1;
    self.sliderView.thumbTintColor = [UIColor orangeColor];
    [self.sliderView addTarget:self action:@selector(sliderView:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.sliderView];
}

- (IBAction)sliderView:(UISlider *)sender {
    
    self.ballView.ballSize = sender.value;
    self.drawView.brushWidth = self.ballView.lineWidth;
}

#pragma mark - initButtons

- (void)initButtons {
    
    UIView *buttonsView = [[UIView alloc] initWithFrame:CGRectMake(0, kCollectionViewHeight+kBallViewHeight, CGRectGetMaxX(self.bounds), kbuttonsView)];
    [self addSubview:buttonsView];
    UIView *self_view = buttonsView;
    
    //工具栏
    
    UIButton *btnUndo = [UIButton buttonWithType:UIButtonTypeCustom];
    btnUndo.backgroundColor = [UIColor orangeColor];
    btnUndo.frame = CGRectMake(20, 20+0, 60, 20);
    [btnUndo setTitle:@"撤销" forState:UIControlStateNormal];
    [btnUndo addTarget:self action:@selector(btnUndoClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self_view addSubview:btnUndo];
    
    UIButton *btnRedo = [UIButton buttonWithType:UIButtonTypeCustom];
    btnRedo.backgroundColor = [UIColor orangeColor];
    btnRedo.frame = CGRectMake(100, 20+0, 60, 20);
    [btnRedo setTitle:@"重做" forState:UIControlStateNormal];
    [btnRedo addTarget:self action:@selector(btnRedoClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self_view addSubview:btnRedo];
    
    UIButton *btnSave = [UIButton buttonWithType:UIButtonTypeCustom];
    btnSave.backgroundColor = [UIColor orangeColor];
    btnSave.frame = CGRectMake(180, 20+0, 60, 20);
    [btnSave setTitle:@"保存" forState:UIControlStateNormal];
    [btnSave addTarget:self action:@selector(btnSaveClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self_view addSubview:btnSave];
    
    UIButton *btnClean = [UIButton buttonWithType:UIButtonTypeCustom];
    btnClean.backgroundColor = [UIColor orangeColor];
    btnClean.frame = CGRectMake(260, 20+0, 60, 20);
    [btnClean setTitle:@"清除" forState:UIControlStateNormal];
    [btnClean addTarget:self action:@selector(btnCleanClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self_view addSubview:btnClean];
    
    UIButton *btnCurve = [UIButton buttonWithType:UIButtonTypeCustom];
    btnCurve.backgroundColor = [UIColor orangeColor];
    btnCurve.frame = CGRectMake(20, 50+0, 60, 20);
    [btnCurve setTitle:@"曲线" forState:UIControlStateNormal];
    [btnCurve addTarget:self action:@selector(btnCurveClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self_view addSubview:btnCurve];
    
    UIButton *btnLine = [UIButton buttonWithType:UIButtonTypeCustom];
    btnLine.backgroundColor = [UIColor orangeColor];
    btnLine.frame = CGRectMake(100, 50+0, 60, 20);
    [btnLine setTitle:@"直线" forState:UIControlStateNormal];
    [btnLine addTarget:self action:@selector(btnLineClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self_view addSubview:btnLine];
    
    UIButton *btnEllipse = [UIButton buttonWithType:UIButtonTypeCustom];
    btnEllipse.backgroundColor = [UIColor orangeColor];
    btnEllipse.frame = CGRectMake(180, 50+0, 60, 20);
    [btnEllipse setTitle:@"椭圆" forState:UIControlStateNormal];
    [btnEllipse addTarget:self action:@selector(btnEllipseClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self_view addSubview:btnEllipse];
    
    UIButton *btnRect = [UIButton buttonWithType:UIButtonTypeCustom];
    btnRect.backgroundColor = [UIColor orangeColor];
    btnRect.frame = CGRectMake(260, 50+0, 60, 20);
    [btnRect setTitle:@"矩形" forState:UIControlStateNormal];
    [btnRect addTarget:self action:@selector(btnRectClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self_view addSubview:btnRect];
    
    UIButton *btnRec = [UIButton buttonWithType:UIButtonTypeCustom];
    btnRec.backgroundColor = [UIColor orangeColor];
    btnRec.frame = CGRectMake(20, 80+0, 60, 20);
    [btnRec setTitle:@"录制" forState:UIControlStateNormal];
    [btnRec addTarget:self action:@selector(btnRecClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self_view addSubview:btnRec];
    
    UIButton *btnPlay = [UIButton buttonWithType:UIButtonTypeCustom];
    btnPlay.backgroundColor = [UIColor orangeColor];
    btnPlay.frame = CGRectMake(100, 80+0, 60, 20);
    [btnPlay setTitle:@"绘制" forState:UIControlStateNormal];
    [btnPlay addTarget:self action:@selector(btnPlayClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self_view addSubview:btnPlay];
    
    UIButton *btnEraser = [UIButton buttonWithType:UIButtonTypeCustom];
    btnEraser.backgroundColor = [UIColor orangeColor];
    btnEraser.frame = CGRectMake(180, 80+0, 60, 20);
    [btnEraser setTitle:@"橡皮擦" forState:UIControlStateNormal];
    [btnEraser setTitle:@"画笔" forState:UIControlStateSelected];
    [btnEraser addTarget:self action:@selector(btnEraserClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self_view addSubview:btnEraser];
    
}

//撤销
- (void)btnUndoClicked:(id)sender
{
    [self.drawView unDo];
}
//重做
- (void)btnRedoClicked:(id)sender
{
    [self.drawView reDo];
}
//保存
- (void)btnSaveClicked:(id)sender
{
    [self.drawView save];
}
//清除
- (void)btnCleanClicked:(id)sender
{
    [self.drawView clean];
}

//曲线
- (void)btnCurveClicked:(id)sender
{
    self.drawView.shapeType = ZZShapeCurve;
}
//直线
- (void)btnLineClicked:(id)sender
{
    self.drawView.shapeType = ZZShapeLine;
}
//椭圆
- (void)btnEllipseClicked:(id)sender
{
    self.drawView.shapeType = ZZShapeEllipse;
}
//矩形
- (void)btnRectClicked:(id)sender
{
    self.drawView.shapeType = ZZShapeRect;
}

//录制
- (void)btnRecClicked:(id)sender
{
    //[self.drawView testRecToFile:nil];
    [self.drawView storeBrushes:nil];
}
//‘绘制
- (void)btnPlayClicked:(id)sender
{
    //[self.drawView testPlayFromFile:nil];
    [self.drawView reDrawBrushes:nil];
}

//橡皮擦/画笔
- (void)btnEraserClicked:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    if (btn.selected) {
        btn.selected = NO;
        
        //使用画笔
        self.drawView.isEraser = NO;
    } else {
        btn.selected = YES;
        
        //使用橡皮擦
        self.drawView.isEraser = YES;
    }
}




/*
- (void)getSettingType:(boardSettingBlock)type
{
    self.stype = type;
}
- (CGFloat)getLineWidth
{
    return self.ballView.lineWidth;
}
- (UIColor *)getLineColor
{
    return self.ballView.ballColor;
}
 
- (IBAction)penSetting:(id)sender {
    
    self.backImageView.hidden = YES;
    self.centerView.hidden = self.collectionView.hidden = NO;
    
    if (self.stype) {
        self.stype(setTypePen);
    }
}
- (IBAction)openCamera:(id)sender {
    
    if (self.stype) {
        self.stype(setTypeCamera);
    }
}
- (IBAction)openAlbum:(UIButton *)sender {
    
    
    self.backImageView.hidden = NO;
    self.centerView.hidden = self.collectionView.hidden = YES;
    
    if (sender.tag) return;
    
    if (self.stype) {
        self.stype(setTypeAlbum);
    }
    
}
- (IBAction)saveImage:(id)sender {
    
    if (self.stype) {
        self.stype(setTypeSave);
    }
}
- (IBAction)eraser:(id)sender {
    
    if (self.stype) {
        self.stype(setTypeEraser);
    }
}
- (IBAction)back:(id)sender {
    
    if (self.stype) {
        self.stype(setTypeBack);
    }
}
- (IBAction)revocation:(id)sender {
    
    if (self.stype) {
        self.stype(setTyperegeneration);
    }
}
- (IBAction)clearAll:(id)sender {
    
    if (self.stype) {
        self.stype(setTypeClearAll);
    }
}
- (IBAction)sliderView:(UISlider *)sender {
    
    self.ballView.ballSize = sender.value;
}
*/

@end


@interface ZZColorBall()
@property (nonatomic, strong) CAShapeLayer *shape;
@end

@implementation ZZColorBall

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor clearColor];
    [self.layer addSublayer:self.shape];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self.layer addSublayer:self.shape];
    }
    return self;
}

- (void)setBallColor:(UIColor *)ballColor
{
    _ballColor = ballColor;
    
    self.shape.fillColor = self.ballColor.CGColor;
}
- (void)setBallSize:(CGFloat)ballSize
{
    _ballSize = ballSize;
    
    //缩放
    CGFloat vaule = 0.3 * (1 - ballSize) + ballSize;
    self.transform = CGAffineTransformMakeScale(vaule, vaule);
    
    NSLog(@"画笔宽度:%.f",self.frame.size.width / 2.0);
    
    self.lineWidth = self.frame.size.width / 2.0;
    
}
- (CAShapeLayer *)shape
{
    if (!_shape) {
        _shape = [[CAShapeLayer alloc] init];
        _shape.path = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
    }
    return _shape;
}

@end

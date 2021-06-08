//
//  TIoTDemoPreviewDeviceVC.m
//  LinkSDKDemo
//
//  Created by ccharlesren on 2021/6/5.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TIoTDemoPreviewDeviceVC.h"
#import "TIoTDemoPlaybackCustomCell.h"
#import "TIoTDemoCustomSheetView.h"
#import "AppDelegate.h"
#import "UIDevice+TIoTDemoRotateScreen.h"
#import "NSDate+TIoTCustomCalendar.h"

static CGFloat const kPadding = 16;
static NSString *const kPreviewDeviceCellID = @"kPreviewDeviceCellID";
static CGFloat const kScreenScale = 0.5625; //9/16 高宽比

@interface TIoTDemoPreviewDeviceVC ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, assign) CGRect screenRect;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *actionBottomView; //功能操作底层view
@property (nonatomic, strong) UITableView *tableView; //事件列表
@property (nonatomic, strong) NSMutableArray *dataArray; //事件列表
@property (nonatomic, strong) UIImageView *talkbackIcon;
@property (nonatomic, strong) UIImageView *videoIcon;
@property (nonatomic, strong) UIView *videoingView; //录像中提示view
@property (nonatomic, strong) UIView *landscapeChangeDefinition; //横屏时清晰度选择视图

@property (nonatomic, strong) UIButton *definitionBtn; //竖屏-切换清晰度按钮
@property (nonatomic, strong) UIButton *voiceBtn;
@property (nonatomic, strong) UIButton *rotateBtn;

@property (nonatomic, strong) UIButton *standardDef; //横屏-切换清晰度按钮
@property (nonatomic, strong) UIButton *highDef;
@property (nonatomic, strong) UIButton *supperDef;
@end

@implementation TIoTDemoPreviewDeviceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.screenRect = [UIApplication sharedApplication].delegate.window.frame;
    
    [self addRotateNotification];
    
    [self setupPreViewViews];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    [self recoverNavigationBar];
    
    [self ratetePortrait];
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [[UIDevice currentDevice]endGeneratingDeviceOrientationNotifications];
}

- (void)addRotateNotification {
    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleOrientationChange:)
                                                name:UIDeviceOrientationDidChangeNotification object:nil];
    
}

- (void)setupPreViewViews {
    
    self.view.backgroundColor = [UIColor colorWithHexString:kVideoDemoBackgoundColor];
    
    [self initializedVideo];
    
    [self initVideoParamView];
    
    CGFloat actionViewHeight = 160;
    
    //操作功能底层view
    self.actionBottomView = [[UIView alloc]init];
    self.actionBottomView.backgroundColor = [UIColor colorWithHexString:kVideoDemoBackgoundColor];
    [self.view addSubview:self.actionBottomView];
    [self.actionBottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageView.mas_bottom).offset(kPadding);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(actionViewHeight);
    }];
    
    //对讲、录像、回放、拍照 方向
    //对讲功能
    CGFloat kActionViewHeight = (actionViewHeight-20)/2;
    CGFloat kActionViewWidth = (kScreenWidth-kPadding-100)/2;
    CGFloat kActionIconSize = 24;
    CGFloat kActionIconLeftPadding = 28;
    CGFloat kActionIconTopPadding = 4;
    
    UIImageView *talkbackImage = [[UIImageView alloc]init];
    talkbackImage.image = [UIImage imageNamed:@"talkback"];
    [self.actionBottomView addSubview:talkbackImage];
    [talkbackImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.actionBottomView.mas_top);
        make.left.equalTo(self.actionBottomView.mas_left).offset(kPadding);
        make.height.mas_equalTo(kActionViewHeight);
        make.width.mas_equalTo(kActionViewWidth);
    }];
    
    UIButton *talkbackBtn = [[UIButton alloc]init];
    [talkbackBtn addTarget:self action:@selector(clickTalkback:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBottomView addSubview:talkbackBtn];
    [talkbackBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.equalTo(talkbackImage);
    }];
    
    self.talkbackIcon = [[UIImageView alloc]init];
    self.talkbackIcon.image = [UIImage imageNamed:@"talkback_unselect"];
    [talkbackBtn addSubview:self.talkbackIcon];
    [self.talkbackIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kActionIconSize);
        make.bottom.equalTo(talkbackBtn.mas_centerY);
        make.left.equalTo(talkbackBtn.mas_left).offset(kActionIconLeftPadding);
    }];
    
    UILabel *talkbackLabel = [[UILabel alloc]init];
    [talkbackLabel setLabelFormateTitle:@"对讲" font:[UIFont wcPfRegularFontOfSize:12] titleColorHexString:kVideoDemoDateTipTextColor textAlignment:NSTextAlignmentCenter];
    [talkbackBtn addSubview:talkbackLabel];
    [talkbackLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.talkbackIcon);
        make.top.equalTo(self.talkbackIcon.mas_bottom).offset(kActionIconTopPadding);
    }];

    //回放功能
    UIButton *playbackBtn = [[UIButton alloc]init];
    [playbackBtn setImage:[UIImage imageNamed:@"playback"] forState:UIControlStateNormal];
    [playbackBtn setImage:[UIImage imageNamed:@"playback"] forState:UIControlStateHighlighted];
    [playbackBtn addTarget:self action:@selector(clickPlayback:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBottomView addSubview:playbackBtn];
    [playbackBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.actionBottomView);
        make.left.equalTo(talkbackBtn);
        make.height.width.equalTo(talkbackBtn);
    }];
    
    UIImageView *playbackIcon = [[UIImageView alloc]init];
    playbackIcon.image = [UIImage imageNamed:@"playback_icon"];
    [playbackBtn addSubview:playbackIcon];
    [playbackIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kActionIconSize);
        make.bottom.equalTo(playbackBtn.mas_centerY);
        make.left.equalTo(playbackBtn.mas_left).offset(kActionIconLeftPadding);
    }];
    
    UILabel *playbackLabel = [[UILabel alloc]init];
    [playbackLabel setLabelFormateTitle:@"回看" font:[UIFont wcPfRegularFontOfSize:12] titleColorHexString:kVideoDemoDateTipTextColor textAlignment:NSTextAlignmentCenter];
    [playbackBtn addSubview:playbackLabel];
    [playbackLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(playbackIcon);
        make.top.equalTo(playbackIcon.mas_bottom).offset(kActionIconTopPadding);
    }];

    //录像
    UIImageView *videoImage = [[UIImageView alloc]init];
    videoImage.image = [UIImage imageNamed:@"video"];
    [self.actionBottomView addSubview:videoImage];
    [videoImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.actionBottomView.mas_top);
        make.right.equalTo(self.actionBottomView.mas_right).offset(-kPadding);
        make.height.width.equalTo(talkbackBtn);
    }];
    
    UIButton *videoBtn = [[UIButton alloc]init];
    [videoBtn addTarget:self action:@selector(clickVideoBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBottomView addSubview:videoBtn];
    [videoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.left.right.equalTo(videoImage);
    }];
    
    self.videoIcon = [[UIImageView alloc]init];
    self.videoIcon.image = [UIImage imageNamed:@"video_unselect"];
    [videoBtn addSubview:self.videoIcon];
    [self.videoIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kActionIconSize);
        make.bottom.equalTo(videoBtn.mas_centerY);
        make.right.equalTo(videoBtn.mas_right).offset(-kActionIconLeftPadding);
    }];
    
    UILabel *videoLabel = [[UILabel alloc]init];
    [videoLabel setLabelFormateTitle:@"录像" font:[UIFont wcPfRegularFontOfSize:12] titleColorHexString:kVideoDemoDateTipTextColor textAlignment:NSTextAlignmentCenter];
    [videoBtn addSubview:videoLabel];
    [videoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.videoIcon);
        make.top.equalTo(self.videoIcon.mas_bottom).offset(kActionIconTopPadding);
    }];

    //拍照
    UIButton *photographImage = [[UIButton alloc]init];
    [photographImage setImage:[UIImage imageNamed:@"photograph"] forState:UIControlStateNormal];
    [photographImage setImage:[UIImage imageNamed:@"photograph"] forState:UIControlStateHighlighted];
    [photographImage addTarget:self action:@selector(clickPhotograph) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBottomView addSubview:photographImage];
    [photographImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.actionBottomView.mas_bottom);
        make.right.equalTo(videoBtn.mas_right);
        make.height.width.equalTo(talkbackBtn);
    }];
    
    UIImageView *photographIcon = [[UIImageView alloc]init];
    photographIcon.image = [UIImage imageNamed:@"picture_icon"];
    [photographImage addSubview:photographIcon];
    [photographIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kActionIconSize);
        make.bottom.equalTo(photographImage.mas_centerY);
        make.right.equalTo(videoBtn.mas_right).offset(-kActionIconLeftPadding);
    }];
    
    UILabel *photographLabel = [[UILabel alloc]init];
    [photographLabel setLabelFormateTitle:@"拍照" font:[UIFont wcPfRegularFontOfSize:12] titleColorHexString:kVideoDemoDateTipTextColor textAlignment:NSTextAlignmentCenter];
    [photographImage addSubview:photographLabel];
    [photographLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(photographIcon);
        make.top.equalTo(photographIcon.mas_bottom).offset(kActionIconTopPadding);
    }];
    
    //方向控制
    UIImageView *actionDirectionImage = [[UIImageView alloc]init];
    actionDirectionImage.image = [UIImage imageNamed:@"action_direction"];
    [self.actionBottomView addSubview:actionDirectionImage];
    [actionDirectionImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.actionBottomView);
    }];
    
    //四个方向按钮
    CGFloat kBtnSize = 50;
    
    UIButton *upBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [upBtn addTarget:self action:@selector(turnUpDirection) forControlEvents:UIControlEventTouchUpInside];
    [actionDirectionImage addSubview:upBtn];
    [upBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(actionDirectionImage);
        make.top.equalTo(actionDirectionImage);
        make.width.height.mas_equalTo(kBtnSize);
    }];
    
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftBtn addTarget:self action:@selector(turnLeftDirection) forControlEvents:UIControlEventTouchUpInside];
    [actionDirectionImage addSubview:leftBtn];
    [leftBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(actionDirectionImage);
        make.width.height.mas_equalTo(kBtnSize);
        make.centerY.equalTo(actionDirectionImage);
    }];
    
    UIButton *downBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [downBtn addTarget:self action:@selector(turnDownDirection) forControlEvents:UIControlEventTouchUpInside];
    [actionDirectionImage addSubview:downBtn];
    [downBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(actionDirectionImage);
        make.centerX.equalTo(actionDirectionImage);
        make.width.height.mas_equalTo(kBtnSize);
    }];
    
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightBtn addTarget:self action:@selector(turnRightDirection) forControlEvents:UIControlEventTouchUpInside];
    [actionDirectionImage addSubview:rightBtn];
    [rightBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(actionDirectionImage);
        make.centerY.equalTo(actionDirectionImage);
        make.width.height.mas_equalTo(kBtnSize);
    }];
    
    NSString *weekValue = [[NSDate date] getWeekDayWithDate];
    UILabel *currentWeekTip = [[UILabel alloc]init];
    [currentWeekTip setLabelFormateTitle:[NSString stringWithFormat:@"今天 %@",weekValue] font:[UIFont wcPfRegularFontOfSize:17] titleColorHexString:kVideoDemoDateTipTextColor textAlignment:NSTextAlignmentLeft];
    [self.view addSubview:currentWeekTip];
    [currentWeekTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(kPadding);
        make.top.equalTo(self.actionBottomView.mas_bottom).offset(20);
    }];
    
    self.tableView = [[UITableView alloc]init];
    self.tableView.backgroundColor = [UIColor colorWithHexString:KActionSheetBackgroundColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[TIoTDemoPlaybackCustomCell class] forCellReuseIdentifier:kPreviewDeviceCellID];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(currentWeekTip.mas_bottom).offset(8);
        make.left.right.bottom.equalTo(self.view);
    }];
}

- (void)initializedVideo {
    self.imageView = [[UIImageView alloc] init];
    self.imageView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.imageView];
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.screenRect.size.width);
        make.height.mas_equalTo(self.screenRect.size.width*kScreenScale);
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        }else {
            make.top.equalTo(self.view).offset(64);
        }
    }];
    
    self.imageView.userInteractionEnabled = YES;
}

- (void)initVideoParamView {
    
    //右上角录像提示view
    self.videoingView = [[UIView alloc]init];
    self.videoingView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.7];
    [self.imageView addSubview:self.videoingView];
    [self.videoingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.imageView);
        make.height.mas_equalTo(32);
        make.width.mas_equalTo(88);
    }];
    
    UIImageView *videoingIcon = [[UIImageView alloc]init];
    videoingIcon.image = [UIImage imageNamed:@"video_select"];
    [self.videoingView addSubview:videoingIcon];
    [videoingIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(20);
        make.centerY.equalTo(self.videoingView);
        make.left.equalTo(self.videoingView.mas_left).offset(12);
    }];
    
    UILabel *videoingLabel = [[UILabel alloc]init];
    [videoingLabel setLabelFormateTitle:@"录制中" font:[UIFont wcPfRegularFontOfSize:12] titleColorHexString:@"#ffffff" textAlignment:NSTextAlignmentLeft];
    [self.videoingView addSubview:videoingLabel];
    [videoingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(videoingIcon.mas_right).offset(8);
        make.centerY.equalTo(self.videoingView);
    }];
    
    self.videoingView.hidden = YES;
    
    CGFloat kBrnSize = 32;
    CGFloat kPadding = 16;
    CGFloat kInterval = 10;
    
    //调节video参数 按钮
    self.rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rotateBtn setImage:[UIImage imageNamed:@"rotate_icon"] forState:UIControlStateNormal];
    [self.rotateBtn addTarget:self action:@selector(rotateScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.imageView addSubview:self.rotateBtn];
    [self.rotateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kBrnSize);
        make.bottom.equalTo(self.imageView.mas_bottom).offset(-10);
        make.right.equalTo(self.imageView.mas_right).offset(-kPadding);
    }];
    
    
    self.voiceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.voiceBtn setImage:[UIImage imageNamed:@"voice_open"] forState:UIControlStateNormal];
    [self.voiceBtn addTarget:self action:@selector(controlVoice:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageView addSubview:self.voiceBtn];
    [self.voiceBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kBrnSize);
        make.bottom.equalTo(self.rotateBtn.mas_bottom);
        make.right.equalTo(self.rotateBtn.mas_left).offset(-kInterval);
    }];

    self.definitionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.definitionBtn setButtonFormateWithTitlt:@"test" titleColorHexString:@"#ffffff" font:[UIFont wcPfRegularFontOfSize:12]];
    self.definitionBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    [self.definitionBtn addTarget:self action:@selector(changeVideoDefinitaion) forControlEvents:UIControlEventTouchUpInside];
    [self.imageView addSubview:self.definitionBtn];
    [self.definitionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(kBrnSize);
        make.bottom.equalTo(self.imageView.mas_bottom).offset(-10);
        make.right.equalTo(self.voiceBtn.mas_left).offset(-kInterval);
    }];
}

#pragma mark - action
///MARK: 对讲
- (void)clickTalkback:(UIButton *)button {
    if (!button.selected) {
        self.talkbackIcon.image = [UIImage imageNamed:@"talkback_select"];
    }else {
        self.talkbackIcon.image = [UIImage imageNamed:@"talkback_unselect"];
    }
    
    button.selected = !button.selected;
}
///MARK: 回放
- (void)clickPlayback:(UIButton *)button {
    
}
///MARK: 录像
- (void)clickVideoBtn:(UIButton *)button {
    if (!button.selected) {
        self.videoIcon.image = [UIImage imageNamed:@"video_select"];
        self.videoingView.hidden = NO;
    }else {
        self.videoIcon.image = [UIImage imageNamed:@"video_unselect"];
        self.videoingView.hidden = YES;
    }
    
    button.selected = !button.selected;
}
///MARK: 拍照
- (void)clickPhotograph {
    
}

#pragma mark - 控制video 显示
- (void)rotateScreen {
    AppDelegate * appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.isRotation == YES) {
        appDelegate.isRotation = NO;
        [self ratetePortrait];
    }else {
        appDelegate.isRotation = YES;
        [self rotateLandscapeRight];
    }
    [self resetScreenSubviewsWithLandscape:appDelegate.isRotation];
}

- (void)controlVoice:(UIButton *)button {
    if (!button.selected) {
        [button setImage:[UIImage imageNamed:@"voice_close"] forState:UIControlStateNormal];
    }else {
        [button setImage:[UIImage imageNamed:@"voice_open"] forState:UIControlStateNormal];
    }
    button.selected = !button.selected;
}

- (void)changeVideoDefinitaion {
    
    if ([UIDevice judgeScreenOrientationPortrait]) {
        //竖屏
        __weak typeof(self) weakSelf = self;
        TIoTDemoCustomSheetView *definitaionSheet = [[TIoTDemoCustomSheetView alloc]init];
        NSArray *actionTitleArray = @[@"超清 720P",@"高清 480P",@"标清 270P",@"取消"];
        ChooseFunctionBlock superDefinitaionBlock = ^(TIoTDemoCustomSheetView *view){
            [weakSelf.definitionBtn setTitle:@"超清" forState:UIControlStateNormal];
            [definitaionSheet removeFromSuperview];
        };
        
        ChooseFunctionBlock highDefinitionBlock = ^(TIoTDemoCustomSheetView *view){
            [weakSelf.definitionBtn setTitle:@"高清" forState:UIControlStateNormal];
            [definitaionSheet removeFromSuperview];
        };
        
        ChooseFunctionBlock standardDefinitionBlock = ^(TIoTDemoCustomSheetView *view){
            [weakSelf.definitionBtn setTitle:@"标清" forState:UIControlStateNormal];
            [definitaionSheet removeFromSuperview];
        };
        
        ChooseFunctionBlock cancelBlock = ^(TIoTDemoCustomSheetView *view) {
            NSLog(@"取消");
            [view removeFromSuperview];
        };
        
        NSArray *actionBlockArray = @[superDefinitaionBlock,highDefinitionBlock,standardDefinitionBlock,cancelBlock];
        
        [definitaionSheet sheetViewTopTitleArray:actionTitleArray withMatchBlocks:actionBlockArray];
        [[UIApplication sharedApplication].delegate.window addSubview:definitaionSheet];
        [definitaionSheet mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.leading.right.bottom.equalTo([UIApplication sharedApplication].delegate.window);
        }];
    }else {
        //横屏
        
        [self hideSettingVidoParamView];
        
        [self.view addSubview:self.landscapeChangeDefinition];
        [self.landscapeChangeDefinition mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.left.right.equalTo(self.view);
        }];
    }
}

#pragma mark - dirention action
- (void)turnUpDirection {
    
}

- (void)turnLeftDirection {
    
}

- (void)turnDownDirection {
    
}

- (void)turnRightDirection {
    
}

#pragma mark - handler orientation event
- (void)handleOrientationChange:(NSNotification *)notification {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    AppDelegate * appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:{
            //屏幕向左横置
            appDelegate.isRotation = YES;
            [self setNavigationBarTransparency];
            [self resetScreenSubviewsWithLandscape:YES];
            break;
            }
        case UIDeviceOrientationLandscapeRight: {
            //屏幕向右橫置
            appDelegate.isRotation = YES;
            [self setNavigationBarTransparency];
            [self resetScreenSubviewsWithLandscape:YES ];
            break;
        }
        case UIDeviceOrientationPortrait: {
            //屏幕直立
            appDelegate.isRotation = NO;
            [self resetScreenSubviewsWithLandscape:NO];
            break;
        }
        default:
            //无法辨识
            break;
    }
}

///MARK: viewarray 约束更新适配屏幕
- (void)resetScreenSubviewsWithLandscape:(BOOL)rotation {
    if (rotation == YES) { //横屏
        self.actionBottomView.hidden = YES;
        self.tableView.hidden = YES;
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.screenRect.size.width/kScreenScale);
            make.top.bottom.equalTo(self.view);
        }];
    }else { //竖屏
        if (self.definitionBtn.hidden == YES) {
            [self hideDefinitionView];
        }
        self.actionBottomView.hidden = NO;
        self.tableView.hidden = NO;
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.screenRect.size.width);
            make.height.mas_equalTo(self.screenRect.size.width*kScreenScale);
            make.centerX.equalTo(self.view);
            if (@available(iOS 11.0, *)) {
                make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            }else {
                make.top.equalTo(self.view).offset(64);
            }
        }];
    }
}

///MARK:横屏
- (void)rotateLandscapeRight {
    [self setNavigationBarTransparency];
    AppDelegate * appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.isRotation = YES;
    [UIDevice changeOrientation:UIInterfaceOrientationLandscapeRight];
}

///MARK:竖屏
- (void)ratetePortrait {
    [self recoverNavigationBar];
    AppDelegate * appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.isRotation = NO;
    [UIDevice changeOrientation:UIInterfaceOrientationPortrait];
}

///MARK: 设置导航栏透明
- (void)setNavigationBarTransparency {
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
}

///MARK: 恢复导航栏
- (void)recoverNavigationBar {
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:nil];
}

#pragma mark - UITableViewdelegate and UITableViewDataSrouce
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TIoTDemoPlaybackCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:kPreviewDeviceCellID forIndexPath:indexPath];
    return cell;
}

#pragma mark - lazy loading
- (UIView *)landscapeChangeDefinition {
    if (!_landscapeChangeDefinition) {
        _landscapeChangeDefinition = [[UIView alloc]init];
        _landscapeChangeDefinition.backgroundColor = [UIColor redColor];
        
        CGFloat kLeftPadding = 40;
        CGFloat kBottomPadding = 30;
        CGFloat kBtnWidth = 80;
        CGFloat kBtnHeight = 74;
        
        //标清
        self.standardDef = [UIButton buttonWithType:UIButtonTypeCustom];
        self.standardDef.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
        [self.standardDef addTarget:self action:@selector(switchStandardDef) forControlEvents:UIControlEventTouchUpInside];
        [_landscapeChangeDefinition addSubview:self.standardDef];
        [self.standardDef mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(_landscapeChangeDefinition.mas_bottom).offset(-kBottomPadding);
            make.left.equalTo(_landscapeChangeDefinition.mas_left).offset(kLeftPadding);
            make.width.mas_equalTo(kBtnWidth);
            make.height.mas_equalTo(kBtnHeight);
        }];
        UILabel *standardDefValue = [[UILabel alloc]init];
        [standardDefValue setLabelFormateTitle:@"270P" font:[UIFont wcPfRegularFontOfSize:14] titleColorHexString:@"#ffffff" textAlignment:NSTextAlignmentCenter];
        [self.standardDef addSubview:standardDefValue];
        [standardDefValue mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.standardDef.mas_centerY);
            make.centerX.equalTo(self.standardDef);
        }];
        UILabel *standardDefTip = [[UILabel alloc]init];
        [standardDefTip setLabelFormateTitle:@"标清" font:[UIFont wcPfRegularFontOfSize:14] titleColorHexString:@"#ffffff" textAlignment:NSTextAlignmentCenter];
        [self.standardDef addSubview:standardDefTip];
        [standardDefTip mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.standardDef);
            make.top.equalTo(self.standardDef.mas_centerY);
        }];
        
        //高清
        self.highDef = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.highDef addTarget:self action:@selector(switchHighDef) forControlEvents:UIControlEventTouchUpInside];
        self.highDef.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
        [_landscapeChangeDefinition addSubview:self.highDef];
        [self.highDef mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(self.standardDef);
            make.left.equalTo(self.standardDef.mas_right).offset(20);
            make.bottom.equalTo(self.standardDef.mas_bottom);
        }];
        UILabel *highDefValue = [[UILabel alloc]init];
        [highDefValue setLabelFormateTitle:@"480P" font:[UIFont wcPfRegularFontOfSize:14] titleColorHexString:@"#ffffff" textAlignment:NSTextAlignmentCenter];
        [self.highDef addSubview:highDefValue];
        [highDefValue mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.highDef.mas_centerY);
            make.centerX.equalTo(self.highDef);
        }];
        UILabel *highDefTip = [[UILabel alloc]init];
        [highDefTip setLabelFormateTitle:@"高清" font:[UIFont wcPfRegularFontOfSize:14] titleColorHexString:@"#ffffff" textAlignment:NSTextAlignmentCenter];
        [self.highDef addSubview:highDefTip];
        [highDefTip mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.highDef);
            make.top.equalTo(self.highDef.mas_centerY);
        }];
        
        
        //超清
        self.supperDef = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.supperDef addTarget:self action:@selector(switchSupperDef) forControlEvents:UIControlEventTouchUpInside];
        self.supperDef.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
        [_landscapeChangeDefinition addSubview:self.supperDef];
        [self.supperDef mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(self.standardDef);
            make.bottom.equalTo(self.standardDef.mas_bottom);
            make.left.equalTo(self.highDef.mas_right).offset(20);
        }];
        UILabel *supperDefValue = [[UILabel alloc]init];
        [supperDefValue setLabelFormateTitle:@"720P" font:[UIFont wcPfRegularFontOfSize:14] titleColorHexString:@"#ffffff" textAlignment:NSTextAlignmentCenter];
        [self.supperDef addSubview:supperDefValue];
        [supperDefValue mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.supperDef.mas_centerY);
            make.centerX.equalTo(self.supperDef);
        }];
        UILabel *supperDefTip = [[UILabel alloc]init];
        [supperDefTip setLabelFormateTitle:@"超清" font:[UIFont wcPfRegularFontOfSize:14] titleColorHexString:@"#ffffff" textAlignment:NSTextAlignmentCenter];
        [self.supperDef addSubview:supperDefTip];
        [supperDefTip mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.supperDef);
            make.top.equalTo(self.supperDef.mas_centerY);
        }];
        
        
        //提示tip
        UILabel *definitionTip = [[UILabel alloc]init];
        [definitionTip setLabelFormateTitle:@"画质" font:[UIFont wcPfRegularFontOfSize:14] titleColorHexString:@"#ffffff" textAlignment:NSTextAlignmentLeft];
        [_landscapeChangeDefinition addSubview:definitionTip];
        [definitionTip mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_landscapeChangeDefinition.mas_left).offset(kLeftPadding);
            make.bottom.equalTo(self.standardDef.mas_top).offset(-10);
        }];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideDefinitionView)];
        [_landscapeChangeDefinition addGestureRecognizer:tap];
    }
    return _landscapeChangeDefinition;
}

#pragma mark - respensed event
///MARK: 移除横屏清晰度选择view
- (void)hideDefinitionView {
    [self showSettingVidoParamView];
    
    [self.landscapeChangeDefinition removeFromSuperview];
}

- (void)hideSettingVidoParamView {
    self.definitionBtn.hidden = YES;
    self.voiceBtn.hidden = YES;
    self.rotateBtn.hidden = YES;
}

- (void)showSettingVidoParamView {
    self.definitionBtn.hidden = NO;
    self.voiceBtn.hidden = NO;
    self.rotateBtn.hidden = NO;
}

- (void)switchStandardDef {
    self.standardDef.backgroundColor = [UIColor colorWithHexString:kVideoDemoMainThemeColor];
    self.highDef.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
    self.supperDef.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
    [self.definitionBtn setTitle:@"标清" forState:UIControlStateNormal];
    [self hideDefinitionView];
}

- (void)switchHighDef {
    self.standardDef.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
    self.highDef.backgroundColor = [UIColor colorWithHexString:kVideoDemoMainThemeColor];
    self.supperDef.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
    [self.definitionBtn setTitle:@"高清" forState:UIControlStateNormal];
    [self hideDefinitionView];
}

- (void)switchSupperDef {
    self.standardDef.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
    self.highDef.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3];
    self.supperDef.backgroundColor = [UIColor colorWithHexString:kVideoDemoMainThemeColor];
    [self.definitionBtn setTitle:@"超清" forState:UIControlStateNormal];
    [self hideDefinitionView];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
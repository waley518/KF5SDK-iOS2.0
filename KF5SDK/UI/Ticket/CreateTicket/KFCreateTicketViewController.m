//
//  KFCreateTicketViewController.m
//  Pods
//
//  Created by admin on 16/11/3.
//
//

#import "KFCreateTicketViewController.h"
#import "KFCategory.h"
#import "KFUserManager.h"
#import "KFTicketManager.h"
#import "SDImageCache.h"
#import "KFCreateTicketView.h"

@interface KFCreateTicketViewController ()
/**
 创建工单视图
 */
@property (nullable, nonatomic, weak) KFCreateTicketView *createView;

@property (nonatomic,strong) NSLayoutConstraint *scrollBottomLayout;

@end

static NSArray *CustomFields = nil;
static NSString *TicketTitle = nil;

@implementation KFCreateTicketViewController

+ (void)setCustomFields:(NSArray *)customFields {
    CustomFields = customFields;
}

+ (void)setTicketTitle:(NSString *)ticketTitle {
    TicketTitle = ticketTitle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChangeWithNote:)  name:UITextViewTextDidChangeNotification object:self.createView.textView];
    
    if (!self.title.length) self.title =  KF5Localized(@"kf5_feedback");
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:KF5Localized(@"kf5_submit") style:UIBarButtonItemStyleDone target:self action:@selector(createTicket:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (self.navigationController.viewControllers.count == 1 && !self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:KF5Localized(@"kf5_cancel") style:UIBarButtonItemStyleDone target:self action:@selector(cancelView)];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)setupView{
    self.automaticallyAdjustsScrollViewInsets = NO;
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    
    KFCreateTicketView *createView = [[KFCreateTicketView alloc] init];
    __weak typeof(self)weakSelf = self;
    createView.clickAttBtn = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf addAttachment];
        });
    };
    self.createView = createView;
    [scrollView addSubview:createView];
    
    [scrollView kf5_makeConstraints:^(KFAutoLayout * _Nonnull make) {
        make.top.kf_equalTo(self.kf5_safeAreaTopLayoutGuide);
        make.left.kf_equalTo(self.view.kf5_safeAreaLayoutGuideLeft);
        make.right.kf_equalTo(self.view.kf5_safeAreaLayoutGuideRight);
        self.scrollBottomLayout = make.bottom.kf_equalTo(self.view.kf5_safeAreaLayoutGuideBottom).active;
    }];
    
    [createView kf5_makeConstraints:^(KFAutoLayout * _Nonnull make) {
        make.top.kf_equalTo(scrollView);
        make.left.kf_equalTo(scrollView);
        make.right.kf_equalTo(scrollView);
        make.bottom.kf_equalTo(scrollView);
        make.width.kf_equalTo(scrollView);
        make.height.kf_greaterThanOrEqualTo(scrollView).priority(UILayoutPriorityDefaultLow);
    }];
}

- (void)addAttachment{
    [self.createView.textView resignFirstResponder];
    
    __weak typeof(self)weakSelf = self;
    UIViewController *imagePickerVC = [KFHelper imagePickerControllerWithMaxCount:6 selectedAssets:[self.createView.photoImageView.items valueForKeyPath:@"asset"] didFinishedHandle:^(NSArray<UIImage *> *photos, NSArray *assets) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.createView.photoImageView.items = [KFAssetImage assetImagesWithImages:photos assets:assets];
        });
    }];
    [self presentViewController:imagePickerVC animated:YES completion:nil];
}

- (void)createTicket:(UIBarButtonItem *)btnItem{
    
    [self.createView.textView resignFirstResponder];
    
    if (![KFHelper isNetworkEnable]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [KFProgressHUD showErrorTitleToView:self.view title:KF5Localized(@"kf5_no_internet") hideAfter:3];
        });
        return ;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [KFProgressHUD showLoadingTo:self.view title:KF5Localized(@"kf5_submitting")];
    });
    
    dispatch_group_t group = dispatch_group_create();
    
    __block NSArray *imageTokens = nil;
    __block NSError *failure = nil;
    
    __weak typeof(self)weakSelf = self;
    if (self.createView.photoImageView.items.count > 0) {
        
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.createView.photoImageView.items.count];
        for (KFAssetImage *assetImage in self.createView.photoImageView.items) {
            KFFileModel *model = [[KFFileModel alloc] init];
            model.fileData = UIImageJPEGRepresentation(assetImage.image, 1.0);
            [array addObject:model];
        }
        dispatch_group_enter(group);
        [KFHttpTool uploadWithUserToken:[KFUserManager shareUserManager].user.userToken?:@"" fileModels:array uploadProgress:nil completion:^(NSDictionary * _Nullable result, NSError * _Nullable error) {
            if (!error) {
                imageTokens = [result kf5_arrayForKeyPath:@"data.attachments.token"];
                NSArray *urls = [result kf5_arrayForKeyPath:@"data.attachments.content_url"];
                for (NSInteger i = 0; i < urls.count; i++) {
                    NSString *url = urls[i];
                    if ([url isKindOfClass:[NSString class]]) {
                        [[SDImageCache sharedImageCache]storeImage:((KFAssetImage *)weakSelf.createView.photoImageView.items[i]).image forKey:url completion:nil];
                    }
                }
            }else{
                failure = error;
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (failure) {
            [KFProgressHUD hideHUDForView:weakSelf.view];
            [[KFHelper alertWithMessage:KF5Localized(@"kf5_image_upload_error")]showToVC:weakSelf];
            weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
            return;
        }
        
        NSString *title = TicketTitle.length > 0 ? TicketTitle : @"来自iOS SDK的工单反馈";
        NSString *content = weakSelf.createView.textView.text;
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary: @{ KF5UserToken:[KFUserManager shareUserManager].user.userToken?:@"", KF5Title:title?:@"", KF5Content:content, KF5Uploads:imageTokens?:@[]}];
        if (CustomFields) {
            [params setObject:[KFHelper JSONStringWithObject:CustomFields] forKey:KF5CustomFields];
        }
        
        [KFHttpTool createTicketWithParams:params completion:^(NSDictionary * _Nullable result, NSError * _Nullable error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [KFProgressHUD hideHUDForView:weakSelf.view];
                weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
                if (!error) {
                    [weakSelf cancelView];
                    [KFTicketManager saveTicketNewDateWithTicket:[result kf5_numberForKeyPath:@"data.request.id"].integerValue lastComment:[result kf5_numberForKeyPath:@"data.request.last_comment_id"].integerValue];
                    // 同时工单列表更新
                    [[NSNotificationCenter defaultCenter]postNotificationName:KKF5NoteNeedLoadTicketListData object:nil];
                }else{
                    [[KFHelper alertWithMessage:error.localizedDescription]showToVC:weakSelf];
                }
            });
        }];
    });
}

#pragma mark 收到键盘弹出通知后的响应
- (void)keyboardWillShow:(NSNotification *)info {
    
    NSDictionary *dict = info.userInfo;
    //得到键盘的显示完成后的frame
    CGRect keyboardBounds = [dict[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    //得到键盘的高度，即输入框需要移动的距离
    self.scrollBottomLayout.constant = -(keyboardBounds.size.height  - self.view.kf5_safeAreaInsets.bottom);

    [UIView animateWithDuration:[dict[UIKeyboardAnimationDurationUserInfoKey] doubleValue] delay:0 options:[dict[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16 animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark 隐藏键盘通知的响应
- (void)keyboardWillHide:(NSNotification *)info {
    NSDictionary *dict = info.userInfo;
    self.scrollBottomLayout.constant = 0;
    [UIView animateWithDuration:[dict[UIKeyboardAnimationDurationUserInfoKey] doubleValue] delay:0 options:[dict[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16 animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)cancelView{
    if (self.navigationController.viewControllers.count == 1) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

// 监听textView的内容变化
- (void)textDidChangeWithNote:(NSNotification *)note{
    if ([self.createView.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }else{
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end

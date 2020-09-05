//
//  KFHelper+CurrentImage.m
//  KF5SDK
//
//  Created by Ray on 2020/9/5.
//  Copyright © 2020 kf5. All rights reserved.
//

#import "KFHelper+CurrentImage.h"

@implementation KFHelper (CurrentImage)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL oldSel = NSSelectorFromString(@"agentImage");
        SEL newSel = NSSelectorFromString(@"headerImage");
        Method originalMethod = class_getInstanceMethod([self class], oldSel);
        Method swizzledMethod = class_getInstanceMethod([self class], newSel);
        
        SEL oldSel2 = NSSelectorFromString(@"chat_ctnOtherBg");
        SEL newSel2 = NSSelectorFromString(@"chatCtnOtherBg");
        Method originalMethod2 = class_getInstanceMethod([self class], oldSel2);
        Method swizzledMethod2 = class_getInstanceMethod([self class], newSel2);
        
        SEL oldSel3 = NSSelectorFromString(@"chat_ctnMeBg");
        SEL newSel3 = NSSelectorFromString(@"chatCtnMeBg");
        Method originalMethod3 = class_getInstanceMethod([self class], oldSel3);
        Method swizzledMethod3 = class_getInstanceMethod([self class], newSel3);
        
        BOOL didAddMethod = class_addMethod([self class],
                                            oldSel,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        BOOL didAddMethod2 = class_addMethod([self class],
                                             oldSel2,
                                             method_getImplementation(swizzledMethod2),
                                             method_getTypeEncoding(swizzledMethod2));
        BOOL didAddMethod3 = class_addMethod([self class],
                                             oldSel3,
                                             method_getImplementation(swizzledMethod3),
                                             method_getTypeEncoding(swizzledMethod3));
        if (didAddMethod) {
            class_replaceMethod([self class],
                                newSel,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
        if (didAddMethod2) {
            class_replaceMethod([self class],
                                newSel2,
                                method_getImplementation(originalMethod2),
                                method_getTypeEncoding(originalMethod2));
        } else {
            method_exchangeImplementations(originalMethod2, swizzledMethod2);
        }
        
        if (didAddMethod3) {
            class_replaceMethod([self class],
                                newSel3,
                                method_getImplementation(originalMethod3),
                                method_getTypeEncoding(originalMethod3));
        } else {
            method_exchangeImplementations(originalMethod3, swizzledMethod3);
        }
    });
}

- (void)headerImage {
    self.agentImage = [UIImage imageNamed:@"kf5_header_ba"];
}

- (void)chatCtnOtherBg {
    self.chat_ctnOtherBg = [UIImage imageNamed:@"kf5_header_ba"];
}

- (void)chatCtnMeBg {
    self.chat_ctnMeBg = [UIImage imageNamed:@"kf5_header_ba"];
}


@end

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <sys/stat.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <spawn.h>
#import <mach/mach_host.h>
#import <dlfcn.h>
#include <mach/mach.h>
#import <SafariServices/SafariServices.h>
#import "MobileGestalt.h"
#import "Preferences.h"
#import <rootless.h>

#define LOGO_IMAGE @"CannatheaLogo"
#define APPNAME @"RegionChanger"
#define VERSION @"v0.0.2"

#define Notify_Preferences "com.ichitaso.regionchanger.alert"

#define IS_PAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#define PLIST_PATH @"/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
#define BACKUP_PATH  @"/var/mobile/Library/Preferences/com.ichitaso.regionchanger.plist"

#define COUNTRY_KEY @"h63QSdBCiT/z0WU6rdQv6Q"
#define REGION_KEY @"zHeENZu+wbg7PUprwNwBWg"

@protocol SFSafariViewControllerDelegate;
@import SafariServices;

@interface APPController : PSListController <SFSafariViewControllerDelegate> {
    CGRect topFrame;
    UILabel *bannerTitle;
    UILabel *footerLabel;
    UILabel *titleLabel;
    UILabel *_label;
    UILabel *underLabel;
}
@property (nonatomic, strong) id<SFSafariViewControllerDelegate> delegate;
@property(retain) UIView *bannerView;
@property (nonatomic, copy) NSString *valueStr;
+ (APPController *)shared;
@end

@interface AppDelegate : UIApplication <UIApplicationDelegate> {
    UIWindow *_window;
    UIViewController *_viewController;
}
@property (nonatomic, retain) UIWindow *window;
@end

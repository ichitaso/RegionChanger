#import "RootViewController.h"

@interface UIDeviceHardware : NSObject
- (NSString *)platform;
@end

@implementation UIDeviceHardware
- (NSString *)platform {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}
@end

static CGFloat const kHBFPHeaderTopInset = 64.f;
static CGFloat const kHBFPHeaderHeight = 160.f;

static int status;
static BOOL hideEcid;
static UIAlertController *alertController;
static CFStringRef (*$MGCopyAnswer)(CFStringRef);

static BOOL isEnable() {
    NSDictionary *dict1 = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
    NSDictionary *dict2 = dict1[@"CacheExtra"];
    NSString *country = [dict2[COUNTRY_KEY] ?: nil copy];
    NSString *regioncode = [dict2[REGION_KEY] ?: nil copy];
    if ([country isEqualToString:@"US"] && [regioncode isEqualToString:@"LL/A"]) {
        return YES;
    }
    return NO;
}

extern char **environ;
void run_cmd(char *cmd) {
    pid_t pid;
    char *argv[] = {"sh", "-c", cmd, NULL};
    int status;
    status = posix_spawn(&pid, "/bin/sh", NULL, NULL, (char* const*)argv, environ);

    if (status == 0) {
        printf("Child pid: %i\n", pid);
        if (waitpid(pid, &status, 0) != -1) {
            printf("Child exited with status %i\n", status);
        } else {
            perror("waitpid");
        }
    } else {
        printf("posix_spawn: %s\n", strerror(status));
    }
}

@implementation AppDelegate
@synthesize window = _window;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _viewController = [[UINavigationController alloc] initWithRootViewController:[APPController shared]];
    [_window addSubview:_viewController.view];
    _window.rootViewController = _viewController;
    [_window makeKeyAndVisible];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application
  supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskAll;
}
@end

static APPController *controller;

@implementation APPController
+ (APPController *)shared {
    if (!controller) {
        controller = [[[self class] alloc] init];
    }
    return controller;
}

- (instancetype)init {
    self = [super init];
    // Alert Notification
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), &status, CFSTR(Notify_Preferences), NULL);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"notifyAlertButton" object:nil];

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), &status, (CFNotificationCallback)notifyAlertButtonCallBack, CFSTR(Notify_Preferences), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyAlertButton:) name:@"notifyAlertButton" object:nil];

    return self;
}

void notifyAlertButtonCallBack () {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"notifyAlertButton" object:nil];
}

- (void)notifyAlertButton:(NSNotification *)notification {
    alertController =
    [UIAlertController alertControllerWithTitle:nil
                                        message:@"Get root"
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {}]];
    [self presentViewController:alertController animated:YES completion:nil];
    [self reloadSpecifiers];
}

- (void)loadView {
    [super loadView];

    // Header logo image
    UINavigationItem *navigationItem = self.navigationItem;

    navigationItem.titleView =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:LOGO_IMAGE
                                                  inBundle:[NSBundle bundleForClass:self.class]]];

    CGFloat headerHeight = 0 + kHBFPHeaderHeight;
    CGRect selfFrame = [self.view frame];

    _bannerView = [[UIView alloc] init];
    _bannerView.frame = CGRectMake(0, -kHBFPHeaderHeight, selfFrame.size.width, headerHeight);
    _bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [self.table addSubview:_bannerView];
    [self.table sendSubviewToBack:_bannerView];

    topFrame = CGRectMake(0, -kHBFPHeaderHeight, 414, kHBFPHeaderHeight);

    bannerTitle = [[UILabel alloc] init];
    bannerTitle.text = APPNAME;
    [bannerTitle setFont:[UIFont fontWithName:@"HelveticaNeue-Ultralight" size:36]];

    [_bannerView addSubview:bannerTitle];

    [bannerTitle setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:bannerTitle attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0f]];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:bannerTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:20.0f]];
    bannerTitle.textAlignment = NSTextAlignmentCenter;

    NSString *systemStr = [NSString stringWithFormat:@"%@ %@ %@ - %@",[[UIDeviceHardware alloc] platform],[[UIDevice currentDevice] systemName],[[UIDevice currentDevice] systemVersion],VERSION];

    footerLabel = [[UILabel alloc] init];
    footerLabel.text = systemStr;
    [footerLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16]];
    footerLabel.textColor = [UIColor grayColor];
    footerLabel.alpha = 1.0;

    [_bannerView addSubview:footerLabel];

    [footerLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:footerLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0f]];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:footerLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:60.0f]];
    footerLabel.textAlignment = NSTextAlignmentCenter;

    [self.table setContentInset:UIEdgeInsetsMake(kHBFPHeaderHeight-kHBFPHeaderTopInset,0,0,0)];
    [self.table setContentOffset:CGPointMake(0, -kHBFPHeaderHeight+kHBFPHeaderTopInset)];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
    $MGCopyAnswer = dlsym(gestalt, "MGCopyAnswer");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)_unloadBundleControllers {
    [super _unloadBundleControllers];
}

- (id)specifiers {
    if (!_specifiers) {
        NSMutableArray *specifiers = [NSMutableArray array];
        PSSpecifier *spec;

        spec = [PSSpecifier preferenceSpecifierNamed:@"System Status"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSGroupCell
                                                edit:nil];
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Root Status"
                                              target:self
                                                 set:nil
                                                 get:@selector(isRoot:)
                                              detail:nil
                                                cell:PSTitleValueCell
                                                edit:nil];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Current Settings"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSGroupCell
                                                edit:nil];
        [spec setProperty:@"The system region of your current device been changed." forKey:@"footerText"];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Region Code:"
                                              target:self
                                                 set:nil
                                                 get:@selector(readRegionCodeValue:)
                                              detail:nil
                                                cell:PSTitleValueCell
                                                edit:nil];
        [spec setProperty:@"Region Code:" forKey:@"key"];
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Region Info:"
                                              target:self
                                                 set:nil
                                                 get:@selector(readRegionInfoValue:)
                                              detail:nil
                                                cell:PSTitleValueCell
                                                edit:nil];
        [spec setProperty:@"Region Info:" forKey:@"key"];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Change Region"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSGroupCell
                                                edit:nil];
        [spec setProperty:@"Set the System Region of your device to US or Original." forKey:@"footerText"];
        [specifiers addObject:spec];

        NSString *setting = isEnable() ? @"Restore" : @"Enable";

        spec = [PSSpecifier preferenceSpecifierNamed:setting
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSButtonCell
                                                edit:nil];

        spec->action = @selector(confirmRegion);
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"System Function"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSGroupCell
                                                edit:nil];
        [spec setProperty:@"System Function" forKey:@"label"];
        [spec setProperty:@"Works only in jailbroken state." forKey:@"footerText"];
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Reboot"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSButtonCell
                                                edit:nil];
        spec->action = @selector(tapReboot);
        [spec setProperty:@"Reboot" forKey:@"key"];
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"UserSpace Reboot"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSButtonCell
                                                edit:nil];
        spec->action = @selector(tapUserSpaceReboot);
        [spec setProperty:@"UserSpaceReboot" forKey:@"key"];
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"LDRestart"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSButtonCell
                                                edit:nil];
        spec->action = @selector(tapLDRestart);
        [spec setProperty:@"LDRestart" forKey:@"key"];
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"ECID"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSGroupCell
                                                edit:nil];
        [specifiers addObject:spec];


        spec = [PSSpecifier preferenceSpecifierNamed:@"Decimal"
                                              target:self
                                                 set:nil
                                                 get:@selector(ecidValue:)
                                              detail:nil
                                                cell:PSTitleValueCell
                                                edit:nil];
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Hexadecimal"
                                              target:self
                                                 set:nil
                                                 get:@selector(ecidHexValue:)
                                              detail:nil
                                                cell:PSTitleValueCell
                                                edit:nil];
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Show / Hide ECID"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSButtonCell
                                                edit:nil];

        spec->action = @selector(showHideEcid);
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Infomation"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSGroupCell
                                                edit:nil];
        [spec setProperty:@"Info" forKey:@"label"];
        [spec setProperty:@"If you like my work, Please a donation by Paypal." forKey:@"footerText"];
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Device Model"
                                              target:self
                                                 set:nil
                                                 get:@selector(modelValue:)
                                              detail:nil
                                                cell:PSTitleValueCell
                                                edit:nil];
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Follow on Twitter"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSButtonCell
                                                edit:nil];
        
        spec->action = @selector(openTwitter);
        [spec setProperty:@YES forKey:@"hasIcon"];
        [spec setProperty:[UIImage imageWithContentsOfFile:[[self bundle] pathForResource:@"twitter" ofType:@"png"]] forKey:@"iconImage"];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Donation"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSLinkCell
                                                edit:nil];
        
        spec->action = @selector(donate);
        [spec setProperty:@YES forKey:@"hasIcon"];
        [spec setProperty:[UIImage imageWithContentsOfFile:[[self bundle] pathForResource:@"paypal" ofType:@"png"]] forKey:@"iconImage"];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"© Will feel Tips by ichitaso" forKey:@"footerText"];
        [specifiers addObject:spec];
        _specifiers = [specifiers copy];
    }
    return _specifiers;
}

- (void)_returnKeyPressed:(id)arg1 {
    [super _returnKeyPressed:arg1];
    [self.view endEditing:YES];
}

- (id)isRoot:(PSSpecifier*)specifier {
    setgid(0);
    uint32_t gid = getgid();
    NSLog(@"getgid() returns %u\n", gid);
    setuid(0);
    uint32_t uid = getuid();
    NSLog(@"getuid() returns %u\n", uid);
    return [NSString stringWithFormat:@"%@", getuid() == 0 ? @"root" : @"mobile"];
}

- (id)readRegionCodeValue:(PSSpecifier *)specifier {
    NSDictionary *dict1 = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
    NSDictionary *dict2 = dict1[@"CacheExtra"];
    NSString *country = [dict2[COUNTRY_KEY] ?: nil copy];
    return country;
}

- (id)readRegionInfoValue:(PSSpecifier *)specifier {
    NSDictionary *dict1 = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
    NSDictionary *dict2 = dict1[@"CacheExtra"];
    NSString *regioncode = [dict2[REGION_KEY] ?: nil copy];
    return regioncode;
}

- (void)confirmRegion {
    alertController =
    [UIAlertController alertControllerWithTitle:@"Change Device Region?"
                                        message:[NSString stringWithFormat:@"Change file:\n%@", PLIST_PATH]
                                 preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle:@"YES"
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
        [self changeRegion];
    }]];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {}]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)changeRegion {
    NSFileManager *manager = [NSFileManager defaultManager];

    NSDictionary *dict1 = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
    NSMutableDictionary *mdict1 = dict1 ? [dict1 mutableCopy] : [NSMutableDictionary dictionary];

    NSDictionary *dict2 = dict1[@"CacheExtra"];

    if (!isEnable() && ![manager fileExistsAtPath:BACKUP_PATH]) {
        // Backup Orignal key
        NSMutableDictionary *bkdict = [NSMutableDictionary dictionary];
        bkdict[COUNTRY_KEY] = dict2[COUNTRY_KEY];
        bkdict[REGION_KEY] = dict2[REGION_KEY];
        [bkdict writeToFile:BACKUP_PATH atomically:YES];
        // Set US Region
        NSMutableDictionary *mdict2 = dict2 ? [dict2 mutableCopy] : [NSMutableDictionary dictionary];
        mdict2[COUNTRY_KEY] = @"US";
        mdict2[REGION_KEY] = @"LL/A";
        [mdict1 setObject:mdict2 forKey:@"CacheExtra"];
        [mdict1 writeToFile:PLIST_PATH atomically:YES];

        if (isEnable() && [manager fileExistsAtPath:BACKUP_PATH]) {
            alertController =
            [UIAlertController alertControllerWithTitle:@"Succes"
                                                message:@"Reboot or ldrestart or userspace reboot is required to reflect this."
                                         preferredStyle:UIAlertControllerStyleAlert];

            [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
            }]];

            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            alertController =
            [UIAlertController alertControllerWithTitle:@"Faild"
                                                message:[NSString stringWithFormat:@"Pls check this file:\n%@", PLIST_PATH]
                                         preferredStyle:UIAlertControllerStyleAlert];

            [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
            }]];

            [self presentViewController:alertController animated:YES completion:nil];
        }
    } else {
        // Restore Orignal plist
        NSDictionary *bkdict = [NSDictionary dictionaryWithContentsOfFile:BACKUP_PATH];
        NSMutableDictionary *mdict2 = dict2 ? [dict2 mutableCopy] : [NSMutableDictionary dictionary];
        mdict2[COUNTRY_KEY] = bkdict[COUNTRY_KEY];
        mdict2[REGION_KEY] = bkdict[REGION_KEY];
        [mdict1 setObject:mdict2 forKey:@"CacheExtra"];
        [mdict1 writeToFile:PLIST_PATH atomically:YES];
        // Delete Backup file
        [manager removeItemAtPath:BACKUP_PATH error:nil];

        if (!isEnable() && ![manager fileExistsAtPath:BACKUP_PATH]) {
            alertController =
            [UIAlertController alertControllerWithTitle:@"Succes"
                                                message:@"Reboot or ldrestart or userspace reboot is required to reflect this."
                                         preferredStyle:UIAlertControllerStyleAlert];

            [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
            }]];

            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            alertController =
            [UIAlertController alertControllerWithTitle:@"Faild"
                                                message:[NSString stringWithFormat:@"Pls check this file:\n%@", PLIST_PATH]
                                         preferredStyle:UIAlertControllerStyleAlert];

            [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
            }]];

            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    // Reload
    [self reloadSpecifiers];
}

- (void)tapReboot {
    if (getuid() != 0) {
        setuid(0);
    }

    if (getuid() != 0) {
        alertController =
        [UIAlertController alertControllerWithTitle:@"You can not run"
                                            message:@"Status: mobile"
                                     preferredStyle:UIAlertControllerStyleAlert];

        [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {}]];

        [self presentViewController:alertController animated:YES completion:nil];
        // return
        return;
    }

    alertController =
    [UIAlertController alertControllerWithTitle:nil
                                        message:@"Confirm Reboot"
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Reboot"
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
        run_cmd("kill 1");
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {

                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)tapLDRestart {
    if (getuid() != 0) {
        setuid(0);
    }

    if (getuid() != 0) {
        alertController =
        [UIAlertController alertControllerWithTitle:@"You can not run"
                                            message:@"Status: mobile"
                                     preferredStyle:UIAlertControllerStyleAlert];

        [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {}]];

        [self presentViewController:alertController animated:YES completion:nil];
        // return
        return;
    }

    alertController =
    [UIAlertController alertControllerWithTitle:nil
                                        message:@"Confirm LDRestart"
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"LDRestart"
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
        run_cmd("/usr/bin/ldrestart");
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {

                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)tapUserSpaceReboot {
    if (getuid() != 0) {
        setuid(0);
    }

    if (getuid() != 0) {
        alertController =
        [UIAlertController alertControllerWithTitle:@"You can not run"
                                            message:@"Status: mobile"
                                     preferredStyle:UIAlertControllerStyleAlert];

        [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {}]];

        [self presentViewController:alertController animated:YES completion:nil];
        // return
        return;
    }

    alertController =
    [UIAlertController alertControllerWithTitle:nil
                                        message:@"Confirm UserSpace Reboot"
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"UserSpace Reboot"
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/jb"]) {
            run_cmd("/var/jb/bin/launchctl reboot userspace");
        } else {
            run_cmd("/bin/launchctl reboot userspace");
        }
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {

                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (id)ecidValue:(PSSpecifier *)specifier {
    if (hideEcid == NO) {
        CFStringRef ecid = (CFStringRef)$MGCopyAnswer(CFSTR("UniqueChipID"));
        return [NSString stringWithFormat:@"%@", (__bridge NSString *)ecid];
    } else {
        return @"1234567890";
    }
}

- (id)ecidHexValue:(PSSpecifier *)specifier {
   return [NSString stringWithFormat:@"%lX", (unsigned long)[[self ecidValue:nil] integerValue]];
}

- (id)modelValue:(PSSpecifier *)specifier {
    CFStringRef boardId = (CFStringRef)$MGCopyAnswer(CFSTR("HWModelStr"));
    if (!boardId) return @"NULL";
    return [NSString stringWithFormat:@"%@", (__bridge NSString *)boardId];;
}

- (void)showHideEcid {
    if (hideEcid) {
        hideEcid = NO;
    } else {
        hideEcid = YES;
    }

    [self reloadSpecifiers];
}

- (void)openTwitter {
    NSString *twitterID = @"ichitaso";

    alertController = [UIAlertController
                       alertControllerWithTitle:@"Follow @ichitaso"
                       message:nil
                       preferredStyle:UIAlertControllerStyleActionSheet];

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Open in Twitter" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@",twitterID]]
                                               options:@{}
                                     completionHandler:nil];
        }]];
    }

    [alertController addAction:[UIAlertAction actionWithTitle:@"Open in Browser" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self openURLInBrowser:[NSString stringWithFormat:@"https://twitter.com/%@",twitterID]];
        });
    }]];

    // Fix Crash for iPad
    if (IS_PAD) {
        CGRect rect = self.view.frame;
        alertController.popoverPresentationController.sourceView = self.view;
        alertController.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(rect)-60,rect.size.height-50, 120,50);
        alertController.popoverPresentationController.permittedArrowDirections = 0;
    } else {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}]];
    }

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)donate {
    [self openURLInBrowser:@"https://cydia.ichitaso.com/donation.html"];
}

- (void)openURLInBrowser:(NSString *)url {
    SFSafariViewControllerConfiguration *config = [[SFSafariViewControllerConfiguration alloc] init];
    config.barCollapsingEnabled = NO;
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url] configuration:config];
    if (@available(iOS 13.0, *)) {
        [self presentViewController:safari animated:YES completion:nil];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]
                                           options:@{}
                                 completionHandler:nil];
    }

}
@end

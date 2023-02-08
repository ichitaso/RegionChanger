#include <stdio.h>
#import "../RootViewController.h"

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

int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
        NSFileManager *manager = [NSFileManager defaultManager];

        NSDictionary *dict1 = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
        NSMutableDictionary *mdict1 = dict1 ? [dict1 mutableCopy] : [NSMutableDictionary dictionary];

        NSDictionary *dict2 = dict1[@"CacheExtra"];

        if (isEnable() && [manager fileExistsAtPath:BACKUP_PATH]) {
            // Restore Orignal plist
            NSDictionary *bkdict = [NSDictionary dictionaryWithContentsOfFile:BACKUP_PATH];
            NSMutableDictionary *mdict2 = dict2 ? [dict2 mutableCopy] : [NSMutableDictionary dictionary];
            mdict2[COUNTRY_KEY] = bkdict[COUNTRY_KEY];
            mdict2[REGION_KEY] = bkdict[REGION_KEY];
            [mdict1 setObject:mdict2 forKey:@"CacheExtra"];
            [mdict1 writeToFile:PLIST_PATH atomically:YES];
            // Delete Backup file
            [manager removeItemAtPath:BACKUP_PATH error:nil];

            // Removing Alert thx karen
            CFUserNotificationRef postinstNotification = CFUserNotificationCreate(kCFAllocatorDefault, 0, 0, NULL, (__bridge CFDictionaryRef)[[NSDictionary alloc] initWithObjectsAndKeys:
                            @"RegionChanger", @"AlertHeader",
                            @"Please reboot or userspace reboot or run ldrestart.", @"AlertMessage",
                            @"OK", @"DefaultButtonTitle", nil]);
            CFUserNotificationReceiveResponse(postinstNotification, 0, NULL);
        }
		return 0;
	}
}

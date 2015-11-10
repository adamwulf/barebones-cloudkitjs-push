//
//  AppDelegate.m
//  cloudkitjs-push
//
//  Created by Adam Wulf on 11/10/15.
//  Copyright © 2015 Milestone Made. All rights reserved.
//

#import "AppDelegate.h"
#import <CloudKit/CloudKit.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSTextField *textField;

@end

@implementation AppDelegate

@synthesize textField;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.textField.stringValue = [self.textField.stringValue stringByAppendingString:@"applicationDidFinishLaunching\n"];


    [[[CKContainer defaultContainer] privateCloudDatabase] fetchAllSubscriptionsWithCompletionHandler:^(NSArray<CKSubscription *> *_Nullable subscriptions, NSError *_Nullable error) {
        __block NSArray* subsToDelete = @[];
        [subscriptions enumerateObjectsUsingBlock:^(CKSubscription * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            subsToDelete = [subsToDelete arrayByAddingObject:[obj subscriptionID]];
        }];

        [self logMessage:[NSString stringWithFormat:@"deleting %d subscriptions", (int) [subsToDelete count]]];
        CKModifySubscriptionsOperation* delSubOp = [[CKModifySubscriptionsOperation alloc] initWithSubscriptionsToSave:@[] subscriptionIDsToDelete:subsToDelete];
        delSubOp.modifySubscriptionsCompletionBlock = ^(NSArray* savedSubs, NSArray* deletedSubs, NSError* err){
            NSAssert(!err, @"no error");
            NSDate* date = [NSDate dateWithTimeInterval:-60.0 * 120 sinceDate:[NSDate date]];
            CKSubscription* newSub = [[CKSubscription alloc] initWithRecordType:@"AnObjectType" predicate:[NSPredicate predicateWithFormat:@"creationDate > %@", date] options:CKSubscriptionOptionsFiresOnRecordDeletion];
            [self logMessage:[NSString stringWithFormat:@"deleted %d subscriptions", (int) [deletedSubs count]]];
            [self logMessage:[NSString stringWithFormat:@"creating new subscription"]];
            [[[CKContainer defaultContainer] privateCloudDatabase] saveSubscription:newSub completionHandler:^(CKSubscription *subscription, NSError *error) {
                NSAssert(subscription, @"subscription saved ok");
                NSAssert(!error, @"no error");
                [self logMessage:[NSString stringWithFormat:@"created subscription"]];
                [[NSApplication sharedApplication] registerForRemoteNotificationTypes:NSRemoteNotificationTypeAlert];
            }];
        };
        [[[CKContainer defaultContainer] privateCloudDatabase] addOperation:delSubOp];
    }];

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void)application:(NSApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken{
    [self logMessage:@"didRegisterForRemoteNotificationsWithDeviceToken"];
}

-(void)application:(NSApplication *)application didReceiveRemoteNotification:(NSDictionary<NSString *,id> *)userInfo{
    [self logMessage:@"didReceiveRemoteNotification"];
}

-(void) application:(NSApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    [self logMessage:@"didFailToRegisterForRemoteNotificationsWithError"];
}

-(void) logMessage:(NSString*)log{
    self.textField.stringValue = [self.textField.stringValue stringByAppendingString:[NSString stringWithFormat:@"%@\n", log]];
}

@end

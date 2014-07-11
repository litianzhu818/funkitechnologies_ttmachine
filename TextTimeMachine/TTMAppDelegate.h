//
//  TTMAppDelegate.h
//  TextTimeMachine
//
//  Created by Dinesh Mehta on 28/02/14.
//  Copyright (c) 2014 Dinesh Mehta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "XMPPFramework.h"
//ch.07
#import "YDFileInfo.h"
#import "YDFileReceiver.h"
#import "TTMMUCManager.h"

@protocol SMMessageDelegate;
@protocol SMChatDelegate;

@interface TTMAppDelegate : UIResponder <UIApplicationDelegate,XMPPRosterDelegate,YDFileReceiverDelegate,XMPPMUCDelegate,XMPPRoomDelegate> {
    
    BOOL allowSelfSignedCertificates;
	BOOL allowSSLHostNameMismatch;
	
	BOOL isXmppConnected;
    __strong id <XMPPRoomStorage> xmppRoomStorage;

}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) NSObject <SMChatDelegate>  *chatDelegate;
@property (nonatomic, assign) id  messageDelegate;

//XMPP
@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (nonatomic, strong, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;
//CoreData
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
//@property (nonatomic,strong)TTMMUCManager *mucManager;
- (void)saveContext;

//public methods
- (BOOL)connect;
- (void)disconnect;
-(void)sendInvitationToJID:(NSString *)_jid withNickName:(NSString *)_nickName;

//ch.07 file transfer
@property(nonatomic,strong) YDFileInfo* fileInfo;
@property(nonatomic,assign) BOOL isSending;
@property(nonatomic,assign) BOOL isReceiving;
@property(nonatomic,strong)  NSString* transferID;
@property(nonatomic,strong)  NSString* streamID;
@property(nonatomic,strong) YDFileReceiver *fileReceiver;

//ch.08
@property (nonatomic,strong, readonly) XMPPMUC *xmppMUC;
@property (nonatomic,strong, readonly) XMPPRoomCoreDataStorage *xmppRoomCoreDataStore;

@end

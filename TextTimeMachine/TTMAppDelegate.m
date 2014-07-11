//
//  TTMAppDelegate.m
//  TextTimeMachine
//
//  Created by Dinesh Mehta on 28/02/14.
//  Copyright (c) 2014 Dinesh Mehta. All rights reserved.
//

#import "TTMAppDelegate.h"
#import "TTMHomeViewController.h"
#import "TTMChatDelegate.h"
#import "SMChatDelegate.h"
#import "TTMCustomDelegate.h"
#import "TTMMediaModel.h"
#import "GCDAsyncSocket.h"
#import "XMPP.h"
#import "Chat.h"
#import "TTMMessageInfo.h"
#import "SBJsonParser.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
//ch.08
#import "XMPPRoomHybridStorage.h"
#import "XMPPRoomMemoryStorage.h"
#import "Room.h"
#import "XMPPMessage+XEP0045.h"

#import <CFNetwork/CFNetwork.h>

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif
@interface TTMAppDelegate() {
    NSString* userPassword;
}

@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;

//ch.08
@property (nonatomic,strong) XMPPMUC *xmppMUC;
@property (nonatomic,strong) XMPPRoomCoreDataStorage *xmppRoomCoreDataStore;


- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;


@end

@implementation TTMAppDelegate
@synthesize xmppStream;
@synthesize xmppRoster;
@synthesize chatDelegate = _chatDelegate ;
@synthesize messageDelegate = _messageDelegate;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

/*
-(TTMMUCManager *)mucManager {
    if(!_mucManager) {
        _mucManager = [[TTMMUCManager alloc] init] ;
    }
    return _mucManager;
}
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    TTMHomeViewController *homeViewController = [[TTMHomeViewController alloc] init];
    UINavigationController *navigationLocal = [[UINavigationController alloc] initWithRootViewController:homeViewController];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    TTMDataBaseManager *dataInitialization = [[TTMDataBaseManager alloc] init];
    [dataInitialization initializeTheCoreDataModelClasses];
    
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
    //Create directory for the images and videos
    [TTMCommon createDirectoryStructureInDocument];
    // Setup the XMPP stream
	[self setupStream];
    //Setup our CoreData System
    __managedObjectContext = self.managedObjectContext;
    //
    self.isReceiving=NO;
    self.isSending=NO;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    self.window.rootViewController = navigationLocal;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

-(void)credentialsStored
{
    if (![self connect])
    {
        DDLogInfo(@"credentialsStored self connect failed");
    }
    
}

/***
 ** @ Set up stream for the socket connection
 ***/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Core Data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [self.xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
	return [self.xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setupStream
{
	NSAssert(self.xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	//
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	self.xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
        // Want xmpp to run in the background?
        //
        // P.S. - The simulator doesn't support backgrounding yet.
        //        When you try to set the associated property on the simulator, it simply fails.
        //        And when you background an app on the simulator,
        //        it just queues network traffic til the app is foregrounded again.
        //        We are patiently waiting for a fix from Apple.
        //        If you do enableBackgroundingOnSocket on the simulator,
        //        you will simply see an error message from the xmpp stack when it fails to set the property.
        
        self.xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	
	// Setup reconnect
	//
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	self.xmppReconnect = [[XMPPReconnect alloc] init];
	
	// Setup roster
	//
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
	
	self.xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    //	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
	
	self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage];
	
	self.xmppRoster.autoFetchRoster = YES;
	self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	//
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	self.xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	self.xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:self.xmppvCardStorage];
	
	self.xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:self.xmppvCardTempModule];
	
	// Setup capabilities
	//
	// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
	// Basically, when other clients broadcast their presence on the network
	// they include information about what capabilities their client supports (audio, video, file transfer, etc).
	// But as you can imagine, this list starts to get pretty big.
	// This is where the hashing stuff comes into play.
	// Most people running the same version of the same client are going to have the same list of capabilities.
	// So the protocol defines a standardized way to hash the list of capabilities.
	// Clients then broadcast the tiny hash instead of the big list.
	// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
	// and also persistently storing the hashes so lookups aren't needed in the future.
	//
	// Similarly to the roster, the storage of the module is abstracted.
	// You are strongly encouraged to persist caps information across sessions.
	//
	// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
	// It can also be shared amongst multiple streams to further reduce hash lookups.
	
	self.xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    self.xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:self.xmppCapabilitiesStorage];
    
    self.xmppCapabilities.autoFetchHashedCapabilities = YES;
    self.xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    //ch.08
    //ROOM
    
    self.xmppRoomCoreDataStore = [XMPPRoomCoreDataStorage sharedInstance];
    self.xmppMUC = [[XMPPMUC alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    
    
    
	// Activate xmpp modules
    
	[self.xmppReconnect         activate:self.xmppStream];
	[self.xmppRoster            activate:self.xmppStream];
	[self.xmppvCardTempModule   activate:self.xmppStream];
	[self.xmppvCardAvatarModule activate:self.xmppStream];
	[self.xmppCapabilities      activate:self.xmppStream];
    //ch.08
    [self.xmppMUC              activate:self.xmppStream];
    
    // Add ourself as a delegate to anything we may be interested in
    
	[self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    //ch.08
    [self.xmppMUC addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
	// Optional:
	//
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	//
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	//
	// If you don't specify a hostPort, then the default (5222) will be used.
	
    //	[xmppStream setHostName:@"talk.google.com"];
    //	[xmppStream setHostPort:5222];
	
    
	// You may need to alter these settings depending on the server you're connecting to
	allowSelfSignedCertificates = YES;
	allowSSLHostNameMismatch = NO;
}

- (void)teardownStream
{
	[self.xmppStream removeDelegate:self];
	[self.xmppRoster removeDelegate:self];
    //ch.08
    [self.xmppMUC     removeDelegate:self];
	
	[self.xmppReconnect         deactivate];
	[self.xmppRoster            deactivate];
	[self.xmppvCardTempModule   deactivate];
	[self.xmppvCardAvatarModule deactivate];
	[self.xmppCapabilities      deactivate];
	//ch.08
    [self.xmppMUC     deactivate];
    
    
	[self.xmppStream disconnect];
	
	self.xmppStream = nil;
	self.xmppReconnect = nil;
    self.xmppRoster = nil;
	self.xmppRosterStorage = nil;
	self.xmppvCardStorage = nil;
    self.xmppvCardTempModule = nil;
	self.xmppvCardAvatarModule = nil;
	self.xmppCapabilities = nil;
	self.xmppCapabilitiesStorage = nil;
    //ch.08
    self.xmppMUC=nil;
}

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
//
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
//
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
//
// For more information on working with XML elements, see the Wiki article:
// https://github.com/robbiehanson/XMPPFramework/wiki/WorkingWithElements

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
    
    NSString *domain = [self.xmppStream.myJID domain];
    
    //Google set their presence priority to 24, so we do the same to be compatible.
    
    if([domain isEqualToString:@"gmail.com"]
       || [domain isEqualToString:@"gtalk.com"]
       || [domain isEqualToString:@"talk.google.com"])
    {
        NSXMLElement *priority = [NSXMLElement elementWithName:@"priority" stringValue:@"24"];
        [presence addChild:priority];
    }
	
	[[self xmppStream] sendElement:presence];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect/disconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connect
{
	if (![self.xmppStream isDisconnected]) {
		return YES;
	}
    
    NSString *userName = [[NSUserDefaults standardUserDefaults] valueForKey:@"userName"];
    NSString *userPassword1 = [[NSUserDefaults standardUserDefaults] valueForKey:@"Password"];
	NSString *myJID = [NSString stringWithFormat:@"%@%@%@", userName, @"@",[TTMCommon getChatServerStaticIPName]];
    
    userPassword = userPassword1;
    
	//
	// If you don't want to use the Settings view to set the JID,
	// uncomment the section below to hard code a JID and password.
	//
	// myJID = @"user@gmail.com/xmppframework";
	// myPassword = @"";
	
	if (myJID == nil || userPassword1 == nil) {
		return NO;
	}
    //[self.xmppStream setMyJID:[XMPPJID jidWithString:myJID ]];
    //ch.07
	[self.xmppStream setMyJID:[XMPPJID jidWithString:myJID resource:@"iPhone"]];
    
	NSError *error = nil;
	if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
    {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
		                                                    message:@"See console for error details."
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Ok"
		                                          otherButtonTitles:nil];
		[alertView show];
        
		DDLogError(@"Error connecting: %@", error);
        
        return NO;
    }
    
	return YES;
}
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    DDLogInfo(@"xmppStreamDidRegister: ");
}


-(void)connectToServerHost {
    [self connect];
    NSLog(@"connectToServerHost");
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (allowSelfSignedCertificates)
    {
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    }
	
	if (allowSSLHostNameMismatch)
    {
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
    }
	else
    {
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
		
		NSString *expectedCertName = nil;
		
		NSString *serverDomain = self.xmppStream.hostName;
		NSString *virtualDomain = [self.xmppStream.myJID domain];
		
		if ([serverDomain isEqualToString:@"talk.google.com"])
        {
			if ([virtualDomain isEqualToString:@"gmail.com"])
            {
				expectedCertName = virtualDomain;
            }
			else
            {
				expectedCertName = serverDomain;
            }
        }
		else if (serverDomain == nil)
        {
			expectedCertName = virtualDomain;
        }
		else
        {
			expectedCertName = serverDomain;
        }
		
		if (expectedCertName)
        {
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
        }
    }
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	isXmppConnected = YES;
	
	NSError *error = nil;
	
	if (![[self xmppStream] authenticateWithPassword:userPassword error:&error])
    {
		DDLogError(@"Error authenticating: %@", error);
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	[self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSError *err=nil;
    ///check if inband registration is supported
    if (self.xmppStream.supportsInBandRegistration)
    {
        if (![self.xmppStream registerWithPassword:userPassword error:&err])
        {
            DDLogError(@"Oops, I forgot something: %@", error);
        }
    }
    else
    {
        DDLogError(@"Inband registration is not supported");
    }
    
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    
    NSXMLElement *siRequest = [iq elementForName:@"si" xmlns:@"http://jabber.org/protocol/si"];
    NSXMLElement *isByteStream = [iq elementForName:@"query" xmlns:@"http://jabber.org/protocol/bytestreams"];
    NSXMLElement *fileNode= [siRequest elementForName:@"file" xmlns:@"http://jabber.org/protocol/si/profile/file-transfer"];
	if (self.isSending)
    {
      	return NO;
    }
	if (self.isSending && siRequest  )
    {
      	return NO;
    }
    if (siRequest && [iq isSetIQ] && !self.isReceiving)
    {
        NSString *fromjidString = [iq fromStr];
        NSArray *splitter1 = [fromjidString componentsSeparatedByString:@"/"];
        NSString* sendingJID = [splitter1 objectAtIndex:0];
		splitter1=nil;
        
        NSString* mimeType = [[siRequest attributeForName:@"mime-type"] stringValue];
        
        NSString* sendingIQ = [NSString stringWithFormat:@"%@",iq];
        
        NSString* fname = [[fileNode attributeForName:@"name"] stringValue ];
		//create target file
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *extension = @"";
        NSString *mediaType = @"";
        NSArray *splitter = [mimeType componentsSeparatedByString:@"/"];
        if ([splitter count]==2)
        {
			extension = [splitter objectAtIndex:1];
			mediaType = [splitter objectAtIndex:0];
        }
        else
        {    extension = [fname pathExtension];
            if ([extension isEqualToString:@"m4a"])
            { mediaType = @"audio";}
            else   if ([extension isEqualToString:@"mp4"])
            { mediaType = @"video";}
            else   if ([extension isEqualToString:@"m4v"])
            { mediaType = @"video";}
            else   if ([extension isEqualToString:@"mp3"])
            { mediaType = @"audio";}
            else   if ([extension isEqualToString:@"3gp"])
            { mediaType = @"audio";}
            else   if ([extension isEqualToString:@"png"])
            { mediaType = @"image";}
            else   if ([extension isEqualToString:@"jpg"])
            { mediaType = @"image";}
            else   if ([extension isEqualToString:@"jpeg"])
            { mediaType = @"image";}
            else   if ([extension isEqualToString:@"gif"])
            {  mediaType = @"image";}
        }
		
        
        splitter=nil;
		NSString *filepath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,fname];
		paths=nil;
		long long fileSize  = [[[fileNode attributeForName:@"size"] stringValue ] longLongValue];
        
        self.fileInfo = [[YDFileInfo alloc] initWithFileName:fname mediaType:mediaType mimeType:mimeType size:fileSize localName:filepath IQ:sendingIQ fileNameAsSent:@"" sender:sendingJID];
        self.streamID = [[siRequest attributeForName:@"id"] stringValue];
        self.transferID=[[iq attributeForName:@"id"] stringValue];
		NSString *fromJID = [iq fromStr];
        NSLog(@"self.streamIDself.streamID %@ nd %@", self.streamID, self.transferID);
        
        //step 2. we send our prefered stream-method as a response
        NSString *initiatorID = [[iq attributeForName:@"id"] stringValue];
        NSXMLElement *si= [NSXMLElement elementWithName:@"si" xmlns:@"http://jabber.org/protocol/si"];
        [si addAttributeWithName:@"id" stringValue:initiatorID];
        NSXMLElement *feature = [NSXMLElement elementWithName:@"feature" xmlns:@"http://jabber.org/protocol/feature-neg"];
        NSXMLElement *x = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
        [x addAttributeWithName:@"type" stringValue:@"submit"];
        NSXMLElement *field =[NSXMLElement elementWithName:@"field"];
        [field addAttributeWithName:@"var"  stringValue:@"stream-method"];
        NSXMLElement *bs =[NSXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/bytestreams"] ;
        [field addChild:bs];
        [x addChild:field];
        [feature addChild:x];
        [si addChild:feature];
        //Send
        
        self.isReceiving=YES;
        XMPPIQ *iqToReturn = [XMPPIQ iqWithType:@"result" to:[XMPPJID jidWithString:fromJID] elementID:initiatorID child:si];
        [self.xmppStream sendElement:iqToReturn];
        
        return NO;
    }
    else if (isByteStream && [iq isSetIQ] && self.isReceiving )
    {
        self.fileReceiver = [[YDFileReceiver alloc] initWithStream:[self xmppStream] incomingRequest:iq];
        self.fileReceiver.streamID=self.streamID;
        self.fileReceiver.transferID= self.transferID;
        self.fileReceiver.fileInfo = self.fileInfo;
        [self.fileReceiver startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        return YES;
        
    }
    
    return NO;
}
#pragma mark YDFileReceiver delegates
- (void)fileReceiver:(YDFileReceiver *)sender didSucceed:(YDFileInfo *)fileInfo
{
    
    Chat *chat = [NSEntityDescription
                  insertNewObjectForEntityForName:@"Chat"
                  inManagedObjectContext:self.managedObjectContext];
    chat.messageBody = @"file received";
    chat.messageDate = [NSDate date];
    chat.hasMedia=[NSNumber numberWithBool:YES];
    chat.isNew=[NSNumber numberWithBool:YES];
    chat.messageStatus=@"received";
    chat.direction = @"IN";
    chat.groupNumber=@"";
    chat.isGroupMessage=[NSNumber numberWithBool:NO];
    chat.jidString =  fileInfo.sendingJID;
    chat.localfileName = fileInfo.localFileName;
    chat.mimeType=_fileInfo.mimeType;
    chat.mediaType= fileInfo.mediaType;
    chat.filenameAsSent=fileInfo.filenameAsSent;
    NSError *error = nil;
    
    if (![self.managedObjectContext save:&error])
    {
        NSLog(@"error saving");
    }
    self.isReceiving=NO;
    self.fileReceiver = nil;
    //Send notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessage object:self userInfo:nil];
}
-(void)fileReceiverDidFail:(YDFileReceiver *)sender
{
    DDLogError(@"ERROR fileReceiverDidFail");
    self.isReceiving=NO;
}
-(TTMMediaModel *)getURLFromJSON:(NSDictionary *)dict {
    
    NSMutableArray *jsonArray = [dict objectForKey:@"messageList"];
    NSLog(@"jsonArray %@", jsonArray);
    if([jsonArray count]) {
        NSMutableDictionary *temJsonDict = [jsonArray objectAtIndex:0];
        TTMMediaModel *mediaURLs = [[TTMMediaModel alloc] init];
        [mediaURLs setThumbnail:[temJsonDict objectForKey:@"thumbnailPath"]];
        [mediaURLs setOriginal_url:[temJsonDict objectForKey:@"filePath"]];
        
        return mediaURLs;
    }
    return nil;
}
-(void) timerMethod:(NSTimer *)timer{
    
    NSString * timeInterval= [NSString stringWithFormat:@"%@", timer.userInfo]  ;
    NSLog(@"in timerMethod %@", timer.userInfo);
    [timer invalidate];
    TTMMessageInfo *messageInfo = [[TTMMessageInfo alloc] init];
    XMPPMessage *message = [messageInfo loadDataFromDisk:timeInterval];
    [self updateCoreDataWithIncomingMessage:message];
}

-(void)timerRunINBackGroundWithObject:(XMPPMessage *)message timeInterval:(NSString *)milisecond{
    
    long long milliseconds = [milisecond longLongValue];
    long long overALlSeconds = milliseconds - [TTMCommon getUTCTimeInterval];
    float seconds = (overALlSeconds / 1000.0);
    int secondValue = (int)seconds;
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    [infoDict setObject:milisecond forKey:@"TimeDelay"];
//    float minutes = seconds / 60.0;
//    float hours = minutes / 60.0;
    TTMMessageInfo *messageInfo = [TTMMessageInfo initWithXMPPMessageInfo:message];
    [messageInfo saveDataToDisk:milisecond];
    UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;
    UIApplication *app = [UIApplication sharedApplication];
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
    }];
    NSLog(@"seconds seconds seconds %d", secondValue);
    NSTimer  *timer = [NSTimer scheduledTimerWithTimeInterval:secondValue target:self   selector:@selector(timerMethod:) userInfo:(id)[NSString stringWithFormat:@"%@", milisecond] repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

}

-(NSString *)getMessageTypeFromJSON:(NSDictionary *)dict {
    
    NSMutableArray *jsonArray = [dict objectForKey:@"messageList"];
    NSLog(@"jsonArray %@", jsonArray);
    if([jsonArray count]) {
        NSMutableDictionary *temJsonDict = [jsonArray objectAtIndex:0];
        NSLog(@"chat type is with incoming message %@", [NSString stringWithFormat:@"%@",[temJsonDict objectForKey:@"type"]]);
        return [NSString stringWithFormat:@"%@",[temJsonDict objectForKey:@"type"]];
    }
    return nil;
}

-(NSString *)inserMessageTypeinChat:(NSString *)jsonString {
    NSDictionary *JSON =
    [NSJSONSerialization JSONObjectWithData: [jsonString  dataUsingEncoding:NSUTF8StringEncoding]
                                    options: NSJSONReadingMutableContainers
                                      error:nil];
    return [self getMessageTypeFromJSON:JSON];
}

-(void)updateCoreDataWithIncomingMessage:(XMPPMessage *)message
{
    //determine the sender
    XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[message from]
                                                                  xmppStream:self.xmppStream
                                                        managedObjectContext:[self managedObjectContext_roster]];
    NSDictionary *JSON =
    [NSJSONSerialization JSONObjectWithData: [[[message elementForName:@"body"] stringValue] dataUsingEncoding:NSUTF8StringEncoding]
                                    options: NSJSONReadingMutableContainers
                                      error:nil];
	TTMMediaModel *decoder = [self getURLFromJSON:JSON];
    Chat *chat = [NSEntityDescription
                  insertNewObjectForEntityForName:@"Chat"
                  inManagedObjectContext:self.managedObjectContext];
    chat.messageBody = [[message elementForName:@"body"] stringValue];
    chat.messageDate = [NSDate date];
    chat.messageStatus=@"received";
    chat.direction = @"IN";
    chat.groupNumber=@"";
    chat.thumbNail = [NSString stringWithFormat:@"%@", decoder.thumbnail];
    chat.originalURL = [NSString stringWithFormat:@"%@", decoder.original_url];
    chat.chatType = [self inserMessageTypeinChat:[[message elementForName:@"body"] stringValue]];
    chat.isNew = [NSNumber numberWithBool:YES];
    chat.hasMedia=[NSNumber numberWithBool:NO];
    if ([[message type] isEqualToString:@"groupchat"]) {
        chat.isGroupMessage= [NSNumber numberWithBool:YES];
    }else
    {
        chat.isGroupMessage= [NSNumber numberWithBool:NO];
    }
    chat.jidString = user.jidStr;
    NSLog(@"chat.jidString %@",chat.jidString);
    NSError *error = nil;
    if (![self.managedObjectContext save:&error])
    {
        NSLog(@"error saving");
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewMessage object:self userInfo:nil];
}

#pragma mark json value from string
- (id) JSONValue:(NSString *)parameter {
    
	SBJsonParser *jparser = [[SBJsonParser alloc] init];
	id response = [jparser objectWithString:parameter];
	return response;
}
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@  %@", THIS_FILE, THIS_METHOD,message);
     /*// A simple example of inbound message handling.
     //if ([message isChatMessageWithBody] )
     if ([[message type] isEqualToString:@"groupchat"] || [[message type] isEqualToString:@"chat"])
     {
     
     //[self updateCoreDataWithIncomingMessage:message];
     }*/
    
    if (([[message type] isEqualToString:@"groupchat"] || [[message type] isEqualToString:@"chat"]))	{
        
        DDLogInfo(@"Save message in CoreData: %@", message);
        if ([message isChatMessageWithBody] ||[[message type] isEqualToString:@"groupchat"]){
            NSMutableDictionary *messageDict = [self JSONValue:[[message elementForName:@"body"] stringValue]];
            NSLog(@"messageDict messageDict %@", messageDict);

            NSMutableArray *dictArray = [messageDict objectForKey:@"messageList"];
            NSString *timeStamp = [[dictArray objectAtIndex:0] objectForKey:@"timeDelayed"];
            if((timeStamp) || ([timeStamp floatValue] != 0.0)) {
                
                [self timerRunINBackGroundWithObject:message timeInterval:timeStamp];
            }else {
                [self updateCoreDataWithIncomingMessage:message];
            }
        }
		XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:[message from]
                                                                  xmppStream:self.xmppStream
                                                        managedObjectContext:[self managedObjectContext_roster]];
		
		NSString *body = [[message elementForName:@"body"] stringValue];
		NSString *displayName = [user displayName];
        
		if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive && [[message type] isEqualToString:@"groupchat"] )
		{
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
                                                                message:body
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
			[alertView show];
		}
		else
		{
			// We are not active, so use a local notification instead
			UILocalNotification *localNotification = [[UILocalNotification alloc] init];
			localNotification.alertAction = @"Ok";
			localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
            
			[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		}
	}
    else if ([message isChatMessage])
    {
        NSArray *elements = [message elementsForXmlns:@"http://jabber.org/protocol/chatstates"];
        if ([elements count] >0)
        {
            for (NSXMLElement *element in elements)
            {
                NSString *statusString = @" ";
                NSString *cleanStatus = [element.name stringByReplacingOccurrencesOfString:@"cha:" withString:@""];
                if ([cleanStatus isEqualToString:@"composing"])
                    statusString = @" is typing";
                else if ([cleanStatus isEqualToString:@"active"])
                    statusString = @" is ready";
                else  if ([cleanStatus isEqualToString:@"paused"])
                    statusString = @" is pausing";
                else  if ([cleanStatus isEqualToString:@"inactive"])
                    statusString = @" is not active";
                else  if ([cleanStatus isEqualToString:@"gone"])
                    statusString = @" left this chat";
                NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
                [m setObject:statusString forKey:@"msg"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"kChatStatus" object:self userInfo:m];
                
            }
        }
    }
}


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
	
	NSString *presenceType = [presence type]; // online/offline
	NSString *myUsername = [[sender myJID] user];
	NSString *presenceFromUser = [[presence from] user];
    
	if (![presenceFromUser isEqualToString:myUsername]) {
		
		if ([presenceType isEqualToString:@"available"]) {
			NSLog(@"Chat Delegate is %@", [[self.xmppStream myJID] resource]);
			[self.chatDelegate newBuddyOnline:[NSString stringWithFormat:@"%@@%@", presenceFromUser, [TTMCommon getChatServerHostName]]];
			
		} else if ([presenceType isEqualToString:@"unavailable"]) {
			
			[self.chatDelegate buddyWentOffline:[NSString stringWithFormat:@"%@@%@", presenceFromUser, [TTMCommon getChatServerHostName]]];
		} else if  ([presenceType isEqualToString:@"subscribe"]) {
            
            [[NSNotificationCenter defaultCenter]postNotificationName:@"FriendRequestIdentified" object:[NSString stringWithFormat:@"%@", presenceFromUser]];
            
        } else if  ([presenceType isEqualToString:@"unsubscribe"]) {
            
        }
	}
}

//- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
//{
//	DDLogInfo(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
//    NSString *userResource = [[[presence attributeForName:@"from"] stringValue] lastPathComponent];
//    //Store the resource in CoreData for later usage
//}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (!isXmppConnected)
    {
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark MUC Delegate
- (void)xmppMUC:(XMPPMUC *)sender didReceiveRoomInvitation:(XMPPMessage *)message
{
    //isGroupChatInvite is defined in XMPPMessage+0045 category
    if ([message isGroupChatInvite])
    {
        NSString *roomJidString = [message fromStr];
#if USE_MEMORY_STORAGE
        xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
#elif USE_HYBRID_STORAGE
        xmppRoomStorage = [XMPPRoomCoreDataStorage sharedInstance];
#endif
        
        XMPPRoom *newRoom = [[XMPPRoom alloc] initWithRoomStorage:xmppRoomStorage jid:[XMPPJID jidWithString:roomJidString]];
        [newRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [newRoom activate:[self xmppStream]];
        //Add it to CoreData
        Room  *room =[NSEntityDescription
                      insertNewObjectForEntityForName:@"Room"
                      inManagedObjectContext:self.managedObjectContext];
        room.roomJID = roomJidString;
        //clean the name
        NSString *roomName = [roomJidString stringByReplacingOccurrencesOfString:kxmppConferenceServer  withString:@""];
        roomName=[roomName stringByReplacingOccurrencesOfString:@"@" withString:@""];
        
        
        room.name = roomName;
        NSError *error = nil;
        if (![self.managedObjectContext save:&error])
        {
            NSLog(@"error saving");
        }
    }
}
- (void)xmppMUC:(XMPPMUC *)sender didReceiveRoomInvitationDecline:(XMPPMessage *)message
{
    DDLogInfo(@"%@: %@  %@", THIS_FILE, THIS_METHOD,message);
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)sendInvitationToJID:(NSString *)_jid withNickName:(NSString *)_nickName
{
    
    [self.xmppRoster addUser:[XMPPJID jidWithString:_jid] withNickname:_nickName];
    [self.xmppRoster subscribePresenceToUser:[XMPPJID jidWithString:_jid]];
}

- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[presence from]
                                                                  xmppStream:self.xmppStream
                                                        managedObjectContext:[self managedObjectContext_roster]];
    DDLogVerbose(@"didReceivePresenceSubscriptionRequest from user %@ ", user.jidStr);
    [self.xmppRoster acceptPresenceSubscriptionRequestFrom:[presence from] andAddToRoster:YES];
}
- (void)disconnect
{
	[self goOffline];
	[self.xmppStream disconnect];
}
- (void)dealloc {
	
	[xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
	[xmppStream disconnect];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   // [self disconnect];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
#if TARGET_IPHONE_SIMULATOR
	DDLogError(@"The iPhone simulator does not process background network traffic. "
			   @"Inbound traffic is queued until the keepAliveTimeout:handler: fires.");
#endif
    
	if ([application respondsToSelector:@selector(setKeepAliveTimeout:handler:)])
    {
		[application setKeepAliveTimeout:600 handler:^{
			
			DDLogVerbose(@"KeepAliveHandler");
			
			// Do other keep alive stuff here.
		}];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self connect];

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self connect];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark COREDATA
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
        [__managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        // subscribe to change notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mocDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return __managedObjectContext;
}
//

- (void)_mocDidSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *savedContext = [notification object];
    
    // ignore change notifications for the main MOC
    if (__managedObjectContext == savedContext)
    {
        return;
    }
    
    if (__managedObjectContext.persistentStoreCoordinator != savedContext.persistentStoreCoordinator)
    {
        // that's another database
        return;
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [__managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    });
}
//
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ChatModel" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"YDChat.sqlite"];   NSError *error = nil;
    
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
        
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return __persistentStoreCoordinator;
}


@end

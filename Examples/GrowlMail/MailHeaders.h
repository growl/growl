
@class MailboxUid, MFError;


@interface MailNotificationCenter : NSNotificationCenter
{
    struct _NSHashTable *nameTable;
}

+ (void)initialize;
+ (id)defaultMailCenter;
- (id)init;
- (void)addObserverInMainThread:(id)fp8 selector:(SEL)fp12 name:(id)fp16 object:(id)fp20;
- (void)postNotification:(id)fp8;
- (void)postNotificationName:(id)fp8 object:(id)fp12 userInfo:(id)fp16;
- (void)_postNotificationWithMangledName:(id)fp8 object:(id)fp12 userInfo:(id)fp16;
- (void)removeObserver:(id)fp8 name:(id)fp12 object:(id)fp16;
@end


@interface MVMailBundle : NSObject
{
	
}

+ allBundles;
+ composeAccessoryViewOwners;
+ (void)registerBundle;
+ sharedInstance;
+ (BOOL)hasPreferencesPanel;
+ preferencesOwnerClassName;
+ preferencesPanelName;
+ (BOOL)hasComposeAccessoryViewOwner;
+ composeAccessoryViewOwnerClassName;
- (void)dealloc;
- (void)_registerBundleForNotifications;

@end

@interface Account : NSObject
{
    NSMutableDictionary *_info;
    unsigned int _isOffline:1;
    unsigned int _willingToGoOnline:1;
    unsigned int _autosynchronizingEnabled:1;
    unsigned int _ignoreSSLCertificates:1;
    unsigned int _promptedToIgnoreSSLCertificates:1;
}

+ (void)initialize;
+ (BOOL)haveAccountsBeenConfigured;
+ (id)readAccountsUsingDefaultsKey:(id)fp8;
+ (void)saveAccounts:(id)fp8 usingDefaultsKey:(id)fp12;
+ (void)saveAccountInfoToDefaults;
+ (id)createAccountWithDictionary:(id)fp8;
+ (id)accountTypeString;
+ (BOOL)allObjectsInArrayAreOffline:(id)fp8;
- (id)init;
- (void)dealloc;
- (void)setAutosynchronizingEnabled:(BOOL)fp8;
- (void)_queueAccountInfoDidChange;
- (id)accountInfo;
- (void)_setAccountInfo:(id)fp8;
- (void)setAccountInfo:(id)fp8;
- (id)defaultsDictionary;
- (BOOL)isActive;
- (void)setIsActive:(BOOL)fp8;
- (BOOL)canGoOffline;
- (BOOL)isOffline;
- (void)setIsOffline:(BOOL)fp8;
- (BOOL)isWillingToGoOnline;
- (void)setIsWillingToGoOnline:(BOOL)fp8;
- (id)displayName;
- (void)setDisplayName:(id)fp8;
- (id)username;
- (void)setUsername:(id)fp8;
- (id)hostname;
- (void)setHostname:(id)fp8;
- (void)setPasswordInKeychain:(id)fp8;
- (void)_removePasswordInKeychain;
- (void)setTemporaryPassword:(id)fp8;
- (void)setPassword:(id)fp8;
- (id)passwordFromStoredUserInfo;
- (id)passwordFromKeychain;
- (id)password;
- (id)promptUserForPasswordWithMessage:(id)fp8;
- (id)promptUserIfNeededForPasswordWithMessage:(id)fp8;
- (unsigned int)portNumber;
- (unsigned int)defaultPortNumber;
- (unsigned int)defaultSecurePortNumber;
- (void)setPortNumber:(unsigned int)fp8;
- (id)serviceName;
- (id)secureServiceName;
- (void)releaseAllConnections;
- (void)validateConnections;
- (BOOL)usesSSL;
- (void)setUsesSSL:(BOOL)fp8;
- (id)sslProtocolVersion;
- (void)setSSLProtocolVersion:(id)fp8;
- (void)accountInfoDidChange;
- (id)securityProtocol;
- (void)setSecurityProcol:(id)fp8;
- (id)preferredAuthScheme;
- (void)setPreferredAuthScheme:(id)fp8;
- (id)saslProfileName;
- (Class)connectionClass;
- (BOOL)requiresAuthentication;
- (id)authenticatedConnection;
- (BOOL)_shouldTryDirectSSLConnectionOnPort:(unsigned int)fp8;
- (BOOL)_shouldRetryConnectionWithoutCertificateCheckingAfterError:(id)fp8;
- (BOOL)_connectAndAuthenticate:(id)fp8;
- (BOOL)_ignoreSSLCertificates;
- (void)_setIgnoreSSLCertificates:(BOOL)fp8;

@end

@interface MailAccount : Account
{
    NSString *_path;
    MailboxUid *_rootMailboxUid;
    struct {
        unsigned int cacheDirtyCount:16;
        unsigned int synchronizationThreadIsRunning:1;
        unsigned int backgroundFetchInProgress:1;
        unsigned int cacheHasBeenRead:1;
        unsigned int disableCacheWrite:1;
        unsigned int _UNUSED_:12;
    } _flags;
    MailboxUid *_inboxMailboxUid;
    MailboxUid *_draftsMailboxUid;
    MailboxUid *_sentMessagesMailboxUid;
    MailboxUid *_trashMailboxUid;
    MailboxUid *_junkMailboxUid;
    MFError *_lastConnectionError;
}

+ (void)initialize;
+ (BOOL)mailboxListingNotificationAreEnabled;
+ (void)disableMailboxListingNotifications;
+ (void)enableMailboxListingNotifications;
+ (BOOL)haveAccountsBeenConfigured;
+ (void)_addAccountToSortedPaths:(id)fp8;
+ (id)mailAccounts;
+ (void)setMailAccounts:(id)fp8;
+ (void)_removeAccountFromSortedPaths:(id)fp8;
+ (id)activeAccounts;
+ (void)saveAccountInfoToDefaults;
+ (id)allEmailAddressesIncludingFullUserName:(BOOL)fp8;
+ (id)_accountContainingEmailAddress:(id)fp8 matchingAddress:(id *)fp12 fullUserName:(id *)fp16;
+ (id)accountContainingEmailAddress:(id)fp8;
+ (id)accountThatMessageIsFrom:(id)fp8;
+ (id)accountThatReceivedMessage:(id)fp8 matchingEmailAddress:(id *)fp12 fullUserName:(id *)fp16;
+ (id)outboxMessageStore:(BOOL)fp8;
+ (id)specialMailboxUids;
+ (id)_specialMailboxUidsUsingSelector:(SEL)fp8;
+ (id)inboxMailboxUids;
+ (id)trashMailboxUids;
+ (id)outboxMailboxUids;
+ (id)sentMessagesMailboxUids;
+ (id)draftMailboxUids;
+ (id)junkMailboxUids;
+ (id)allMailboxUids;
+ (id)accountWithPath:(id)fp8;
+ (id)newAccountWithPath:(id)fp8;
+ (id)createAccountWithDictionary:(id)fp8;
+ (id)defaultPathForAccountWithHostname:(id)fp8 username:(id)fp12;
+ (id)defaultAccountDirectory;
+ (id)defaultPathNameForAccountWithHostname:(id)fp8 username:(id)fp12;
+ (id)defaultDeliveryAccount;
+ (BOOL)isAnyAccountOffline;
+ (BOOL)isAnyAccountOnline;
+ (void)_setOnlineStateOfAllAccountsTo:(BOOL)fp8;
+ (void)disconnectAllAccounts;
+ (void)connectAllAccounts;
+ (void)saveStateForAllAccounts;
+ (int)numberOfDaysToKeepLocalTrash;
+ (BOOL)allAccountsDeleteInPlace;
+ (void)synchronouslyEmptyMailboxUidType:(int)fp8 inAccounts:(id)fp12;
+ (void)resetAllSpecialMailboxes;
+ (id)mailboxUidForFileSystemPath:(id)fp8 create:(BOOL)fp12;
+ (void)deleteMailboxUidIfEmpty:(id)fp8;
- (void)synchronizeMailboxListAfterImport;
- (BOOL)isValidAccountWithError:(id)fp8 accountBeingEdited:(id)fp12 userCanOverride:(char *)fp16;
- (BOOL)cheapStoreAtPathIsEmpty:(id)fp8;
- (id)init;
- (id)initWithPath:(id)fp8;
- (void)dealloc;
- (id)path;
- (void)setPath:(id)fp8;
- (id)tildeAbbreviatedPath;
- (id)applescriptFullUserName;
- (void)setApplescriptFullUserName:(id)fp8;
- (id)fullUserName;
- (void)setFullUserName:(id)fp8;
- (id)deliveryAccount;
- (void)setDeliveryAccount:(id)fp8;
- (void)deliveryAccountWillBeRemoved:(id)fp8;
- (id)firstEmailAddress;
- (id)rawEmailAddresses;
- (id)emailAddresses;
- (id)applescriptEmailAddresses;
- (void)setApplescriptEmailAddresses:(id)fp8;
- (void)setEmailAddresses:(id)fp8;
- (BOOL)shouldAutoFetch;
- (void)setShouldAutoFetch:(BOOL)fp8;
- (BOOL)fileManager:(id)fp8 shouldProceedAfterError:(id)fp12;
- (void)_synchronouslyInvalidateAndDelete:(BOOL)fp8;
- (void)deleteAccount;
- (void)saveState;
- (void)releaseAllConnections;
- (void)setIsOffline:(BOOL)fp8;
- (void)setIsWillingToGoOnline:(BOOL)fp8;
- (BOOL)canFetch;
- (id)defaultsDictionary;
- (void)nowWouldBeAGoodTimeToStartBackgroundSynchronization;
- (BOOL)canAppendMessages;
- (BOOL)canBeSynchronized;
- (void)synchronizeAllMailboxes;
- (void)fetchAsynchronously;
- (void)fetchSynchronously;
- (BOOL)isFetching;
- (void)newMailHasBeenReceived;
- (id)primaryMailboxUid;
- (id)rootMailboxUid;
- (id)draftsMailboxUidCreateIfNeeded:(BOOL)fp8;
- (id)junkMailboxUidCreateIfNeeded:(BOOL)fp8;
- (id)sentMessagesMailboxUidCreateIfNeeded:(BOOL)fp8;
- (id)trashMailboxUidCreateIfNeeded:(BOOL)fp8;
- (id)allMailboxUids;
- (void)setDraftsMailboxUid:(id)fp8;
- (void)setTrashMailboxUid:(id)fp8;
- (void)setJunkMailboxUid:(id)fp8;
- (void)setSentMessagesMailboxUid:(id)fp8;
- (void)deleteMessagesFromMailboxUid:(id)fp8 olderThanNumberOfDays:(unsigned int)fp12 compact:(BOOL)fp16;
- (void)_setEmptyFrequency:(int)fp8 forKey:(id)fp12;
- (int)_emptyFrequencyForKey:(id)fp8 defaultValue:(id)fp12;
- (int)emptySentMessagesFrequency;
- (void)setEmptySentMessagesFrequency:(int)fp8;
- (int)emptyJunkFrequency;
- (void)setEmptyJunkFrequency:(int)fp8;
- (int)emptyTrashFrequency;
- (void)setEmptyTrashFrequency:(int)fp8;
- (BOOL)shouldMoveDeletedMessagesToTrash;
- (void)setShouldMoveDeletedMessagesToTrash:(BOOL)fp8;
- (void)emptySpecialMailboxesThatNeedToBeEmptiedAtQuit;
- (id)displayName;
- (id)displayNameForMailboxUid:(id)fp8;
- (BOOL)containsMailboxes;
- (void)resetSpecialMailboxes;
- (id)mailboxPathExtension;
- (BOOL)canCreateNewMailboxes;
- (BOOL)newMailboxNameIsAcceptable:(id)fp8 reasonForFailure:(id *)fp12;
- (BOOL)canMailboxBeRenamed:(id)fp8;
- (BOOL)canMailboxBeDeleted:(id)fp8;
- (id)createMailboxWithParent:(id)fp8 name:(id)fp12;
- (BOOL)renameMailbox:(id)fp8 newName:(id)fp12 parent:(id)fp16;
- (BOOL)deleteMailbox:(id)fp8;
- (void)accountInfoDidChange;
- (void)postUserInfoHasChangedForMailboxUid:(id)fp8 userInfo:(id)fp12;
- (void)setConnectionError:(id)fp8;
- (id)connectionError;
- (id)storeForMailboxUid:(id)fp8;
- (Class)storeClass;
- (void)setUnreadCount:(unsigned int)fp8 forMailbox:(id)fp12;
- (BOOL)hasUnreadMail;
- (id)mailboxUidForRelativePath:(id)fp8 create:(BOOL)fp12;
- (id)valueInMailboxesWithName:(id)fp8;
- (id)objectSpecifierForMessageStore:(id)fp8;
- (id)objectSpecifierForMailboxUid:(id)fp8;
- (id)objectSpecifier;

@end


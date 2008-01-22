#import "MailHeaders.h"

//Class-dumped, and slightly modified, by Peter Hosey on 2007-11-25 from Message.framework on Mac OS X 10.4.10 UB.

@interface ObjectCache : NSObject
{
    unsigned int _arrayCapacity;
    NSArray *_keysAndValues;
    BOOL _useIsEqual;
}

- (id)initWithCapacity:(unsigned int)fp8;
- (void)dealloc;
- (void)finalize;
- (void)setCapacity:(unsigned int)fp8;
- (void)setUsesIsEqualForComparison:(BOOL)fp8;
- (void)setObject:(id)fp8 forKey:(id)fp12;
- (id)objectForKey:(id)fp8;
- (void)removeObjectForKey:(id)fp8;
- (void)removeAllObjects;
- (BOOL)isObjectInCache:(id)fp8;

@end

@interface MessageCriterion : NSObject
{
    NSString *_uniqueId;
    NSString *_criterionIdentifier;
    NSString *_expression;
    int _qualifier;
    NSString *_groupUniqueId;
    NSArray *_criteria;
    int _dateUnitType;
    int specialMailboxType;
    NSString *_name;
    unsigned int _allCriteriaMustBeSatisfied:1;
    unsigned int _dateIsRelative:1;
    NSString *_cachedAccountURLForSyncConflictResolution;
}

+ (void)initialize;
+ (id)criteriaFromDefaultsArray:(id)fp8;
+ (id)criteriaFromDefaultsArray:(id)fp8 removingRecognizedKeys:(BOOL)fp12;
+ (id)defaultsArrayFromCriteria:(id)fp8;
+ (void)_updateAddressComments:(id)fp8;
+ (int)criterionTypeForString:(id)fp8;
+ (id)stringForCriterionType:(int)fp8;
- (id)init;
- (id)initWithCriterion:(id)fp8 expression:(id)fp12;
- (id)initWithDictionary:(id)fp8;
- (id)initWithDictionary:(id)fp8 andRemoveRecognizedKeysIfMutable:(BOOL)fp12;
- (void)dealloc;
- (void)finalize;
- (BOOL)isEqual:(id)fp8;
- (id)descriptionWithDepth:(unsigned int)fp8;
- (id)description;
- (id)dictionaryRepresentation;
- (int)criterionType;
- (void)setCriterionType:(int)fp8;
- (id)criterionIdentifier;
- (void)setCriterionIdentifier:(id)fp8;
- (id)_qualifierString;
- (int)qualifier;
- (void)setQualifier:(int)fp8;
- (id)expression;
- (void)setExpression:(id)fp8;
- (id)groupUniqueId;
- (void)setGroupUniqueId:(id)fp8;
- (id)recursiveGroupUniqueIds;
- (id)name;
- (void)setName:(id)fp8;
- (id)_headersRequiredForEvaluation;
- (void)addHeadersRequiredForRoutingToArray:(id)fp8;
- (BOOL)_evaluateDateCriterion:(id)fp8;
- (BOOL)_evaluateHeaderCriterion:(id)fp8;
- (BOOL)_evaluateBodyCriterion:(id)fp8;
- (BOOL)_evaluateAddressBookCriterion:(id)fp8;
- (BOOL)_doesGroup:(id)fp8 containSender:(id)fp12;
- (BOOL)_evaluateMemberOfGroupCriterion:(id)fp8;
- (BOOL)_evaluateAccountCriterion:(id)fp8;
- (BOOL)_evaluateAddressHistoryCriterion:(id)fp8;
- (BOOL)_evaluateFullNameCriterion:(id)fp8;
- (BOOL)_evaluateIsDigitallySignedCriterion:(id)fp8;
- (BOOL)_evaluateIsEncryptedCriterion:(id)fp8;
- (BOOL)_evaluatePriorityIsNormalCriterion:(id)fp8;
- (BOOL)_evaluatePriorityIsHighCriterion:(id)fp8;
- (BOOL)_evaluatePriorityIsLowCriterion:(id)fp8;
- (BOOL)_evaluateJunkMailCriterion:(id)fp8;
- (BOOL)_evaluateAttachmentCriterion:(id)fp8;
- (BOOL)doesMessageSatisfyCriterion:(id)fp8;
- (int)messageRuleQualifierForString:(id)fp8;
- (id)stringForMessageRuleQualifier:(int)fp8;
- (BOOL)hasExpression;
- (BOOL)hasQualifier;
- (BOOL)isValid:(id *)fp8;
- (id)criteria;
- (void)setCriteria:(id)fp8;
- (BOOL)allCriteriaMustBeSatisfied;
- (void)setAllCriteriaMustBeSatisfied:(BOOL)fp8;
- (int)dateUnits;
- (void)setDateUnits:(int)fp8;
- (BOOL)dateIsRelative;
- (void)setDateIsRelative:(BOOL)fp8;
- (int)specialMailboxType;
- (void)setSpecialMailboxType:(int)fp8;
- (BOOL)containsBodyCriterion;

@end

@interface MFError : NSError
{
    NSMutableDictionary *_moreUserInfo;
}

+ (id)errorWithDomain:(id)fp8 code:(long)fp12 localizedDescription:(id)fp16;
+ (id)errorWithDomain:(id)fp8 code:(long)fp12 localizedDescription:(id)fp16 title:(id)fp20 helpTag:(id)fp24 userInfo:(id)fp28;
+ (id)errorWithException:(id)fp8;
- (void)setUserInfoObject:(id)fp8 forKey:(id)fp12;
- (id)userInfo;
- (id)localizedDescription;
- (id)moreInfo;
- (id)helpAnchor;
- (id)shortDescription;
- (void)setLocalizedDescription:(id)fp8;
- (void)setMoreInfo:(id)fp8;
- (void)setHelpTag:(id)fp8;
- (void)setShortDescription:(id)fp8;
- (void)useGenericDescription:(id)fp8;
- (BOOL)alertShowHelp:(id)fp8;
- (void)dealloc;
- (void)finalize;

@end

@interface NSError (MessageAdditions)
- (BOOL)isUserCancelledError;
- (BOOL)shouldBeReportedToUser;
- (id)moreInfo;
- (id)helpAnchor;
- (id)shortDescription;
@end

@interface ActivityMonitor : NSObject
{
    NSMachPort *_cancelPort;
    NSString *_taskName;
    NSString *_statusMessage;
    NSString *_descriptionString;
    double _percentDone;
    unsigned int _key:13;
    unsigned int _canCancel:1;
    unsigned int _shouldCancel:1;
    unsigned int _isActive:1;
    unsigned int _priority:8;
    unsigned int _changeCount:8;
    id _delegate;
    id _target;
    MFError *_error;
    int shouldUnifyDoneness;
    float previousDoneness;
    int currentProgressStage;
    int numberOfProgressStages;
    double _startTime;
}

+ (id)currentMonitor;
- (id)init;
- (void)dealloc;
- (void)finalize;
- (BOOL)isActive;
- (void)setDelegate:(id)fp8;
- (void)postActivityStarting;
- (void)handlePortMessage:(id)fp8;
- (void)postActivityFinished;
- (void)_didChange;
- (int)changeCount;
- (void)setStatusMessage:(id)fp8;
- (void)setStatusMessage:(id)fp8 percentDone:(double)fp12;
- (id)statusMessage;
- (void)setPercentDone:(double)fp8;
- (double)percentDone;
- (float)unifiedFractionDone;
- (void)beginProgressFor:(int)fp8;
- (unsigned char)priority;
- (void)setPriority:(unsigned char)fp8;
- (id)description;
- (id)taskName;
- (void)setTaskName:(id)fp8;
- (void)setActivityTarget:(id)fp8;
- (id)activityTarget;
- (void)addActivityTarget:(id)fp8;
- (void)removeActivityTarget:(id)fp8;
- (void)setPrimaryTarget:(id)fp8;
- (id)activityTargets;
- (BOOL)canBeCancelled;
- (void)setCanBeCancelled:(BOOL)fp8;
- (BOOL)shouldCancel;
- (void)setShouldCancel:(BOOL)fp8;
- (void)cancel;
- (int)acquireExclusiveAccessKey;
- (void)relinquishExclusiveAccessKey:(int)fp8;
- (void)setStatusMessage:(id)fp8 percentDone:(double)fp12 withKey:(int)fp20;
- (void)setStatusMessage:(id)fp8 withKey:(int)fp12;
- (void)setPercentDone:(double)fp8 withKey:(int)fp16;
- (id)error;
- (void)setError:(id)fp8;
- (id)cancelPort;

@end

@interface SafeObserver : NSObject
{
    unsigned int _retainCount;
}

+ (void)initialize;
+ (void)lockSafeObservers;
+ (void)unlockSafeObservers;
- (id)init;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (id)retain;
- (id)willBeReleased;
- (void)release;
- (unsigned int)retainCount;

@end

@interface MessageStore : SafeObserver
{
    struct {
        unsigned int isReadOnly:1;
        unsigned int hasUnsavedChangesToMessageData:1;
        unsigned int haveOpenLockFile:1;
        unsigned int rebuildingTOC:1;
        unsigned int compacting:1;
        unsigned int cancelInvalidation:1;
        unsigned int forceInvalidation:1;
        unsigned int isWritingChangesToDisk:1;
        unsigned int isTryingToClose:1;
        unsigned int compactOnClose:1;
        unsigned int reserved:22;
    } _flags;
    MailboxUid *_mailboxUid;
    MailAccount *_account;
    NSMutableArray *_allMessages;
    unsigned int _allMessagesSize;
    unsigned int _deletedMessagesSize;
    unsigned int _deletedMessageCount;
    unsigned int _unreadMessageCount;
    int _state;
    union {
        struct {
            ObjectCache *_headerDataCache;
            ObjectCache *_headerCache;
            ObjectCache *_bodyDataCache;
            ObjectCache *_bodyCache;
        } objectCaches;
        struct {
            NSDictionary *_headerDataCache;
            NSDictionary *_headerCache;
            NSDictionary *_bodyDataCache;
            NSDictionary *_bodyCache;
        } intKeyCaches;
    } _caches;
    NSTimer *_timer;
    NSMutableSet *_uniqueStrings;
    double timeOfLastAutosaveOperation;
    ActivityMonitor *_openMonitor;
}

+ (void)initialize;
+ (struct _NSMapTable *)_storeCacheMapTable;
+ (unsigned int)numberOfCurrentlyOpenStores;
+ (id)descriptionOfOpenStores;
+ (id)currentlyAvailableStoreForUid:(id)fp8;
+ (id)currentlyAvailableStoresForAccount:(id)fp8;
+ (id)registerAvailableStore:(id)fp8;
+ (void)removeStoreFromCache:(id)fp8;
+ (BOOL)createEmptyStoreIfNeededForPath:(id)fp8 notIndexable:(BOOL)fp12;
+ (BOOL)createEmptyStoreForPath:(id)fp8;
+ (BOOL)storeAtPathIsWritable:(id)fp8;
+ (BOOL)cheapStoreAtPathIsEmpty:(id)fp8;
+ (int)copyMessages:(id)fp8 toMailboxUid:(id)fp12 shouldDelete:(BOOL)fp16;
- (void)queueSaveChangesInvocation;
- (id)willBeReleased;
- (id)initWithMailboxUid:(id)fp8 readOnly:(BOOL)fp12;
- (id)copyWithZone:(struct _NSZone *)fp8;
- (void)dealloc;
- (void)finalize;
- (void)openAsynchronouslyUpdatingMetadata:(BOOL)fp8;
- (void)openAsynchronously;
- (void)openAsynchronouslyWithOptions:(unsigned int)fp8;
- (void)openSynchronously;
- (void)openSynchronouslyUpdatingMetadata:(BOOL)fp8;
- (void)updateMetadataAsynchronously;
- (void)updateMetadata;
- (void)didOpen;
- (void)cancelOpen;
- (void)writeUpdatedMessageDataToDisk;
- (void)invalidateSavingChanges:(BOOL)fp8;
- (id)account;
- (id)mailboxUid;
- (BOOL)isOpened;
- (id)storePathRelativeToAccount;
- (id)displayName;
- (const char *)displayNameForLogging;
- (BOOL)isReadOnly;
- (id)description;
- (BOOL)isTrash;
- (BOOL)isDrafts;
- (void)messageFlagsDidChange:(id)fp8 flags:(id)fp12;
- (void)structureDidChange;
- (void)messagesWereAdded:(id)fp8;
- (void)messagesWereCompacted:(id)fp8;
- (void)updateUserInfoToLatestValues;
- (unsigned int)totalMessageSize;
- (void)deletedCount:(unsigned int *)fp8 andSize:(unsigned int *)fp12;
- (unsigned int)totalCount;
- (unsigned int)unreadCount;
- (unsigned int)indexOfMessage:(id)fp8;
- (id)copyOfAllMessages;
- (id)mutableCopyOfAllMessages;
- (id)copyOfAllMessagesWithOptions:(unsigned int)fp8;
- (void)addMessagesToAllMessages:(id)fp8;
- (void)addMessageToAllMessages:(id)fp8;
- (void)insertMessageToAllMessages:(id)fp8 atIndex:(unsigned int)fp12;
- (id)_defaultRouterDestination;
- (id)routeMessages:(id)fp8;
- (id)finishRoutingMessages:(id)fp8 routed:(id)fp12;
- (id)routeMessages:(id)fp8 isUserAction:(BOOL)fp12;
- (BOOL)canRebuild;
- (void)rebuildTableOfContentsAsynchronously;
- (BOOL)canCompact;
- (void)doCompact;
- (void)deleteMessagesOlderThanNumberOfDays:(int)fp8 compact:(BOOL)fp12;
- (void)deleteMessages:(id)fp8 moveToTrash:(BOOL)fp12;
- (void)undeleteMessages:(id)fp8;
- (void)deleteLastMessageWithHeader:(id)fp8 forHeaderKey:(id)fp12 compactWhenDone:(BOOL)fp16;
- (BOOL)allowsAppend;
- (int)undoAppendOfMessageIDs:(id)fp8;
- (int)appendMessages:(id)fp8 unsuccessfulOnes:(id)fp12 newMessageIDs:(id)fp16 newMessages:(id)fp20;
- (int)appendMessages:(id)fp8 unsuccessfulOnes:(id)fp12 newMessageIDs:(id)fp16;
- (int)appendMessages:(id)fp8 unsuccessfulOnes:(id)fp12;
- (id)messageWithValue:(id)fp8 forHeader:(id)fp12 options:(unsigned int)fp16;
- (id)messageForMessageID:(id)fp8;
- (id)headerDataForMessage:(id)fp8;
- (id)bodyDataForMessage:(id)fp8;
- (id)fullBodyDataForMessage:(id)fp8 andHeaderDataIfReadilyAvailable:(id *)fp12;
- (id)fullBodyDataForMessage:(id)fp8;
- (id)bodyForMessage:(id)fp8 fetchIfNotAvailable:(BOOL)fp12;
- (id)bodyForMessage:(id)fp8 fetchIfNotAvailable:(BOOL)fp12 updateFlags:(BOOL)fp16;
- (id)headersForMessage:(id)fp8;
- (id)headersForMessage:(id)fp8 fetchIfNotAvailable:(BOOL)fp12;
- (id)dataForMimePart:(id)fp8;
- (BOOL)hasCachedDataForMimePart:(id)fp8;
- (id)uniquedString:(id)fp8;
- (id)colorForMessage:(id)fp8;
- (BOOL)_shouldChangeComponentMessageFlags;
- (BOOL)_shouldChangeComponentMessageFlagsForMessage:(id)fp8;
- (id)setFlagsFromDictionary:(id)fp8 forMessages:(id)fp12;
- (id)setFlagsFromDictionary:(id)fp8 forMessage:(id)fp12;
- (void)setFlag:(id)fp8 state:(BOOL)fp12 forMessages:(id)fp16;
- (BOOL)hasUnsavedChangesToMessageData;
- (void)setColor:(id)fp8 highlightTextOnly:(BOOL)fp12 forMessages:(id)fp16;
- (void)messageColorsNeedToBeReevaluated;
- (void)startSynchronization;
- (id)_getSerialNumberString;
- (void)setNumberOfAttachments:(unsigned int)fp8 isSigned:(BOOL)fp12 isEncrypted:(BOOL)fp16 forMessage:(id)fp20;
- (void)updateNumberOfAttachmentsForMessages:(id)fp8;
- (void)updateMessageColorsSynchronouslyForMessages:(id)fp8;
- (void)updateMessageColorsAsynchronouslyForMessages:(id)fp8;
- (void)setJunkMailLevel:(int)fp8 forMessages:(id)fp12;
- (void)setJunkMailLevel:(int)fp8 forMessages:(id)fp12 trainJunkMailDatabase:(BOOL)fp16;
- (id)status;
- (void)fetchSynchronously;
- (BOOL)setPreferredEncoding:(unsigned long)fp8 forMessage:(id)fp12;
- (void)suggestSortOrder:(id)fp8 ascending:(BOOL)fp12;
- (id)sortOrder;
- (BOOL)isSortedAscending;

@end

@interface LibraryStore : MessageStore
{
    MessageCriterion *_criterion;
    NSString *_query;
    double _lastUpdated;
    NSString *_url;
    unsigned int _openOptions;
    NSMutableSet *_memberMessageIDs;
    unsigned int _messageAvailabilityCount;
    BOOL _mailboxUnreadCountUpdatePending;
    NSMutableArray *_allMessagesDuringOpening;
}

+ (void)initialize;
+ (struct _NSMapTable *)_storeCacheMapTable;
+ (unsigned int)defaultLoadOptions;
+ (id)storeWithCriterion:(id)fp8;
+ (id)storeWithMailbox:(id)fp8;
+ (id)sharedInstance;
+ (BOOL)createEmptyStoreForPath:(id)fp8;
+ (BOOL)storeAtPathIsWritable:(id)fp8;
- (id)initWithCriterion:(id)fp8 mailbox:(id)fp12 readOnly:(BOOL)fp16;
- (id)initWithCriterion:(id)fp8;
- (id)initWithMailboxUid:(id)fp8 readOnly:(BOOL)fp12;
- (id)initWithMailbox:(id)fp8;
- (id)mailbox;
- (void)updateCriterionFromMailbox;
- (void)_updateMailboxUnreadCount;
- (void)addCountsForMessages:(id)fp8 shouldUpdateUnreadCount:(BOOL)fp12;
- (BOOL)shouldCancel;
- (void)_newMessagesAvailable:(id)fp8;
- (void)_addInvocationToQueue:(id)fp8;
- (void)newMessagesAvailable:(id)fp8;
- (void)libraryFinishedSendingMessages;
- (void)openAsynchronouslyWithOptions:(unsigned int)fp8;
- (void)openSynchronouslyUpdatingMetadata:(BOOL)fp8;
- (unsigned int)totalCount;
- (id)copyOfAllMessages;
- (id)copyOfAllMessagesWithOptions:(unsigned int)fp8;
- (void)recalculateUnreadCountAsychronously;
- (void)_recalculateUnreadCountSynchronously;
- (id)filterMessagesByMembership:(id)fp8;
- (void)messagesAdded:(id)fp8;
- (void)handleMessagesAdded:(id)fp8;
- (void)messagesWereAdded:(id)fp8 forIncrementalLoading:(BOOL)fp12;
- (void)messageFlagsChanged:(id)fp8;
- (void)handleMessageFlagsChanged:(id)fp8;
- (void)messagesCompacted:(id)fp8;
- (void)handleMessagesCompacted:(id)fp8;
- (void)dealloc;
- (void)finalize;
- (id)messageForMessageID:(id)fp8;
- (unsigned long)flagsForMessage:(id)fp8;
- (BOOL)hasCachedDataForMimePart:(id)fp8;
- (id)_fetchHeaderDataForMessage:(id)fp8;
- (id)_fetchBodyDataForMessage:(id)fp8 andHeaderDataIfReadilyAvailable:(id *)fp12;
- (id)fullBodyDataForMessage:(id)fp8 andHeaderDataIfReadilyAvailable:(id *)fp12;
- (BOOL)_shouldChangeComponentMessageFlags;
- (id)setFlagsFromDictionary:(id)fp8 forMessages:(id)fp12;
- (unsigned int)indexOfMessage:(id)fp8;
- (void)deleteMessages:(id)fp8 moveToTrash:(BOOL)fp12;
- (void)deleteMessagesOlderThanNumberOfDays:(int)fp8 compact:(BOOL)fp12;
- (BOOL)allowsAppend;
- (int)appendMessages:(id)fp8 unsuccessfulOnes:(id)fp12 newMessageIDs:(id)fp16 newMessages:(id)fp20;
- (int)undoAppendOfMessageIDs:(id)fp8;
- (BOOL)canCompact;
- (BOOL)_shouldCallCompactWhenClosing;
- (void)doCompact;
- (void)deleteLastMessageWithHeader:(id)fp8 forHeaderKey:(id)fp12 compactWhenDone:(BOOL)fp16;
- (id)dataForMimePart:(id)fp8;
- (void)writeUpdatedMessageDataToDisk;
- (void)updateMetadata;
- (void)updateUserInfoToLatestValues;
- (void)_setNeedsAutosave;
- (id)criterion;
- (id)url;
- (unsigned int)unreadCount;
- (void)_flushAllMessageData;
- (void)rebuildTableOfContentsAsynchronously;
- (void)_rebuildTableOfContentsSynchronously;
- (void)_flushAllCaches;
- (id)_cachedBodyForMessage:(id)fp8 valueIfNotPresent:(id)fp12;
- (id)_cachedHeadersForMessage:(id)fp8 valueIfNotPresent:(id)fp12;
- (id)_cachedBodyDataForMessage:(id)fp8 valueIfNotPresent:(id)fp12;
- (id)_cachedHeaderDataForMessage:(id)fp8 valueIfNotPresent:(id)fp12;
- (void)_setBackgroundColorForMessages:(id)fp8 textColorForMessages:(id)fp12;
- (void)_invalidateColorForMessages:(id)fp8;
- (void)_setFlagsForMessages:(id)fp8 mask:(unsigned long)fp12;
- (void)_setFlagsAndColorForMessages:(id)fp8;
- (BOOL)setPreferredEncoding:(unsigned long)fp8 forMessage:(id)fp12;

@end

//
//  GrowlMailMeAction.m
//  MailMe
//
//  Created by Daniel Siemer on 4/12/12.
//
//  This class is where the main logic of dispatching a notification via your plugin goes.
//  There will be only one instance of this class, so use the configuration dictionary for figuring out settings.
//  Be aware that action plugins will be dispatched on the default priority background concurrent queue.
//  

#import "GrowlMailMeAction.h"
#import "GrowlMailMePreferencePane.h"
#import "SMTPClient.h"
#import <GrowlPlugins/GrowlDefines.h>
#import <GrowlPlugins/GrowlKeychainUtilities.h>

@implementation GrowlMailMeAction

/* Dispatch a notification with a configuration, called on the default priority background concurrent queue
 * Unless you need to use UI, do not send something to the main thread/queue.
 * If you have a requirement to be serialized, make a custom serial queue for your own use. 
 */
-(void)dispatchNotification:(NSDictionary *)note withConfiguration:(NSDictionary *)configuration {
	NSString *subject = [configuration valueForKey:SMTPSubjectKey];
	subject = [subject length] ? subject : @"Growl";
	subject = [NSString stringWithFormat:@"[%@] %@: %@", subject, [note valueForKey:GROWL_APP_NAME], [note valueForKey:GROWL_NOTIFICATION_TITLE]];
	
	NSString *message = [[note valueForKey:GROWL_NOTIFICATION_DESCRIPTION] stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>\n"];
	
	NSString *serverAddress = [configuration valueForKey:SMTPServerAddressKey];
	NSString *serverPorts = [configuration valueForKey:SMTPServerPortsKey];
	NSString *serverAuthUsername = [configuration valueForKey:SMTPServerAuthUsernameKey];
	NSString *serverAuthPassword = [GrowlKeychainUtilities passwordForServiceName:@"Growl-MailMe" 
																							accountName:[configuration valueForKey:GROWL_PLUGIN_CONFIG_ID]];
	NSString *messageFrom = [configuration valueForKey:SMTPFromKey];
	NSString *messageTo = [configuration valueForKey:SMTPToKey];
	
	if (!serverPorts.length) serverPorts = @"";
	if(!serverAddress || serverAddress.length == 0 ||
		!messageFrom || messageFrom.length == 0 ||
		!messageTo || messageTo.length == 0) {
		NSLog(@"Unable to send mailme action, not enough information");
		return;
	}
	
	BOOL authFlag = NO;
	if([configuration valueForKey:SMTPServerAuthFlagKey])
		authFlag = [[configuration valueForKey:SMTPServerAuthFlagKey] boolValue];
	
	
	if (authFlag) {
		if(!serverAuthUsername || serverAuthUsername.length == 0 ||
			!serverAuthPassword || serverAuthPassword.length == 0){
			NSLog(@"Unable to send mailme action, selected authentication and no authentication set");
			return;
		}
	} else {
		serverAuthUsername = @"";
		serverAuthPassword = @"";
	}
	
	NSInteger tlsMode = SMTPClientTLSModeTLSIfPossible;
	if([configuration valueForKey:SMTPServerTLSModeKey])
		tlsMode = [[configuration valueForKey:SMTPServerTLSModeKey] integerValue];
	NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys: 
									serverAddress, SMTPServerAddressKey,
									serverPorts, SMTPServerPortsKey,
									[NSNumber numberWithInteger:tlsMode], SMTPServerTLSModeKey,
									[NSNumber numberWithBool:authFlag], SMTPServerAuthFlagKey,
									serverAuthUsername, SMTPServerAuthUsernameKey,
									serverAuthPassword, SMTPServerAuthPasswordKey,
									messageFrom, SMTPFromKey,
									messageTo, SMTPToKey,
									subject, SMTPSubjectKey,
									message, SMTPMessageKey,
									NULL];
	[SMTPClient send:params];
}

/* Auto generated method returning our PreferencePane, do not touch */
- (GrowlPluginPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlMailMePreferencePane alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.growl.MailMe"]];
	
	return preferencePane;
}

@end

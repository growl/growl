//
//  NSFileManager+Authentication.m
//  Growl
//
//  Based on code from Sparkle, which is distributed under the Modified BSD license.
//
//  Created by Andy Matuschak on 3/9/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//
//  This code based on generous contribution from Allan Odgaard. Thanks, Allan!

#import "sys/stat.h"
#import <Security/Security.h>

#import <unistd.h>
#import <sys/stat.h>
#import <dirent.h>

@implementation NSFileManager (SUAuthenticationAdditions)

- (BOOL)_deletePathWithForcedAuthentication:(NSString *)path
{
	BOOL res = NO;
	struct stat sb;
	if(stat([path UTF8String], &sb) != 0)
		return FALSE;

	char* buf = NULL;
	asprintf(&buf,
			 "rm -rf \"$TARGET_PATH\"",
			 sb.st_uid, sb.st_gid);

	if(!buf)
		return false;
	
	AuthorizationRef auth;
	if(AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth) == errAuthorizationSuccess)
	{
		setenv("TARGET_PATH", [path UTF8String], 1);

		sig_t oldSigChildHandler = signal(SIGCHLD, SIG_DFL);
		char const* arguments[] = { "-c", buf, NULL };
		if(AuthorizationExecuteWithPrivileges(auth, "/bin/sh", kAuthorizationFlagDefaults, (char**)arguments, NULL) == errAuthorizationSuccess)
		{
			int status;
			int pid = wait(&status);
			if(pid != -1 && WIFEXITED(status) && WEXITSTATUS(status) == 0)
				res = YES;
		}
		signal(SIGCHLD, oldSigChildHandler);
	}
	AuthorizationFree(auth, 0);
	free(buf);

	return res;
}

- (BOOL)deletePathWithAuthentication:(NSString *)path
{
	if ([self isWritableFileAtPath:path] && [self isWritableFileAtPath:[path stringByDeletingLastPathComponent]]) {
		return [self removeFileAtPath:path handler:nil];
	} else
		return [self _deletePathWithForcedAuthentication:path];
}

@end

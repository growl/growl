//
//  GrowlSafariHelper.m
//  GrowlSafari
//
//  Created by Rudy Richter on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "GrowlSafariHelper.h"
#include <mach_inject_bundle/mach_inject_bundle.h>
#include <mach/mach_error.h>
#include <dlfcn.h>

#define SAFARI_BUNDLE_ID @"com.apple.Safari"

void inject(pid_t pid);

int main(int argc, char **argv) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if(argc == 2)
	{
		BOOL valid = NO;
		NSString *PIDNum = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
		pid_t pid = [PIDNum intValue];
		NSLog(@"pid: %ld\n path: %s\n", pid, [[[[NSBundle mainBundle] privateFrameworksPath] stringByAppendingPathComponent:@"mach_inject_bundle.framework"] fileSystemRepresentation]);

		NSDictionary *process = nil;
		for(process in [[NSWorkspace sharedWorkspace] launchedApplications])
		{	
			NSString *bundleID = [process objectForKey:@"NSApplicationBundleIdentifier"];
			if (bundleID && [bundleID caseInsensitiveCompare:SAFARI_BUNDLE_ID] == NSOrderedSame) 
			{
				if([[process objectForKey:@"NSApplicationProcessIdentifier"] integerValue] == pid)
				{
					valid = YES;
					break;
				}
			}
		}
		
		if(valid)
		{
			//NSBundle is forbidden! the system will kill us if we try to load our framework using -[NSBundle bundleWithPath:]
			void *result = dlopen([[[[[NSBundle mainBundle] privateFrameworksPath] stringByAppendingPathComponent:@"mach_inject_bundle.framework"] stringByAppendingPathComponent:@"mach_inject_bundle"] fileSystemRepresentation], RTLD_LAZY);
			NSLog(@"framework load result: %p\n", result);
			
			//NSLog(@"mach_inject_bundle.framework: %@", [NSBundle bundleWithPath:]);
			//NSLog(@"com.rentzsch.mach_inject_bundle: %@", [NSBundle bundleWithIdentifier:@"com.rentzsch.mach_inject_bundle"]);
			//[NSBundle bundleWithPath:[[[NSBundle mainBundle] privateFrameworksPath] stringByAppendingPathComponent:@"mach_inject_bundle.framework"]];
			//NSLog(@"framework (CF): %@", CFBundleGetBundleWithIdentifier(CFSTR("com.rentzsch.mach_inject_bundle")));
			
			inject(pid);
		}
	}
	[pool drain];
	return 0;
}

void inject(pid_t pid)
{
		
	NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"GrowlSafari" ofType:@"bundle"];
	if (bundlePath) {
	mach_error_t err = mach_inject_bundle_pid([bundlePath fileSystemRepresentation], pid);
	if (err != ERR_SUCCESS)
		NSLog(@"Error while injecting into process %i: %s (system 0x%x, subsystem 0x%x, code 0x%x)", pid, mach_error_string(err), err_get_system(err), err_get_sub(err), err_get_code(err));
	}
}
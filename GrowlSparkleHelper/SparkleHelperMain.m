//
//  SparkleHelperMain.m
//  Growl
//
//  Created by Rudy Richter on 9/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "GrowlSparkleHelper.h"

int main(int argc, const char *argv[]) {
	int status = -1;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@try {
		  GrowlSparkleHelper *helper = [[GrowlSparkleHelper alloc] init];
		[NSApp setDelegate:helper];
		status =  NSApplicationMain(argc,argv);
	}
		  @catch (NSException *exception) {
			  NSLog(@"%@", exp);
		  }
		  [pool drain];
	return status;
}

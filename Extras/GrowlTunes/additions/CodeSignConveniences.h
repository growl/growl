//
//  CodeSignConveniences.h
//
//  Created by Travis Tilley on 2/4/12.
//  Copyright (c) 2012 Travis Tilley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/CodeSigning.h>

#define NSFoundationVersionNumber10_7   833.1
#define NSFoundationVersionNumber10_7_1 833.1 // Foundation wasn't updated in 10.7.1
#define NSFoundationVersionNumber10_7_2 833.20
#define NSFoundationVersionNumber10_7_3 833.24

static inline BOOL isLionOrGreater(void) {
    return (BOOL)(isgreaterequal(NSFoundationVersionNumber, NSFoundationVersionNumber10_7));
}

static inline BOOL hasEntitlement(CFStringRef entitlement) {
    CFErrorRef errors = NULL;
    SecCodeRef code = NULL;
    SecRequirementRef requirement = NULL;
    OSStatus status = errSecSuccess;
    
    status = SecCodeCopySelf(kSecCSDefaultFlags, &code);
    if (status != errSecSuccess) {
        NSLog(@"SecCodeCopySelf failed with status code: %ld", (long)status);
        return NO;
    }
    
#if !defined(NDEBUG)
    NSLog(@"Checking for entitlement: %@", (__bridge NSString*)entitlement);
#endif
    
    CFStringRef format = CFSTR("entitlement[\"%@\"] exists");
    CFStringRef requirementString = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, format, entitlement);
    status = SecRequirementCreateWithStringAndErrors(requirementString, kSecCSDefaultFlags, &errors, &requirement);
    CFRelease(requirementString);
    if (status != errSecSuccess) {
        CFDictionaryRef errDict = CFErrorCopyUserInfo(errors);
        NSLog(@"SecRequirementCreateWithStringAndErrors failure: %@", (NSDictionary*)CFBridgingRelease(errDict));
        CFRelease(errors), errors = NULL;
        return NO;
    }
    
    status = SecCodeCheckValidity(code, kSecCSDefaultFlags, requirement);
    if (status == errSecSuccess) {
#if !defined(NDEBUG)
        NSLog(@"Entitlement present: %@", (__bridge NSString*)entitlement);
#endif
        return YES;
    } else {
#if !defined(NDEBUG)
        NSLog(@"Entitlement NOT present: %@", (__bridge NSString*)entitlement);
#endif
        return NO;
    }    
}

static inline BOOL hasSandboxEntitlement(void) {
    return hasEntitlement(CFSTR("com.apple.security.app-sandbox"));
}

static inline BOOL hasNetworkClientEntitlement(void) {
    return hasEntitlement(CFSTR("com.apple.security.network.client"));
}

static inline BOOL hasNetworkServerEntitlement(void) {
    return hasEntitlement(CFSTR("com.apple.security.network.server"));
}

static inline BOOL isSandboxed(void) {
    return (isLionOrGreater() && hasSandboxEntitlement());
}

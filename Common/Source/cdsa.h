/*
 *  cdsa.h
 *  Growl
 *
 *  Created by Ingmar Stein on 05.05.05.
 *  Copyright 2005 The Growl Project. All rights reserved.
 */

#import <Security/Security.h>

extern CSSM_CSP_HANDLE cspHandle;

CSSM_RETURN cdsaInit(void);
void cdsaShutdown(void);

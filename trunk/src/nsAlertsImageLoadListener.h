//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#ifndef __nsAlertsImageLoadListener_H__
#define __nsAlertsImageLoadListener_H__

#include "xpcom-config.h"

#include "nsIStreamLoader.h"
#include "nsStringAPI.h"

class nsAlertsImageLoadListener : public nsIStreamLoaderObserver
{
public:
  nsAlertsImageLoadListener(const nsAString &aName,
                            const nsAString &aAlertTitle,
                            const nsAString &aAlertText,
                            PRBool aAlertClickable,
                            const nsAString &aAlertCookie,
                            PRUint32 aAlertListenerKey);

  NS_DECL_ISUPPORTS
  NS_DECL_NSISTREAMLOADEROBSERVER
private:
  nsString mName;
  nsString mAlertTitle;
  nsString mAlertText;
  PRBool   mAlertClickable;
  nsString mAlertCookie;
  PRUint32 mAlertListenerKey;
};

#endif // __nsAlertsImageLoadListener_H__

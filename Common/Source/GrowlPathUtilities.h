//
//  GrowlPathUtilities.h
//  Growl
//
//  Created by Ingmar Stein on 17.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

/*we can't typedef the enum, because then NSSearchPathDirectory constants
 *	cannot be used in GrowlSearchPathDirectory arguments/variables without a
 *	compiler warning (because NSSearchPathDirectory and GrowlSearchPathDirectory
 *	would then be different types).
 */
typedef int GrowlSearchPathDirectory;
enum {
	//Library/Application\ Support/Growl
	GrowlSupportDirectory = 0x10000,
	//all other directory constants refer to subdirectories of Growl Support.
	GrowlTicketsDirectory,
	GrowlPluginsDirectory,
};
typedef NSSearchPathDomainMask GrowlSearchPathDomainMask; //consistency

@interface GrowlPathUtilities : NSObject {

}

#pragma mark Bundles

/*!	@method	runningHelperAppBundle
 *	@abstract	Returns the bundle for the running GrowlHelperApp process.
 *	@discussion	If GrowlHelperApp is running, returns an NSBundle for the .app 
 *	 bundle it was loaded from.
 *	If GrowlHelperApp is not running, returns <code>nil</code>.
 *	@result	The <code>NSBundle</code> for GrowlHelperApp if it is running;
 *	 <code>nil</code> otherwise.
 */
+ (NSBundle *) runningHelperAppBundle;

#pragma mark Directories

/*!	@method	searchPathForDirectory:inDomains:mustBeWritable:
 *	@abstract	Returns an array of absolute paths to a given directory.
 *	@discussion	This method returns an array of all the directories of a given
 *	 type that exist (and, if <code>flag</code> is <code>YES</code>, are
 *	 writable). If no directories match this criteria, a valid (but empty)
 *	 array is returned.
 *
 *	 Unlike the <code>NSSearchPathForDirectoriesInDomains</code> function in
 *	 Foundation, this method does not allow you to specify whether tildes are
 *	 expanded: they will always be expanded.
 *	@result	An array of zero or more absolute paths.
 */
+ (NSArray *) searchPathForDirectory:(GrowlSearchPathDirectory) directory inDomains:(GrowlSearchPathDomainMask) domainMask mustBeWritable:(BOOL)flag;
/*!	@method	searchPathForDirectory:inDomains:
 *	@abstract	Returns an array of absolute paths to a given directory.
 *	@discussion	This method returns an array of all the directories of a given
 *	 type that exist. They need not be writable.
 *
 *	 Unlike the <code>NSSearchPathForDirectoriesInDomains</code> function in
 *	 Foundation, this method does not allow you to specify whether tildes are
 *	 expanded: they will always be expanded.
 *	@result	An array of zero or more absolute paths.
 */
+ (NSArray *) searchPathForDirectory:(GrowlSearchPathDirectory) directory inDomains:(GrowlSearchPathDomainMask) domainMask;

/*! @method	growlSupportDirectory
 *	@abstract	Returns the path for Growl's folder inside Application Support.
 *	@discussion	This method creates the folder if it does not already exist.
 *	@result	The path to Growl's support directory.
 */
+ (NSString *) growlSupportDirectory;

/*!	@method	ticketsDirectory
 *	@abstract	Returns the directory where tickets are to be saved.
 *	@discussion	The default location of this directory is
 *	 $HOME/Library/Application\ Support/Growl/Tickets. This method creates
 *	 the folder if it does not already exist.
 *	@result	The absolute path to the ticket directory.
 */
+ (NSString *) ticketsDirectory;

#pragma mark Tickets

/*!	@method	defaultSavePathForTicketWithApplicationName:
 *	@abstract	Returns an absolute path that can be used for saving a ticket.
 *	@discussion	When called with an application name, ".ticket" is appended to
 *	 it, and the result is appended to the absolute path to the ticket
 *	 directory. When called with <code>nil</code>, the ticket directory itself
 *	 is returned.
 *
 *	 For the purpose of this method, 'the ticket directory' refers to the first
 *	 writable directory returned by
 *	 <code>+searchPathForDirectory:inDomains:</code>. If there is no writable
 *	 directory, this method returns <code>nil</code>.
 *	@param	The application name for the ticket, or <code>nil</code>.
 *	@result	The absolute path to a ticket file, or the ticket directory where a
 *	 ticket file can be saved.
 */
+ (NSString *) defaultSavePathForTicketWithApplicationName:(NSString *) appName;

@end

//
//  GRDEImporter.h
//  Growl Registration Dictionary Editor
//
//  Created by Peter Hosey on 2007-10-01.
//  Copyright 2007 Peter Hosey. All rights reserved.
//

@interface GRDEImporter : NSObject {
	NSArray *ticketPaths;
	NSIndexSet *selectedTicketIndices;
	IBOutlet NSPanel *importPanel;
	IBOutlet NSTableView *ticketsTableView; //There being no way to hook up a double-click action in IB 2…
}

#pragma mark Accessors

- (NSArray *) ticketPaths;
- (unsigned) countOfTicketPaths;
- (NSString *) objectInTicketPathsAtIndex:(unsigned)idx;

//Dependent on ticketPaths.
- (NSArray *) ticketApplicationNames;
- (unsigned) countOfTicketApplicationNames;
- (NSObject *) objectInTicketApplicationNamesAtIndex:(unsigned)idx;

- (NSIndexSet *) selectedTicketIndices;

#pragma mark Actions

- (IBAction) orderFrontImportPanel:(id)sender;
- (IBAction) importSelectedTickets:(id)sender;

@end

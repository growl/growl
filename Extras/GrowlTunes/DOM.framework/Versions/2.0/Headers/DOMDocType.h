/*
 * Iconara DOM framework: DOMDocType (created 12 December 2002)
 *
 * Release 1
 *
 * Copyright 2002-2003 Iconara/Theo Hultberg
 *
 *
 * This file is part of the Iconara DOM framework.
 *
 * Iconara DOM is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Iconara DOM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Iconara DOM; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

/*
 * TODO:
 * - DOM compliance: entities, notations
 */

#import <Foundation/Foundation.h>
#import "DOMNode.h"


/*!
 * Represents a doctype declaration (<!DOCTYPE ..>) in a XML-document.
 */
@protocol DOMDocType <DOMNode>

- (NSString *)name;

- (void)setName:(NSString *)name;

- (NSString *)publicId;

- (void)setPublicId:(NSString *)publicId;

- (NSString *)systemId;

- (void)setSystemId:(NSString *)systemId;

- (NSString *)internalSubset;

@end


@interface DOMDocType : DOMNode <DOMDocType> {
	NSString *name;
	NSString *publicId;
	NSString *systemId;
	NSString *internalSubset;
}

+ (id <DOMDocType>)docTypeWithName:(NSString *)name;

+ (id <DOMDocType>)docTypeWithName:(NSString *)name systemId:(NSString *)systemId;

+ (id <DOMDocType>)docTypeWithName:(NSString *)name systemId:(NSString *)systemId publicId:(NSString *)publicId;

- (id)initWithName:(NSString *)name;

- (id)initWithName:(NSString *)name 
          systemId:(NSString *)systemId;

- (id)initWithName:(NSString *)name 
          systemId:(NSString *)systemId 
          publicId:(NSString *)publicId;

@end

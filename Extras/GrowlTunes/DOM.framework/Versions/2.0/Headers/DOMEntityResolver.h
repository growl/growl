/*
 * Iconara DOM framework: DOMEntityResolver (created 8 May 2003)
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

#import <Foundation/Foundation.h>
#import "DOMPreprocessor.h"
	   
/*!
 * Resolves external entity references.
 *
 * Finds the internal subset of the document type declaration, if there is 
 * any, and parses external entity declarations. Then substitutes entity 
 * references for the contents at the URL of the entity.
 *
 * Known problems:
 *   - assumes UTF8 string encoding
 *   - assumes XML-data as the value of each external reference
 *   - only looks in the internal subset (really not a problem since there
 *     shouldn't be any DTD declarations in the XML-document besides the
 *     internal subset)
 *   - doesn't look in the DTD referenced by the doctype declaration
 *   - should have been named ExternalEntityResolver
 *
 */
@interface DOMEntityResolver : DOMPreprocessor { }

@end

/*
 *  Copyright (C) 2016-2019 Savoir-faire Linux Inc.
 *  Author: Alexandre Lision <alexandre.lision@savoirfairelinux.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
 */


#import "AbstractLoadingWC.h"
#import "LoadingWCDelegate.h"
#import "LrcModelsProtocol.h"
#include <qstring.h>


@protocol RegisterNameDelegate <LoadingWCDelegate>

@optional

- (void) didRegisterName:(NSString *) name withSuccess:(BOOL) success;

@end

@interface RegisterNameWC : AbstractLoadingWC <LrcModelsProtocol>

@property (nonatomic, weak) NSViewController <RegisterNameDelegate>* delegate;

/**
 * KVO validators for the UI
 */
@property (assign)BOOL isUserNameAvailable;

@property (assign)BOOL couldRegister;

@property (assign)NSString* passwordString;

@property QString selectedAccountID;

@end

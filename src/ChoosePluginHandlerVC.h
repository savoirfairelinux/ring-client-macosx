/*
 *  Copyright (C) 2015-2017 Savoir-faire Linux Inc.
 *  Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
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

#import <Cocoa/Cocoa.h>
#include <qstring.h>

typedef enum {
    FROM_CALL = 1,
    FROM_CHAT
} PluginPickerType;

namespace lrc {
    namespace api {
        class PluginModel;
    }
}

@protocol ChoosePluginHandlerDelegate <NSObject>
@end

@interface ChoosePluginHandlerVC : NSViewController

@property (retain, nonatomic) id <ChoosePluginHandlerDelegate> delegate;

@property (nonatomic) lrc::api::PluginModel* pluginModel;

-(void) setupForCall:(const QString)callID;
-(void) setupForChat:(const QString)convID accountID:(const QString)accountID;

@end

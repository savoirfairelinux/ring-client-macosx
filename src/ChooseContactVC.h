/*
 *  Copyright (C) 2019 Savoir-faire Linux Inc.
 *  Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>
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
    FROM_CONTACT = 1,
    FROM_CONFERENCABLE_ITEM
} ContactPickerType;

@protocol ChooseContactVCDelegate <NSObject>
-(void)callToContact:(const QString&)contactUri convUID:(const QString&)convID;
-(void)joinCall:(const QString&)callId;
-(void)contactChosen:(const QString&)contactUri;
@end

namespace lrc {
    namespace api {
        class ConversationModel;
        namespace conversation {
            struct Info;
        }
        class ContactModel;
        class NewAccountModel;
    }
}

@interface ChooseContactVC: NSViewController
@property (retain, nonatomic) id <ChooseContactVCDelegate> delegate;

- (void)setUpForConference:(lrc::api::ConversationModel *)conversationModel
      andCurrentConversation:(const QString&)conversation;
- (void)setUpCpntactPickerwithModel:(lrc::api::NewAccountModel *) newaccountModel andAccountId:(const QString&)account;

@end

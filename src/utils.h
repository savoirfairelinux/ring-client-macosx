/*
 *  Copyright (C) 2017-2019 Savoir-faire Linux Inc.
 *  Author: Anthony Léonard <anthony.leonard@savoirfairelinux.com>
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

#import <map>

#import <Foundation/Foundation.h>
#import "NSString+Extensions.h"
#import "views/NSColor+RingTheme.h"


// new lrc
#import <api/conversation.h>
#import <api/conversationmodel.h>
#import <api/account.h>
#import <api/contactmodel.h>
#import <api/contact.h>

//Qt
#import <QtCore/QDir>
#import <qapplication.h>

static inline NSString* bestIDForConversation(const lrc::api::conversation::Info& conv, lrc::api::ConversationModel& model)
{
    try {
        auto contact = model.owner.contactModel->getContact(model.peersForConversation(conv.uid)[0]);
        auto name = contact.registeredName.trimmed().replace("\r","").replace("\n","");
        if (!name.isEmpty()) {
            return [name.toNSString() removeEmptyLinesAtBorders];
        }
        else {
            return [contact.profileInfo.uri.trimmed().replace("\r","").replace("\n","").toNSString() removeEmptyLinesAtBorders];
        }
    } catch (std::out_of_range& e) {
        NSLog(@"bestIDForConversation: getContact - out of range");
        return @"";
    }
}

static inline NSString* bestIDForAccount(const lrc::api::account::Info& account)
{
    auto name = account.registeredName.trimmed().replace("\r","").replace("\n","");
    if (!name.isEmpty()) {
        return [name.toNSString() removeEmptyLinesAtBorders];
    }
    return [account.profileInfo.uri.trimmed().replace("\r","").replace("\n","").toNSString() removeEmptyLinesAtBorders];
}

static inline NSString* bestNameForAccount(const lrc::api::account::Info& account)
{
    if (account.profileInfo.alias.isEmpty()) {
        return bestIDForAccount(account);
    }
    return account.profileInfo.alias.toNSString();
}

static inline NSString* bestIDForContact(const lrc::api::contact::Info& contact)
{
    auto name = contact.registeredName.trimmed().replace("\r","").replace("\n","");
    if (!name.isEmpty()) {
        return [name.toNSString() removeEmptyLinesAtBorders];
    }
    return [contact.profileInfo.uri.trimmed().replace("\r","").replace("\n","").toNSString() removeEmptyLinesAtBorders];
}

static inline NSString* bestNameForContact(const lrc::api::contact::Info& contact)
{
    if (contact.profileInfo.alias.isEmpty()) {
        return bestIDForContact(contact);
    }
    return contact.profileInfo.alias.toNSString();
}

static inline NSString* bestNameForConversation(const lrc::api::conversation::Info& conv, lrc::api::ConversationModel& model)
{
    try {
        auto contact = model.owner.contactModel->getContact(model.peersForConversation(conv.uid)[0]);
        if (contact.profileInfo.alias.isEmpty()) {
            return bestIDForConversation(conv, model);
        }
        auto alias = contact.profileInfo.alias;
        if(alias.length() == 0) {
            return bestIDForConversation(conv, model);
        }
        return [alias.toNSString() removeEmptyLinesAtBorders];
    } catch (std::out_of_range& e) {
        NSLog(@"bestNameForConversation: getContact - out of range");
        return @"";
    }
}

static inline NSString* defaultRingtonePath() {
    QDir ringtonesDir(QCoreApplication::applicationDirPath());
    ringtonesDir.cdUp();
    ringtonesDir.cd("Resources/ringtones/");
    return [ringtonesDir.path().toNSString() stringByAppendingString:@"/default.opus"];
}

static inline lrc::api::profile::Type profileType(const lrc::api::conversation::Info& conv,  lrc::api::ConversationModel& model)
{
    try {
        auto& peers = model.peersForConversation(conv.uid);
        const auto contact = model.owner.contactModel->getContact(peers[0]);
        return contact.profileInfo.type;
    } catch (std::out_of_range& e) {
        lrc::api::profile::Type::INVALID;
    }
}

/**
 * This function return an optional reference to Conversation::Info in ConversationModel given its uid.
 * @param uid UID of conversation being searched
 * @param model ConversationModel in which to do the lookup
 * @return an optional reference to Conversation::Info.
 */
static inline OptRef<lrc::api::conversation::Info> getConversationFromUid(const QString& uid, lrc::api::ConversationModel& model) {
    return model.getConversationForUid(uid);
}
/**
 * This function  return an optional reference to Conversation::Info in ConversationModel given its participant uri.
 * @param uri URI of participant
 * @param model ConversationModel in which to do the lookup
 * @return an optional reference to conversation::Info.
 */
static inline OptRef<lrc::api::conversation::Info> getConversationFromURI(const QString& uri, lrc::api::ConversationModel& model) {
    return model.getConversationForPeerUri(uri);
}
/**
 * This function  return an optional reference to Conversation::Info in ConversationModel given its call Id
 * @param callId callId for conversation
 * @param model ConversationModel in which to do the lookup
 * @return an optional reference to conversation::Info.
 */
static inline OptRef<lrc::api::conversation::Info> getConversationFromCallId(const QString& callId, lrc::api::ConversationModel& model) {
    return model.getConversationForCallId(callId);
}
/**
  * This function return an index of filtered conversation for given conversation uid. If no result found return -1
  * @param uid UID of conversation being searched
  * @param model ConversationModel in which to do the lookup
  * @return an index of corresponding Conversation if any. Otherwise return -1.
  */
static inline int getFilteredConversationIndexFromUid(const QString& uid, const lrc::api::ConversationModel& model) {
    auto it = std::find_if(model.allFilteredConversations().get().begin(), model.allFilteredConversations().get().end(),
                       [&] (const lrc::api::conversation::Info& conv) {
        return uid == conv.uid;
    });
    if (it != model.allFilteredConversations().get().end()) {
        return std::distance(model.allFilteredConversations().get().begin(), it);
    }
    return -1;
}
/**
* This function return an index of search result for given conversation uid. If no result found return -1
* @param uid UID of conversation being searched
* @param model ConversationModel in which to do the lookup
* @return an index of corresponding Conversation if any. Otherwise return -1.
*/
static inline int getSearchResultIndexFromUid(const QString& uid, const lrc::api::ConversationModel& model) {
    auto it = std::find_if(model.getAllSearchResults().begin(), model.getAllSearchResults().end(),
                        [&] (const lrc::api::conversation::Info& conv) {
        return uid == conv.uid;
    });
    if (it != model.getAllSearchResults().end()) {
        return std::distance(model.getAllSearchResults().begin(), it);
    }
    return -1;
}
static inline bool isUrlAccessibleFromSandbox(NSURL* url)
{
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSArray* urlPathsMusic = [fileManager URLsForDirectory:NSMusicDirectory
                                                 inDomains:NSUserDomainMask];
    NSArray* urlPathsPictures = [fileManager URLsForDirectory:NSPicturesDirectory
                                                    inDomains:NSUserDomainMask];
    NSArray* urlPathsDownloads = [fileManager URLsForDirectory:NSDownloadsDirectory
                                                     inDomains:NSUserDomainMask];
    NSArray* urlPathsMovies = [fileManager URLsForDirectory:NSMoviesDirectory
                                                  inDomains:NSUserDomainMask];
    NSArray* availablePaths = [[[urlPathsMusic arrayByAddingObjectsFromArray: urlPathsPictures] arrayByAddingObjectsFromArray: urlPathsDownloads] arrayByAddingObjectsFromArray: urlPathsMovies];
    if([availablePaths containsObject:url]) {
        return YES;
    }
    for (NSURL* availableUrl in availablePaths) {
        if ([url.path containsString:availableUrl.path]) {
            return YES;
        }
    }
    return NO;
}

static inline bool appSandboxed()
{
    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString* url = [[NSURL fileURLWithPath:NSHomeDirectory()] path];
    NSString* appPath = [@"Library/Containers/" stringByAppendingString:bundleID];
    if ([url containsString: appPath]) {
        return YES;
    }
    return NO;
}

static inline NSColor* colorForAccountStatus(const lrc::api::account::Status status)
{
    NSColor *accountStatusColor = [NSColor unregisteredColor];
    switch (status) {
        case  lrc::api::account::Status::REGISTERED:
            accountStatusColor = [NSColor presenceColor];
            break;
        case  lrc::api::account::Status::TRYING:
            accountStatusColor = [NSColor orangeColor];
            break;
        default:
            break;
    }
    return accountStatusColor;
}

/*
 *  Copyright (C) 2015-2019 Savoir-faire Linux Inc.
 *  Author: Alexandre Lision <alexandre.lision@savoirfairelinux.com>
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
#import "AccAdvancedVC.h"

//LRC
#import <api/lrc.h>
#import <api/newaccountmodel.h>
#import <api/newdevicemodel.h>
#import <api/newcodecmodel.h>
#import <api/account.h>

@interface AccAdvancedVC ()

@property (unsafe_unretained) IBOutlet NSButton* ringtoneSelectionButton;
@property (unsafe_unretained) IBOutlet NSButton* enableRingtone;
@property (unsafe_unretained) IBOutlet NSButton* toggleAccountDiscoveryButton;
@property (unsafe_unretained) IBOutlet NSButton* togglePeersDiscoveryButton;
@property (unsafe_unretained) IBOutlet NSButton* autoAnswer;
@property (unsafe_unretained) IBOutlet NSButton* toggleUPnPButton;
@property (unsafe_unretained) IBOutlet NSButton* useTURNButton;
@property (unsafe_unretained) IBOutlet NSButton* useSTUNButton;
@property (unsafe_unretained) IBOutlet NSButton *toggleVideoButton;
@property (unsafe_unretained) IBOutlet NSTableView* audioCodecView;
@property (unsafe_unretained) IBOutlet NSTableView* videoCodecView;
@property (unsafe_unretained) IBOutlet NSTextField *turnAddressField;
@property (unsafe_unretained) IBOutlet NSTextField *turnUsernameField;
@property (unsafe_unretained) IBOutlet NSSecureTextField *turnPasswordField;
@property (unsafe_unretained) IBOutlet NSTextField *turnRealmField;
@property (unsafe_unretained) IBOutlet NSTextField *stunAddressField;
@property (unsafe_unretained) IBOutlet NSButton *disableVideoButton;

@end

@implementation AccAdvancedVC

@synthesize audioCodecView, videoCodecView;
@synthesize privateKeyPaswordField, turnAddressField, turnUsernameField, turnPasswordField, turnRealmField, stunAddressField;
@synthesize ringtoneSelectionButton, selectCACertificateButton, selectUserCertificateButton, selectPrivateKeyButton, toggleAccountDiscoveryButton, togglePeersDiscoveryButton;
@synthesize enableRingtone, toggleVideoButton, autoAnswer, toggleUPnPButton, useTURNButton, useSTUNButton, disableVideoButton;
@synthesize accountModel;

NS_ENUM(NSInteger, ButtonsTags) {
    TAG_RINGTONE = 1,
    TAG_CA_CERTIFICATE,
    TAG_USER_CERTIFICATE,
    TAG_PRIVATE_KEY
};

NS_ENUM(NSInteger, TextFieldsViews) {
    PRIVATE_KEY_PASSWORG_TAG = 1,
    TURN_ADDRESS_TAG,
    TURN_USERNAME_TAG,
    TURN_PASSWORD_TAG,
    TURN_REALM_TAG,
    STUN_ADDRESS_TAG
};

NS_ENUM(NSInteger, tablesViews) {
    AUDIO_CODEC_NAME_TAG = 1,
    AUDIO_CODEC_SAMPLERATE_TAG,
    AUDIO_CODEC_ENABLE_TAG,
    VIDEO_CODEC_NAME_TAG,
    VIDIO_CODEC_ENABLE_TAG
};

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil accountmodel:(lrc::api::NewAccountModel*) accountModel
{
    if (self =  [self initWithNibName: nibNameOrNil bundle:nibBundleOrNil])
    {
        self.accountModel= accountModel;
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    audioCodecView.delegate = self;
    audioCodecView.dataSource = self;
    videoCodecView.delegate = self;
    videoCodecView.dataSource = self;
    [disableVideoButton setWantsLayer:YES];
    disableVideoButton.layer.backgroundColor = [[NSColor colorWithRed:239/255.0 green:239/255.0 blue:239/255.0 alpha:0.3] CGColor];
    [self setTags];
}

-(void) setTags {
    [ringtoneSelectionButton setTag: TAG_RINGTONE];
    [selectCACertificateButton setTag: TAG_CA_CERTIFICATE];
    [selectUserCertificateButton setTag: TAG_USER_CERTIFICATE];
    [selectPrivateKeyButton setTag: TAG_PRIVATE_KEY];
    [privateKeyPaswordField setTag: PRIVATE_KEY_PASSWORG_TAG];
    [turnAddressField setTag: TURN_ADDRESS_TAG];
    [turnUsernameField setTag: TURN_USERNAME_TAG];
    [turnPasswordField setTag: TURN_PASSWORD_TAG];
    [turnRealmField setTag: TURN_REALM_TAG];
    [stunAddressField setTag: STUN_ADDRESS_TAG];
}

-(void) update {
    lrc::api::account::ConfProperties_t accountProperties = self.accountModel->getAccountConfig(self.selectedAccountID);
    [ringtoneSelectionButton setTitle: [accountProperties.Ringtone.ringtonePath.toNSString() lastPathComponent]];
    [enableRingtone setState :accountProperties.Ringtone.ringtoneEnabled];
    [autoAnswer setState: accountProperties.autoAnswer];
    [selectPrivateKeyButton setTitle: [accountProperties.TLS.privateKeyFile.toNSString() lastPathComponent]];
    [selectUserCertificateButton setTitle:[accountProperties.TLS.certificateFile.toNSString() lastPathComponent]];
    [selectCACertificateButton setTitle: [accountProperties.TLS.certificateListFile.toNSString() lastPathComponent]];
    [toggleUPnPButton setState:accountProperties.upnpEnabled];
    [useTURNButton setState:accountProperties.TURN.enable];
    [useSTUNButton setState:accountProperties.STUN.enable];
    [privateKeyPaswordField setStringValue:accountProperties.TLS.password.toNSString()];
    [turnAddressField setStringValue:accountProperties.TURN.server.toNSString()];
    [turnUsernameField setStringValue:accountProperties.TURN.username.toNSString()];
    [turnPasswordField setStringValue:accountProperties.TURN.password.toNSString()];
    [turnRealmField setStringValue:accountProperties.TURN.realm.toNSString()];
    [stunAddressField setStringValue:accountProperties.STUN.server.toNSString()];
    [stunAddressField setEditable:accountProperties.STUN.enable];
    [turnAddressField setEditable:accountProperties.TURN.enable];
    [turnUsernameField setEditable:accountProperties.TURN.enable];
    [turnPasswordField setEditable:accountProperties.TURN.enable];
    [turnRealmField setEditable:accountProperties.TURN.enable];
    [disableVideoButton setHidden:accountProperties.Video.videoEnabled];
    [toggleVideoButton setState:accountProperties.Video.videoEnabled];
    [videoCodecView setEnabled:accountProperties.Video.videoEnabled];
    [audioCodecView reloadData];
    [videoCodecView reloadData];
    [toggleAccountDiscoveryButton setState:accountProperties.accountPublish];
    [togglePeersDiscoveryButton setState:accountProperties.accountDiscovery];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self update];
}

#pragma mark - AccountAdvancedProtocol methods

- (void) setSelectedAccount:(const QString&) account {
    self.selectedAccountID = account;
    [self update];
}

#pragma mark - Actions

- (IBAction)autoAnswerCall:(id)sender {
    lrc::api::account::ConfProperties_t accountProperties = self.accountModel->getAccountConfig(self.selectedAccountID);
    if( accountProperties.autoAnswer != [sender state]) {
        accountProperties.autoAnswer = [sender state];
        self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
    }
}

- (IBAction)toggleAccountDiscovery:(id)sender {
    lrc::api::account::ConfProperties_t accountProperties = self.accountModel->getAccountConfig(self.selectedAccountID);
    if( accountProperties.accountPublish != [sender state]) {
        accountProperties.accountPublish = [sender state];
        self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
    }
}

- (IBAction)togglePeersDiscovery:(id)sender {
    lrc::api::account::ConfProperties_t accountProperties = self.accountModel->getAccountConfig(self.selectedAccountID);
    if( accountProperties.accountDiscovery != [sender state]) {
        accountProperties.accountDiscovery = [sender state];
        self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
    }
}

- (IBAction)autoEnableRingtone:(id)sender {
    lrc::api::account::ConfProperties_t accountProperties = self.accountModel->getAccountConfig(self.selectedAccountID);
    if(accountProperties.Ringtone.ringtoneEnabled != [sender state]) {
        accountProperties.Ringtone.ringtoneEnabled = [sender state];
        self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
        [ringtoneSelectionButton setEnabled:[sender state]];
    }
}

- (IBAction)togleUPnP:(id)sender {
    lrc::api::account::ConfProperties_t accountProperties = self.accountModel->getAccountConfig(self.selectedAccountID);
    if( accountProperties.upnpEnabled != [sender state]) {
        accountProperties.upnpEnabled = [sender state];
        self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
    }
}

- (IBAction)useTURN:(id)sender {
    lrc::api::account::ConfProperties_t accountProperties = self.accountModel->getAccountConfig(self.selectedAccountID);
    if( accountProperties.TURN.enable != [sender state]) {
        accountProperties.TURN.enable = [sender state];
        self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
        [turnAddressField setEditable:[sender state]];
        [turnUsernameField setEditable:[sender state]];
        [turnPasswordField setEditable:[sender state]];
        [turnRealmField setEditable:[sender state]];
    }
}

- (IBAction)useSTUN:(id)sender {
    lrc::api::account::ConfProperties_t accountProperties = self.accountModel->getAccountConfig(self.selectedAccountID);
    if( accountProperties.STUN.enable != [sender state]) {
        accountProperties.STUN.enable = [sender state];
        self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
        [stunAddressField setEditable:[sender state]];
    }
}

- (IBAction)selectFile:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    if ([panel runModal] != NSFileHandlingPanelOKButton) return;
    if ([[panel URLs] lastObject] == nil) return;
    NSString * path = [[[panel URLs] lastObject] path];
    lrc::api::account::ConfProperties_t accountProperties = self.accountModel->getAccountConfig(self.selectedAccountID);
    switch ([sender tag]) {
        case TAG_RINGTONE:
            if(accountProperties.Ringtone.ringtonePath != QString::fromNSString(path)) {
                accountProperties.Ringtone.ringtonePath = QString::fromNSString(path);
                self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
                [ringtoneSelectionButton setTitle:[path lastPathComponent]];
            }
            break;
        case TAG_CA_CERTIFICATE:
            if(accountProperties.TLS.certificateListFile != QString::fromNSString(path)) {
                accountProperties.TLS.certificateListFile = QString::fromNSString(path);
                self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
                [selectCACertificateButton setTitle:[path lastPathComponent]];
            }
            break;
        case TAG_USER_CERTIFICATE:
            if(accountProperties.TLS.certificateFile != QString::fromNSString(path)) {
                accountProperties.TLS.certificateFile = QString::fromNSString(path);
                self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
                [selectUserCertificateButton setTitle:[path lastPathComponent]];
            }
            break;
        case TAG_PRIVATE_KEY:
            if(accountProperties.TLS.privateKeyFile != QString::fromNSString(path)) {
                accountProperties.TLS.privateKeyFile = QString::fromNSString(path);
                self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
                [selectPrivateKeyButton setTitle:[path lastPathComponent]];
            }
            break;
    }
}

- (IBAction)valueDidChange:(id)sender
{
    lrc::api::account::ConfProperties_t accountProperties = self.accountModel->getAccountConfig(self.selectedAccountID);
    switch ([sender tag]) {
        case PRIVATE_KEY_PASSWORG_TAG:
            if(accountProperties.TLS.password != QString::fromNSString([sender stringValue])) {
                accountProperties.TLS.password = QString::fromNSString([sender stringValue]);
                self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
            }
            break;
        case TURN_ADDRESS_TAG:
            if(accountProperties.TURN.server != QString::fromNSString([sender stringValue])) {
                accountProperties.TURN.server = QString::fromNSString([sender stringValue]);
                self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
            }
            break;
        case TURN_USERNAME_TAG:
            if(accountProperties.TURN.username != QString::fromNSString([sender stringValue])) {
                accountProperties.TURN.username = QString::fromNSString([sender stringValue]);
                self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
            }
            break;
        case TURN_PASSWORD_TAG:
            if(accountProperties.TURN.password != QString::fromNSString([sender stringValue])) {
                accountProperties.TURN.password = QString::fromNSString([sender stringValue]);
                self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
            }
            break;
        case TURN_REALM_TAG:
            if(accountProperties.TURN.realm != QString::fromNSString([sender stringValue])) {
                accountProperties.TURN.realm = QString::fromNSString([sender stringValue]);
                self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
            }
            break;
        case STUN_ADDRESS_TAG:
            if(accountProperties.STUN.server != QString::fromNSString([sender stringValue])) {
                accountProperties.STUN.server = QString::fromNSString([sender stringValue]);
                self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
            }
            break;
        default:
            break;
    }
}

- (IBAction)moveAudioCodecUp:(id)sender {
    NSInteger row = [audioCodecView selectedRow];
    if(row < 0) {
        return;
    }
    auto audioCodecs = self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->getAudioCodecs();
    if ((audioCodecs.size() - 1) < row) {
        return;
    }
    auto codec = audioCodecs[row];
    self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->increasePriority(codec.id, false);
    [audioCodecView reloadData];
    row = row == 0 ? row: row-1;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex: row];
    [audioCodecView selectRowIndexes:indexSet byExtendingSelection: NO];
    [audioCodecView scrollRowToVisible:row];
}

- (IBAction)moveAudioCodecDown:(id)sender {
    NSInteger row = [audioCodecView selectedRow];
    if(row < 0) {
        return;
    }
    auto audioCodecs = self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->getAudioCodecs();
    if ((audioCodecs.size() - 1) < row) {
        return;
    }
    auto codec = audioCodecs[row];
    self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->decreasePriority(codec.id, false);
    [audioCodecView reloadData];
    row = (row == ([audioCodecView numberOfRows] - 1)) ? row: row+1;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex: row];
    [audioCodecView selectRowIndexes:indexSet byExtendingSelection: NO];
    [audioCodecView scrollRowToVisible:row];
}

- (IBAction)moveVideoCodecUp:(id)sender {
    NSInteger row = [videoCodecView selectedRow];
    if(row < 0) {
        return;
    }
    auto videoCodecs = self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->getVideoCodecs();
    if ((videoCodecs.size() - 1) < row) {
        return;
    }
    auto codec = videoCodecs[row];
    self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->increasePriority(codec.id, YES);
    [videoCodecView reloadData];
    row = row == 0 ? row: row-1;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex: row];
    [videoCodecView selectRowIndexes:indexSet byExtendingSelection: NO];
    [videoCodecView scrollRowToVisible:row];
}

- (IBAction)moveVideoCodecDown:(id)sender {
    NSInteger row = [videoCodecView selectedRow];
    if(row < 0) {
        return;
    }
    auto videoCodecs = self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->getVideoCodecs();
    if ((videoCodecs.size() - 1) < row) {
        return;
    }
    auto codec = videoCodecs[row];
    self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->decreasePriority(codec.id, YES);
    [videoCodecView reloadData];
    row = row == [videoCodecView numberOfRows] - 1 ? row: row+1;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex: row];
    [videoCodecView selectRowIndexes:indexSet byExtendingSelection: NO];
    [videoCodecView scrollRowToVisible:row];
}

- (IBAction)toggleVideoEnabled:(id)sender {
    lrc::api::account::ConfProperties_t accountProperties = self.accountModel->getAccountConfig(self.selectedAccountID);
    if(accountProperties.Video.videoEnabled != [sender state]) {
        accountProperties.Video.videoEnabled = [sender state];
        self.accountModel->setAccountConfig(self.selectedAccountID, accountProperties);
        [videoCodecView setEnabled:[sender state]];
        [videoCodecView reloadData];
        [disableVideoButton setHidden:[sender state]];
    }
}

- (IBAction)enableAudioCodec:(id)sender
{
    NSInteger row = [audioCodecView rowForView:sender];
    if(row < 0) {
        return;
    }
    auto audioCodecs = self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->getAudioCodecs();
    if ((audioCodecs.size()-1) < row) {
        return;
    }
    auto codec = audioCodecs[row];
    if (codec.enabled != [sender state]) {
        self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->enable(codec.id, [sender state]);
    }
}

- (IBAction)enableVideoCodec:(id)sender
{
    NSInteger row = [videoCodecView rowForView:sender];
    if(row < 0) {
        return;
    }
    auto videoCodecs = self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->getVideoCodecs();
    if ((videoCodecs.size()-1) < row) {
        return;
    }
    auto codec = videoCodecs[row];
    if (codec.enabled != [sender state]) {
        self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->enable(codec.id, [sender state]);
    }
}

#pragma mark - NSTableViewDelegate methods
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == audioCodecView) {
        NSTableCellView* audioCodecCell = [tableView makeViewWithIdentifier:@"TableCellAudioCodecItem" owner:self];
        NSTextField* nameLabel = [audioCodecCell viewWithTag: AUDIO_CODEC_NAME_TAG];
        NSTextField* samplerateLabel = [audioCodecCell viewWithTag: AUDIO_CODEC_SAMPLERATE_TAG];
        NSButton* codecEnableButton = [audioCodecCell viewWithTag: AUDIO_CODEC_ENABLE_TAG];
        auto audioCodecs = self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->getAudioCodecs();
        if ((audioCodecs.size() - 1) < row) {
            return nil;
        }
        auto codec = audioCodecs[row];
        [nameLabel setStringValue: codec.name.toNSString()];
        [samplerateLabel setStringValue: [codec.samplerate.toNSString() stringByAppendingString:@" Hz"]];
        [codecEnableButton setState:codec.enabled];
        [codecEnableButton setAction:@selector(enableAudioCodec:)];
        [codecEnableButton setTarget:self];
        return audioCodecCell;
    } else if (tableView == videoCodecView) {
        NSTableCellView* videoCodecCell = [tableView makeViewWithIdentifier:@"TableCellVideoCodecItem" owner:self];
        NSTextField* nameLabel = [videoCodecCell viewWithTag: VIDEO_CODEC_NAME_TAG];
        NSButton* codecEnableButton = [videoCodecCell viewWithTag: VIDIO_CODEC_ENABLE_TAG];
        nameLabel.textColor = [tableView isEnabled] ? [NSColor labelColor] : [NSColor lightGrayColor];
        [codecEnableButton setEnabled:[tableView isEnabled]];
        auto codecs = self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->getVideoCodecs();
        if ((codecs.size() - 1) < row) {
            return nil;
        }
        auto codec = codecs[row];
        [nameLabel setStringValue: codec.name.toNSString()];
        [codecEnableButton setState:codec.enabled];
        [codecEnableButton setAction:@selector(enableVideoCodec:)];
        [codecEnableButton setTarget:self];
        return videoCodecCell;
    }
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    if(![tableView isEnabled]) {
        return nil;
    }
    return [tableView makeViewWithIdentifier:@"HoverRowView" owner:nil];
}

#pragma mark - NSTableViewDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if(tableView == audioCodecView) {
        return self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->getAudioCodecs().size();
    } else if (tableView == videoCodecView){
        return self.accountModel->getAccountInfo(self.selectedAccountID).codecModel->getVideoCodecs().size();
    }
    return 0;
}

@end

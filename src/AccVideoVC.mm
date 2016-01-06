/*
 *  Copyright (C) 2015-2016 Savoir-faire Linux Inc.
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
#define COLUMNID_STATE   @"VideoStateColumn"
#define COLUMNID_CODECS   @"VideoCodecsColumn"
#define COLUMNID_FREQ     @"VideoFrequencyColumn"
#define COLUMNID_BITRATE  @"VideoBitrateColumn"

#import "AccVideoVC.h"

#include <QtCore/QSortFilterProxyModel>
#import <audio/codecmodel.h>
#import <accountmodel.h>
#import <qitemselectionmodel.h>

#import "QNSTreeController.h"

@interface AccVideoVC ()

@property QNSTreeController *treeController;
@property (assign) IBOutlet NSOutlineView *codecsView;
@property (assign) IBOutlet NSView *videoPanelContainer;
@property (assign) IBOutlet NSButton *toggleVideoButton;

@end

@implementation AccVideoVC
@synthesize treeController;
@synthesize codecsView;
@synthesize videoPanelContainer;
@synthesize toggleVideoButton;

- (void)awakeFromNib
{
    NSLog(@"INIT Video VC");
    QObject::connect(AccountModel::instance().selectionModel(),
                     &QItemSelectionModel::currentChanged,
                     [=](const QModelIndex &current, const QModelIndex &previous) {
                         if(!current.isValid())
                             return;
                         [self loadAccount];
                     });
}

- (Account*) currentAccount
{
    auto accIdx = AccountModel::instance().selectionModel()->currentIndex();
    return AccountModel::instance().getAccountByModelIndex(accIdx);
}

- (void)loadAccount
{
    auto account = [self currentAccount];

    treeController = [[QNSTreeController alloc] initWithQModel:account->codecModel()->videoCodecs()];
    [treeController setAvoidsEmptySelection:NO];
    [treeController setChildrenKeyPath:@"children"];

    [codecsView bind:@"content" toObject:treeController withKeyPath:@"arrangedObjects" options:nil];
    [codecsView bind:@"sortDescriptors" toObject:treeController withKeyPath:@"sortDescriptors" options:nil];
    [codecsView bind:@"selectionIndexPaths" toObject:treeController withKeyPath:@"selectionIndexPaths" options:nil];
    [videoPanelContainer setHidden:!account->isVideoEnabled()];
    [toggleVideoButton setState:account->isVideoEnabled()?NSOnState:NSOffState];
}

- (IBAction)toggleVideoEnabled:(id)sender {
    [self currentAccount]->setVideoEnabled([sender state] == NSOnState);
    [videoPanelContainer setHidden:![self currentAccount]->isVideoEnabled()];
}

- (IBAction)toggleCodec:(NSOutlineView*)sender {
    NSInteger row = [sender clickedRow];
    NSTableColumn *col = [sender tableColumnWithIdentifier:COLUMNID_STATE];
    NSButtonCell *cell = [col dataCellForRow:row];
    [self currentAccount]->codecModel()->videoCodecs()->setData([self currentAccount]->codecModel()->videoCodecs()->index(row, 0, QModelIndex()),
        cell.state == NSOnState ? Qt::Unchecked : Qt::Checked, Qt::CheckStateRole);
}

- (IBAction)moveUp:(id)sender {

    if([[treeController selectedNodes] count] > 0) {
        QModelIndex qIdx = [treeController toQIdx:[treeController selectedNodes][0]];
        if(!qIdx.isValid())
            return;

        QMimeData* mime = [self currentAccount]->codecModel()->mimeData(QModelIndexList() << qIdx);
        [self currentAccount]->codecModel()->dropMimeData(mime, Qt::MoveAction, qIdx.row() - 1, 0, QModelIndex());
    }
}

- (IBAction)moveDown:(id)sender {
    if([[treeController selectedNodes] count] > 0) {
        QModelIndex qIdx = [treeController toQIdx:[treeController selectedNodes][0]];
        if(!qIdx.isValid())
            return;

        QMimeData* mime = [self currentAccount]->codecModel()->mimeData(QModelIndexList() << qIdx);
        [self currentAccount]->codecModel()->dropMimeData(mime, Qt::MoveAction, qIdx.row() + 1, 0, QModelIndex());
    }
}

#pragma mark - NSOutlineViewDelegate methods

// -------------------------------------------------------------------------------
//	shouldSelectItem:item
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
{
    return YES;
}

// -------------------------------------------------------------------------------
//	dataCellForTableColumn:tableColumn:item
// -------------------------------------------------------------------------------
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    NSCell *returnCell = [tableColumn dataCell];

    if(item == nil)
        return returnCell;
    return returnCell;
}

// -------------------------------------------------------------------------------
//	textShouldEndEditing:fieldEditor
// -------------------------------------------------------------------------------
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if ([[fieldEditor string] length] == 0)
    {
        // don't allow empty node names
        return NO;
    }
    else
    {
        return YES;
    }
}

// -------------------------------------------------------------------------------
//	shouldEditTableColumn:tableColumn:item
//
//	Decide to allow the edit of the given outline view "item".
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

// -------------------------------------------------------------------------------
//	outlineView:willDisplayCell:forTableColumn:item
// -------------------------------------------------------------------------------
- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    QModelIndex qIdx = [treeController toQIdx:((NSTreeNode*)item)];
    if(!qIdx.isValid())
        return;

    if([[tableColumn identifier] isEqualToString:COLUMNID_STATE]) {
        [cell setState:[self currentAccount]->codecModel()->videoCodecs()->data(qIdx, Qt::CheckStateRole).value<BOOL>()?NSOnState:NSOffState];
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_CODECS])
    {
        cell.title = [self currentAccount]->codecModel()->videoCodecs()->data(qIdx, CodecModel::Role::NAME).toString().toNSString();
        [cell setState:[self currentAccount]->codecModel()->videoCodecs()->data(qIdx, Qt::CheckStateRole).value<BOOL>()?NSOnState:NSOffState];
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_FREQ])
    {
        cell.title = [self currentAccount]->codecModel()->videoCodecs()->data(qIdx, CodecModel::Role::SAMPLERATE).toString().toNSString();
    } else if ([[tableColumn identifier] isEqualToString:COLUMNID_BITRATE])
    {
        cell.title = [self currentAccount]->codecModel()->videoCodecs()->data(qIdx, CodecModel::Role::BITRATE).toString().toNSString();
    }
}

// -------------------------------------------------------------------------------
//	outlineViewSelectionDidChange:notification
// -------------------------------------------------------------------------------
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    // ask the tree controller for the current selection
}

@end

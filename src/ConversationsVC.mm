/*
 *  Copyright (C) 2015 Savoir-faire Linux Inc.
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
#import "ConversationsVC.h"

#import <callmodel.h>
#import <QtCore/qitemselectionmodel.h>

#define DISPLAYNAME_TAG 200

@interface ConversationsVC ()

@property QNSTreeController *treeController;
@property (assign) IBOutlet NSOutlineView *conversationsView;

@end

@implementation ConversationsVC
@synthesize conversationsView;
@synthesize treeController;
- (void)awakeFromNib
{
    NSLog(@"INIT Conversations VC");

    treeController = [[QNSTreeController alloc] initWithQModel:CallModel::instance()];

    [treeController setAvoidsEmptySelection:NO];
    [treeController setChildrenKeyPath:@"children"];

    [self.conversationsView bind:@"content" toObject:treeController withKeyPath:@"arrangedObjects" options:nil];
    [self.conversationsView bind:@"sortDescriptors" toObject:treeController withKeyPath:@"sortDescriptors" options:nil];
    [self.conversationsView bind:@"selectionIndexPaths" toObject:treeController withKeyPath:@"selectionIndexPaths" options:nil];

    QObject::connect(CallModel::instance(),
                     &QAbstractItemModel::dataChanged,
                     [=](const QModelIndex &topLeft, const QModelIndex &bottomRight) {
                         [conversationsView reloadDataForRowIndexes:
                          [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(topLeft.row(), bottomRight.row() + 1)]
                        columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, conversationsView.tableColumns.count)]];
                     });
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

/* View Based OutlineView: See the delegate method -tableView:viewForTableColumn:row: in NSTableView.
 */
- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    QModelIndex qIdx = [treeController toQIdx:((NSTreeNode*)item)];

    NSTableCellView *result = [outlineView makeViewWithIdentifier:@"MainCell" owner:outlineView];
    NSTextField* displayName = [result viewWithTag:DISPLAYNAME_TAG];

    [displayName setStringValue:qIdx.data(Qt::DisplayRole).toString().toNSString()];

    return result;
}

// -------------------------------------------------------------------------------
//	outlineViewSelectionDidChange:notification
// -------------------------------------------------------------------------------
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    // ask the tree controller for the current selection
//    if([[treeController selectedNodes] count] > 0) {
//        QModelIndex qIdx = [treeController toQIdx:[treeController selectedNodes][0]];
//        //Update details view by changing selection
//        if (qIdx.row() != CallModel::instance()->selectionModel()->currentIndex().row())
//            CallModel::instance()->selectionModel()->setCurrentIndex(qIdx, QItemSelectionModel::ClearAndSelect);
//    } else {
//        CallModel::instance()->selectionModel()->clearCurrentIndex();
//    }
}


@end

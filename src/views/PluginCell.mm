/*
 *  Copyright (C) 2021 Savoir-faire Linux Inc.
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

#import "PluginCell.h"

@implementation PluginCell

@synthesize containerView;

- (void)awakeFromNib{
    self.viewController = [[PluginItemDelegateVC alloc] initWithNibName:@"PluginItemDelegate" bundle:nil];
    [self.containerView addSubview: self.viewController.view];
    self.viewController.view.frame = self.containerView.frame;
}

@end

/*
*  Copyright (C) 2018-2019 Savoir-faire Linux Inc.
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

namespace lrc {
    namespace api {
        class DataTransferModel;
        class NewAccountModel;
        class BehaviorController;
        class AVModel;
        class PluginModel;
    }
}

@protocol LrcModelsProtocol

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil accountModel:(const lrc::api::NewAccountModel*)accountModel avModel:(const lrc::api::AVModel*) avModel;
-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil pluginModel:(const lrc::api::PluginModel*) pluginModel;
-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil avModel:(const lrc::api::AVModel*) avModel;
-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil accountmodel:(const lrc::api::NewAccountModel*) accountModel;
-(id) initWithWindowNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil accountModel:(lrc::api::NewAccountModel*)accountModel avModel: ( lrc::api::AVModel*)avModel;
-(id) initWithWindowNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil accountModel:(const lrc::api::NewAccountModel*)accountModel behaviourController:(const lrc::api::BehaviorController*) behaviorController avModel: (const lrc::api::AVModel*)avModel pluginModel: (const lrc::api::PluginModel*)pluginModel;

@property lrc::api::DataTransferModel* dataTransferModel;
@property lrc::api::NewAccountModel* accountModel;
@property lrc::api::BehaviorController* behaviorController;
@property lrc::api::AVModel* avModel;
@property lrc::api::PluginModel* pluginModel;

@end

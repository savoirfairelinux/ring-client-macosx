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
#import "ImageManipulationDelegate.h"

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

//Qt
#import <QSize>
#import <QBuffer>
#import <QtGui/QColor>
#import <QtGui/QPainter>
#import <QHash>
#import <QtGui/QBitmap>
#import <QtWidgets/QApplication>
#import <QtGui/QImage>
#import <QtMacExtras/qmacfunctions.h>
#import <QtGui/QPalette>

//LRC
#import <api/conversation.h>
#import <api/account.h>
#import <api/contactmodel.h>
#import <api/conversationmodel.h>
#import <api/contact.h>
#import <api/profile.h>

namespace Interfaces {

    // Colors from material.io
    const QColor ImageManipulationDelegate::avatarColors_[] = {
        {"#fff44336"}, //Red
        {"#ffe91e63"}, //Pink
        {"#ff9c27b0"}, //Purple
        {"#ff673ab7"}, //Deep Purple
        {"#ff3f51b5"}, //Indigo
        {"#ff2196f3"}, //Blue
        {"#ff00bcd4"}, //Cyan
        {"#ff009688"}, //Teal
        {"#ff4caf50"}, //Green
        {"#ff8bc34a"}, //Light Green
        {"#ff9e9e9e"}, //Grey
        {"#ffcddc39"}, //Lime
        {"#ffffc107"}, //Amber
        {"#ffff5722"}, //Deep Orange
        {"#ff795548"}, //Brown
        {"#ff607d8b"}  //Blue Grey
    };

    ImageManipulationDelegate::ImageManipulationDelegate() {}

    QPixmap
    ImageManipulationDelegate::crop(QPixmap& photo, const QSize& destSize)
    {
        auto initSize = photo.size();
        float leftDelta = 0;
        float topDelta = 0;

        if (destSize.height() == initSize.height()) {
            leftDelta = (destSize.width() - initSize.width()) / 2;
        } else {
            topDelta = (destSize.height() - initSize.height()) / 2;
        }

        float xScale = (float)destSize.width()  / initSize.width();
        float yScale = (float)destSize.height() / initSize.height();

        QRectF destRect(leftDelta, topDelta,
                            initSize.width() - leftDelta, initSize.height() - topDelta);

        destRect.setLeft(leftDelta * xScale);
        destRect.setTop(topDelta * yScale);

        destRect.setWidth((initSize.width() - leftDelta) * xScale);
        destRect.setHeight((initSize.height() - topDelta) * yScale);

        return photo.copy(destRect.toRect());
    }

    QVariant ImageManipulationDelegate::personPhoto(const QByteArray& data, const QString& type)
    {
        QImage image;
        //For now, ENCODING is only base64 and image type PNG or JPG
        bool ret = image.loadFromData(QByteArray::fromBase64(data),type.toLatin1());
        if (!ret) {
            ret = image.loadFromData(QByteArray::fromBase64(data), 0);
        }
        if (!ret) {
            qDebug() << "vCard image loading failed";
            return QVariant();
        }

        return QPixmap::fromImage(image);
    }

    QChar letterForDefaultUserPixmap(const lrc::api::contact::Info& contact)
    {
        if (!contact.profileInfo.alias.isEmpty()) {
            return contact.profileInfo.alias.at(0).toUpper();
        } else if((contact.profileInfo.type == lrc::api::profile::Type::JAMI ||
                contact.profileInfo.type == lrc::api::profile::Type::PENDING) &&
                  !contact.registeredName.isEmpty()) {
            return contact.registeredName.at(0).toUpper();
        } else {
            return contact.profileInfo.uri.at(0).toUpper();
        }
    }

    QVariant ImageManipulationDelegate::conversationPhoto(const lrc::api::conversation::Info& conversation,
                                                          const lrc::api::account::Info& accountInfo,
                                                          const QSize& size,
                                                          bool displayPresence)
    {
        Q_UNUSED(displayPresence)

        try {
            auto contact = accountInfo.contactModel->getContact(accountInfo.conversationModel->peersForConversation(conversation.uid)[0]);
//            auto contact = accountInfo.contactModel->getContact(accountInfo.conversationModel.peersForConversation(conversation.uid)[0]);
            auto& avatar = contact.profileInfo.avatar;
            if (!avatar.isEmpty()) {
                QPixmap pxm;
                const int radius = size.height() / 2;

                /*
                 * we could not now clear cache and image coul be outdated
                 * so do not use cache now
                // Check cache
                auto index = QStringLiteral("%1%2%3").arg(size.width())
                .arg(size.height())
                .arg(QString::fromStdString(conversation.uid));

                if (convPixmCache.contains(index)) {
                    return convPixmCache.value(index);
                }
                */

                auto contactPhoto = qvariant_cast<QPixmap>(personPhoto(avatar.toUtf8()));
                contactPhoto = contactPhoto.scaled(size, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);

                QPixmap finalImg;
                // We crop the avatar if picture is not squared as scaled() keep ratio of original picture
                if (contactPhoto.size() != size) {
                    finalImg = crop(contactPhoto, size);
                } else
                    finalImg = contactPhoto;

                // Creating clean QPixmap
                pxm = QPixmap(size);
                pxm.fill(Qt::transparent);

                //Add corner radius to the Pixmap
                QPainter painter(&pxm);
                painter.setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform);
                painter.setCompositionMode(QPainter::CompositionMode_SourceOver);
                QRect pxRect = finalImg.rect();
                QBitmap mask(pxRect.size());
                QPainter customPainter(&mask);
                customPainter.setRenderHints (QPainter::Antialiasing | QPainter::SmoothPixmapTransform);
                customPainter.fillRect       (pxRect                , Qt::white );
                customPainter.setBackground  (Qt::black                         );
                customPainter.setBrush       (Qt::black                         );
                customPainter.drawRoundedRect(pxRect,radius,radius              );
                finalImg.setMask             (mask                              );
                painter.drawPixmap           (0,0,finalImg                      );
                painter.setBrush             (Qt::NoBrush                       );
                painter.setPen               (Qt::transparent                   );
                painter.setCompositionMode   (QPainter::CompositionMode_SourceIn);
                painter.drawRoundedRect(0,0,pxm.height(),pxm.height(),radius,radius);

                // Save in cache
                //convPixmCache.insert(index, pxm);

                return pxm;
            } else {
                if (contact.profileInfo.uri.isEmpty()) {
                    return QVariant();
                }
                auto color = contact.profileInfo.uri.at(0);
                auto trimmed = contact.profileInfo.alias.trimmed().replace("\r","").replace("\n","");
                if (!trimmed.isEmpty()) {
                    return drawDefaultUserPixmap(size, color.toLatin1(), trimmed.at(0).toUpper().toLatin1());
                } else if((contact.profileInfo.type == lrc::api::profile::Type::JAMI ||
                           contact.profileInfo.type == lrc::api::profile::Type::PENDING) &&
                          !contact.registeredName.isEmpty()) {
                    trimmed = contact.registeredName.trimmed().replace("\r","").replace("\n","");
                    if(!trimmed.isEmpty()) {
                        return drawDefaultUserPixmap(size, color.toLatin1(), trimmed.at(0).toUpper().toLatin1());
                    } else {
                        return drawDefaultUserPixmapUriOnly(size, color.toLatin1());
                    }
                } else {
                    return drawDefaultUserPixmapUriOnly(size, color.toLatin1());
                }
            }
        } catch (...) {
            return QVariant();
        }
    }

    QByteArray ImageManipulationDelegate::toByteArray(const QVariant& pxm)
    {
        //Preparation of our QPixmap
        QByteArray bArray;
        QBuffer buffer(&bArray);
        buffer.open(QIODevice::WriteOnly);

        //PNG ?
        (qvariant_cast<QPixmap>(pxm)).scaled({100,100}).save(&buffer, "PNG");
        buffer.close();

        return bArray;
    }

    QPixmap ImageManipulationDelegate::drawDefaultUserPixmap(const QSize& size,  const char color, const char letter) {
        // We start with a transparent avatar
        QPixmap avatar(size);
        avatar.fill(Qt::transparent);

        // We pick a color based on the passed character
        QColor avColor = ImageManipulationDelegate::avatarColors_[color % 16];

        // We draw a circle with this color
        QPainter painter(&avatar);
        painter.setRenderHints(QPainter::Antialiasing|QPainter::SmoothPixmapTransform);
        painter.setPen(Qt::transparent);
        painter.setBrush(avColor);
        painter.drawEllipse(avatar.rect());

        // Then we paint a letter in the circle
        auto font = painter.font();
        font.setPointSize(avatar.height()/2);
        painter.setFont(font);
        painter.setPen(Qt::white);
        QRect textRect = avatar.rect();
        painter.drawText(textRect, QString(letter), QTextOption(Qt::AlignCenter));

        return avatar;
    }

    QPixmap ImageManipulationDelegate::drawDefaultUserPixmapUriOnly(const QSize& size,  const char color) {
        // We start with a transparent avatar
        QPixmap avatar(size);
        avatar.fill(Qt::transparent);

        // We pick a color based on the passed character
        QColor avColor = ImageManipulationDelegate::avatarColors_[color % 16];

        // We draw a circle with this color
        QPainter painter(&avatar);
        painter.setRenderHints(QPainter::Antialiasing|QPainter::SmoothPixmapTransform);
        painter.setPen(Qt::transparent);
        painter.setBrush(avColor);
        painter.drawEllipse(avatar.rect());

        // Then we paint the avatar in the circle
        QRect textRect = avatar.rect();
        QImage defaultAvatarImage;
        QRect rect = QRect(0, 0, size.width(), size.height());
        NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        NSString *imagePath = [bundleURL.absoluteString stringByAppendingString:@"Contents/Resources/default_avatar_overlay.png"];
        if (defaultAvatarImage.load(QString::fromNSString(imagePath).mid(7))) {
            painter.drawImage(avatar.rect(), defaultAvatarImage);
        } else {
            painter.drawText(avatar.rect(), QString('?'), QTextOption(Qt::AlignCenter));
        }

        return avatar;
    }

    CGImageRef ImageManipulationDelegate::resizeCGImage(CGImageRef image, const QSize& size) {
        // create context, keeping original image properties
        CGContextRef context = CGBitmapContextCreate(NULL, size.width(), size.height(),
                                                     CGImageGetBitsPerComponent(image),
                                                     CGImageGetBytesPerRow(image),
                                                     CGImageGetColorSpace(image),
                                                     kCGImageAlphaPremultipliedLast);

        if(context == NULL)
            return nil;

        // draw image to context (resizing it)
        CGContextDrawImage(context, CGRectMake(0, 0, size.width(), size.height()), image);
        // extract resulting image from context
        CGImageRef imgRef = CGBitmapContextCreateImage(context);
        CGContextRelease(context);

        return imgRef;
    }

    QVariant
    ImageManipulationDelegate::numberCategoryIcon(const QVariant& p, const QSize& size, bool displayPresence, bool isPresent)
    {
        Q_UNUSED(p)
        Q_UNUSED(size)
        Q_UNUSED(displayPresence)
        Q_UNUSED(isPresent)
        return QVariant();
    }

    QVariant
    ImageManipulationDelegate::userActionIcon(const UserActionElement& state) const
    {
        Q_UNUSED(state)
        return QVariant();
    }

    QVariant ImageManipulationDelegate::decorationRole(const QModelIndex& index)
    {
        Q_UNUSED(index)
        return QVariant();
    }
} // namespace Interfaces

/****************************************************************************
** Meta object code from reading C++ file 'mediainfo.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/mediainfo.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'mediainfo.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.11.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN9MediaInfoE_t {};
} // unnamed namespace

template <> constexpr inline auto MediaInfo::qt_create_metaobjectdata<qt_meta_tag_ZN9MediaInfoE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "MediaInfo",
        "mediaChanged",
        "",
        "refresh",
        "playPause",
        "next",
        "previous",
        "seekToRatio",
        "ratio",
        "seekRelative",
        "offsetSeconds",
        "setVolume",
        "volume",
        "selectPlayer",
        "playerId",
        "selectPlayerAt",
        "index",
        "playerName",
        "availablePlayers",
        "availablePlayerLabels",
        "selectedPlayer",
        "title",
        "artist",
        "status",
        "positionSeconds",
        "lengthSeconds",
        "artUrl",
        "isVideo",
        "hasMedia"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'mediaChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'refresh'
        QtMocHelpers::SlotData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'playPause'
        QtMocHelpers::MethodData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'next'
        QtMocHelpers::MethodData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'previous'
        QtMocHelpers::MethodData<void()>(6, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'seekToRatio'
        QtMocHelpers::MethodData<void(double)>(7, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Double, 8 },
        }}),
        // Method 'seekRelative'
        QtMocHelpers::MethodData<void(double)>(9, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Double, 10 },
        }}),
        // Method 'setVolume'
        QtMocHelpers::MethodData<void(double)>(11, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Double, 12 },
        }}),
        // Method 'selectPlayer'
        QtMocHelpers::MethodData<void(const QString &)>(13, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 14 },
        }}),
        // Method 'selectPlayerAt'
        QtMocHelpers::MethodData<void(int)>(15, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 16 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'playerName'
        QtMocHelpers::PropertyData<QString>(17, QMetaType::QString, QMC::DefaultPropertyFlags, 0),
        // property 'availablePlayers'
        QtMocHelpers::PropertyData<QStringList>(18, QMetaType::QStringList, QMC::DefaultPropertyFlags, 0),
        // property 'availablePlayerLabels'
        QtMocHelpers::PropertyData<QStringList>(19, QMetaType::QStringList, QMC::DefaultPropertyFlags, 0),
        // property 'selectedPlayer'
        QtMocHelpers::PropertyData<QString>(20, QMetaType::QString, QMC::DefaultPropertyFlags, 0),
        // property 'title'
        QtMocHelpers::PropertyData<QString>(21, QMetaType::QString, QMC::DefaultPropertyFlags, 0),
        // property 'artist'
        QtMocHelpers::PropertyData<QString>(22, QMetaType::QString, QMC::DefaultPropertyFlags, 0),
        // property 'status'
        QtMocHelpers::PropertyData<QString>(23, QMetaType::QString, QMC::DefaultPropertyFlags, 0),
        // property 'positionSeconds'
        QtMocHelpers::PropertyData<double>(24, QMetaType::Double, QMC::DefaultPropertyFlags, 0),
        // property 'lengthSeconds'
        QtMocHelpers::PropertyData<double>(25, QMetaType::Double, QMC::DefaultPropertyFlags, 0),
        // property 'volume'
        QtMocHelpers::PropertyData<double>(12, QMetaType::Double, QMC::DefaultPropertyFlags, 0),
        // property 'artUrl'
        QtMocHelpers::PropertyData<QString>(26, QMetaType::QString, QMC::DefaultPropertyFlags, 0),
        // property 'isVideo'
        QtMocHelpers::PropertyData<bool>(27, QMetaType::Bool, QMC::DefaultPropertyFlags, 0),
        // property 'hasMedia'
        QtMocHelpers::PropertyData<bool>(28, QMetaType::Bool, QMC::DefaultPropertyFlags, 0),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<MediaInfo, qt_meta_tag_ZN9MediaInfoE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject MediaInfo::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9MediaInfoE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9MediaInfoE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN9MediaInfoE_t>.metaTypes,
    nullptr
} };

void MediaInfo::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<MediaInfo *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->mediaChanged(); break;
        case 1: _t->refresh(); break;
        case 2: _t->playPause(); break;
        case 3: _t->next(); break;
        case 4: _t->previous(); break;
        case 5: _t->seekToRatio((*reinterpret_cast<std::add_pointer_t<double>>(_a[1]))); break;
        case 6: _t->seekRelative((*reinterpret_cast<std::add_pointer_t<double>>(_a[1]))); break;
        case 7: _t->setVolume((*reinterpret_cast<std::add_pointer_t<double>>(_a[1]))); break;
        case 8: _t->selectPlayer((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 9: _t->selectPlayerAt((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (MediaInfo::*)()>(_a, &MediaInfo::mediaChanged, 0))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<QString*>(_v) = _t->playerName(); break;
        case 1: *reinterpret_cast<QStringList*>(_v) = _t->availablePlayers(); break;
        case 2: *reinterpret_cast<QStringList*>(_v) = _t->availablePlayerLabels(); break;
        case 3: *reinterpret_cast<QString*>(_v) = _t->selectedPlayer(); break;
        case 4: *reinterpret_cast<QString*>(_v) = _t->title(); break;
        case 5: *reinterpret_cast<QString*>(_v) = _t->artist(); break;
        case 6: *reinterpret_cast<QString*>(_v) = _t->status(); break;
        case 7: *reinterpret_cast<double*>(_v) = _t->positionSeconds(); break;
        case 8: *reinterpret_cast<double*>(_v) = _t->lengthSeconds(); break;
        case 9: *reinterpret_cast<double*>(_v) = _t->volume(); break;
        case 10: *reinterpret_cast<QString*>(_v) = _t->artUrl(); break;
        case 11: *reinterpret_cast<bool*>(_v) = _t->isVideo(); break;
        case 12: *reinterpret_cast<bool*>(_v) = _t->hasMedia(); break;
        default: break;
        }
    }
}

const QMetaObject *MediaInfo::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *MediaInfo::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN9MediaInfoE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int MediaInfo::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 10)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 10;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 10)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 10;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 13;
    }
    return _id;
}

// SIGNAL 0
void MediaInfo::mediaChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}
QT_WARNING_POP

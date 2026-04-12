/****************************************************************************
** Meta object code from reading C++ file 'systeminfo.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/systeminfo.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'systeminfo.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN10SystemInfoE_t {};
} // unnamed namespace

template <> constexpr inline auto SystemInfo::qt_create_metaobjectdata<qt_meta_tag_ZN10SystemInfoE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "SystemInfo",
        "cpuUsageChanged",
        "",
        "gpuUsageChanged",
        "ramUsageChanged",
        "diskUsageChanged",
        "cpuNameChanged",
        "gpuNameChanged",
        "ramTotalsChanged",
        "diskTotalsChanged",
        "diskNameChanged",
        "networkChanged",
        "batteryPercentChanged",
        "osNameChanged",
        "deNameChanged",
        "themeNameChanged",
        "uptimeTextChanged",
        "cpuUsage",
        "gpuUsage",
        "ramUsage",
        "diskUsage",
        "cpuName",
        "gpuName",
        "ramUsedGiB",
        "ramTotalGiB",
        "diskUsedGiB",
        "diskTotalGiB",
        "diskName",
        "networkDownBps",
        "networkUpBps",
        "batteryPercent",
        "osName",
        "deName",
        "themeName",
        "uptimeText"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'cpuUsageChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'gpuUsageChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'ramUsageChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'diskUsageChanged'
        QtMocHelpers::SignalData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'cpuNameChanged'
        QtMocHelpers::SignalData<void()>(6, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'gpuNameChanged'
        QtMocHelpers::SignalData<void()>(7, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'ramTotalsChanged'
        QtMocHelpers::SignalData<void()>(8, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'diskTotalsChanged'
        QtMocHelpers::SignalData<void()>(9, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'diskNameChanged'
        QtMocHelpers::SignalData<void()>(10, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'networkChanged'
        QtMocHelpers::SignalData<void()>(11, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'batteryPercentChanged'
        QtMocHelpers::SignalData<void()>(12, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'osNameChanged'
        QtMocHelpers::SignalData<void()>(13, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'deNameChanged'
        QtMocHelpers::SignalData<void()>(14, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'themeNameChanged'
        QtMocHelpers::SignalData<void()>(15, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'uptimeTextChanged'
        QtMocHelpers::SignalData<void()>(16, 2, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'cpuUsage'
        QtMocHelpers::PropertyData<int>(17, QMetaType::Int, QMC::DefaultPropertyFlags, 0),
        // property 'gpuUsage'
        QtMocHelpers::PropertyData<int>(18, QMetaType::Int, QMC::DefaultPropertyFlags, 1),
        // property 'ramUsage'
        QtMocHelpers::PropertyData<int>(19, QMetaType::Int, QMC::DefaultPropertyFlags, 2),
        // property 'diskUsage'
        QtMocHelpers::PropertyData<int>(20, QMetaType::Int, QMC::DefaultPropertyFlags, 3),
        // property 'cpuName'
        QtMocHelpers::PropertyData<QString>(21, QMetaType::QString, QMC::DefaultPropertyFlags, 4),
        // property 'gpuName'
        QtMocHelpers::PropertyData<QString>(22, QMetaType::QString, QMC::DefaultPropertyFlags, 5),
        // property 'ramUsedGiB'
        QtMocHelpers::PropertyData<double>(23, QMetaType::Double, QMC::DefaultPropertyFlags, 6),
        // property 'ramTotalGiB'
        QtMocHelpers::PropertyData<double>(24, QMetaType::Double, QMC::DefaultPropertyFlags, 6),
        // property 'diskUsedGiB'
        QtMocHelpers::PropertyData<double>(25, QMetaType::Double, QMC::DefaultPropertyFlags, 7),
        // property 'diskTotalGiB'
        QtMocHelpers::PropertyData<double>(26, QMetaType::Double, QMC::DefaultPropertyFlags, 7),
        // property 'diskName'
        QtMocHelpers::PropertyData<QString>(27, QMetaType::QString, QMC::DefaultPropertyFlags, 8),
        // property 'networkDownBps'
        QtMocHelpers::PropertyData<double>(28, QMetaType::Double, QMC::DefaultPropertyFlags, 9),
        // property 'networkUpBps'
        QtMocHelpers::PropertyData<double>(29, QMetaType::Double, QMC::DefaultPropertyFlags, 9),
        // property 'batteryPercent'
        QtMocHelpers::PropertyData<int>(30, QMetaType::Int, QMC::DefaultPropertyFlags, 10),
        // property 'osName'
        QtMocHelpers::PropertyData<QString>(31, QMetaType::QString, QMC::DefaultPropertyFlags, 11),
        // property 'deName'
        QtMocHelpers::PropertyData<QString>(32, QMetaType::QString, QMC::DefaultPropertyFlags, 12),
        // property 'themeName'
        QtMocHelpers::PropertyData<QString>(33, QMetaType::QString, QMC::DefaultPropertyFlags, 13),
        // property 'uptimeText'
        QtMocHelpers::PropertyData<QString>(34, QMetaType::QString, QMC::DefaultPropertyFlags, 14),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<SystemInfo, qt_meta_tag_ZN10SystemInfoE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject SystemInfo::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10SystemInfoE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10SystemInfoE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN10SystemInfoE_t>.metaTypes,
    nullptr
} };

void SystemInfo::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<SystemInfo *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->cpuUsageChanged(); break;
        case 1: _t->gpuUsageChanged(); break;
        case 2: _t->ramUsageChanged(); break;
        case 3: _t->diskUsageChanged(); break;
        case 4: _t->cpuNameChanged(); break;
        case 5: _t->gpuNameChanged(); break;
        case 6: _t->ramTotalsChanged(); break;
        case 7: _t->diskTotalsChanged(); break;
        case 8: _t->diskNameChanged(); break;
        case 9: _t->networkChanged(); break;
        case 10: _t->batteryPercentChanged(); break;
        case 11: _t->osNameChanged(); break;
        case 12: _t->deNameChanged(); break;
        case 13: _t->themeNameChanged(); break;
        case 14: _t->uptimeTextChanged(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::cpuUsageChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::gpuUsageChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::ramUsageChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::diskUsageChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::cpuNameChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::gpuNameChanged, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::ramTotalsChanged, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::diskTotalsChanged, 7))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::diskNameChanged, 8))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::networkChanged, 9))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::batteryPercentChanged, 10))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::osNameChanged, 11))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::deNameChanged, 12))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::themeNameChanged, 13))
            return;
        if (QtMocHelpers::indexOfMethod<void (SystemInfo::*)()>(_a, &SystemInfo::uptimeTextChanged, 14))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<int*>(_v) = _t->cpuUsage(); break;
        case 1: *reinterpret_cast<int*>(_v) = _t->gpuUsage(); break;
        case 2: *reinterpret_cast<int*>(_v) = _t->ramUsage(); break;
        case 3: *reinterpret_cast<int*>(_v) = _t->diskUsage(); break;
        case 4: *reinterpret_cast<QString*>(_v) = _t->cpuName(); break;
        case 5: *reinterpret_cast<QString*>(_v) = _t->gpuName(); break;
        case 6: *reinterpret_cast<double*>(_v) = _t->ramUsedGiB(); break;
        case 7: *reinterpret_cast<double*>(_v) = _t->ramTotalGiB(); break;
        case 8: *reinterpret_cast<double*>(_v) = _t->diskUsedGiB(); break;
        case 9: *reinterpret_cast<double*>(_v) = _t->diskTotalGiB(); break;
        case 10: *reinterpret_cast<QString*>(_v) = _t->diskName(); break;
        case 11: *reinterpret_cast<double*>(_v) = _t->networkDownBps(); break;
        case 12: *reinterpret_cast<double*>(_v) = _t->networkUpBps(); break;
        case 13: *reinterpret_cast<int*>(_v) = _t->batteryPercent(); break;
        case 14: *reinterpret_cast<QString*>(_v) = _t->osName(); break;
        case 15: *reinterpret_cast<QString*>(_v) = _t->deName(); break;
        case 16: *reinterpret_cast<QString*>(_v) = _t->themeName(); break;
        case 17: *reinterpret_cast<QString*>(_v) = _t->uptimeText(); break;
        default: break;
        }
    }
}

const QMetaObject *SystemInfo::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *SystemInfo::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10SystemInfoE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int SystemInfo::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 15)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 15;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 15)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 15;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 18;
    }
    return _id;
}

// SIGNAL 0
void SystemInfo::cpuUsageChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void SystemInfo::gpuUsageChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void SystemInfo::ramUsageChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void SystemInfo::diskUsageChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void SystemInfo::cpuNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void SystemInfo::gpuNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void SystemInfo::ramTotalsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}

// SIGNAL 7
void SystemInfo::diskTotalsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 7, nullptr);
}

// SIGNAL 8
void SystemInfo::diskNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 8, nullptr);
}

// SIGNAL 9
void SystemInfo::networkChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 9, nullptr);
}

// SIGNAL 10
void SystemInfo::batteryPercentChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 10, nullptr);
}

// SIGNAL 11
void SystemInfo::osNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 11, nullptr);
}

// SIGNAL 12
void SystemInfo::deNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 12, nullptr);
}

// SIGNAL 13
void SystemInfo::themeNameChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 13, nullptr);
}

// SIGNAL 14
void SystemInfo::uptimeTextChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 14, nullptr);
}
QT_WARNING_POP

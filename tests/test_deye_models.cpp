#include "api/DeyeModels.h"

#include <QJsonDocument>
#include <QtTest>

using namespace deye;

class TestDeyeModels : public QObject {
    Q_OBJECT

private slots:
    void sha256PasswordHashing()
    {
        DeyeCredentials creds;
        creds.password = QStringLiteral("hello");
        // Known SHA-256 of "hello"
        QCOMPARE(creds.sha256PasswordHex(),
                 QStringLiteral("2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"));
    }

    void tokenRequestJsonAllLoginMethods()
    {
        // Email login without companyId
        {
            DeyeCredentials c;
            c.baseUrl = QStringLiteral("https://eu1-developer.deyecloud.com/");
            c.appId = QStringLiteral("app123");
            c.appSecret = QStringLiteral("sec456");
            c.loginMethod = LoginMethod::Email;
            c.email = QStringLiteral("user@example.com");
            c.password = QStringLiteral("hello");

            QVERIFY(c.validate().isEmpty());
            QCOMPARE(c.normalizedBaseUrl(), QStringLiteral("https://eu1-developer.deyecloud.com"));

            const QJsonObject obj = c.toTokenRequestJson();
            QCOMPARE(obj.value("appSecret").toString(), QStringLiteral("sec456"));
            QCOMPARE(obj.value("email").toString(), QStringLiteral("user@example.com"));
            QVERIFY(!obj.contains("mobile"));
            QVERIFY(!obj.contains("username"));
            QVERIFY(!obj.contains("companyId"));
        }

        // Phone login with leading '+' stripped and optional companyId
        {
            DeyeCredentials c;
            c.baseUrl = QStringLiteral("https://eu1-developer.deyecloud.com");
            c.appId = QStringLiteral("app123");
            c.appSecret = QStringLiteral("sec456");
            c.loginMethod = LoginMethod::Phone;
            c.countryCode = QStringLiteral("+48");
            c.mobile = QStringLiteral("500600700");
            c.companyId = QStringLiteral("9988");
            c.password = QStringLiteral("secret");

            QVERIFY(c.validate().isEmpty());
            const QJsonObject obj = c.toTokenRequestJson();
            QCOMPARE(obj.value("countryCode").toString(), QStringLiteral("48"));
            QCOMPARE(obj.value("mobile").toString(), QStringLiteral("500600700"));
            QCOMPARE(obj.value("companyId").toString(), QStringLiteral("9988"));
            QVERIFY(!obj.contains("email"));
        }

        // Username login
        {
            DeyeCredentials c;
            c.baseUrl = QStringLiteral("https://us1-developer.deyecloud.com");
            c.appId = QStringLiteral("app123");
            c.appSecret = QStringLiteral("sec456");
            c.loginMethod = LoginMethod::Username;
            c.username = QStringLiteral("solar_admin");
            c.password = QStringLiteral("secret");

            QVERIFY(c.validate().isEmpty());
            const QJsonObject obj = c.toTokenRequestJson();
            QCOMPARE(obj.value("username").toString(), QStringLiteral("solar_admin"));
            QVERIFY(!obj.contains("email"));
            QVERIFY(!obj.contains("mobile"));
        }
    }

    void parseAuthResponseRootAndNested()
    {
        const QByteArray rootJson = R"({
            "code": "1000000",
            "msg": "success",
            "success": true,
            "accessToken": "tok_root_123",
            "expiresIn": "5183999",
            "tokenType": "bearer"
        })";
        const auto r1 = DeyeAuthResult::fromJson(QJsonDocument::fromJson(rootJson).object());
        QVERIFY(r1.success);
        QCOMPARE(r1.accessToken, QStringLiteral("tok_root_123"));
        QCOMPARE(r1.expiresInSeconds, 5183999LL);

        const QByteArray nestedJson = R"({
            "code": "0",
            "msg": "success",
            "success": true,
            "data": {
                "accessToken": "tok_nested_456",
                "refreshToken": "ref_789",
                "expiresIn": 86400
            }
        })";
        const auto r2 = DeyeAuthResult::fromJson(QJsonDocument::fromJson(nestedJson).object());
        QVERIFY(r2.success);
        QCOMPARE(r2.accessToken, QStringLiteral("tok_nested_456"));
        QCOMPARE(r2.refreshToken, QStringLiteral("ref_789"));
        QCOMPARE(r2.expiresInSeconds, 86400LL);

        const QByteArray errorJson = R"({
            "code": "2101001",
            "msg": "Invalid password",
            "success": false
        })";
        const auto r3 = DeyeAuthResult::fromJson(QJsonDocument::fromJson(errorJson).object());
        QVERIFY(!r3.success);
        QCOMPARE(r3.code, QStringLiteral("2101001"));
        QCOMPARE(r3.message, QStringLiteral("Invalid password"));
    }

    void parseStationList()
    {
        const QByteArray json = R"({
            "code": "1000000",
            "msg": "success",
            "success": true,
            "total": 2,
            "stationList": [
                {
                    "id": 61151868,
                    "name": "Home PV",
                    "locationAddress": "Berlin",
                    "installedCapacity": 10.5,
                    "connectionStatus": "NORMAL",
                    "generationPower": 3200.0,
                    "batterySOC": 80.0
                },
                {
                    "id": 61151869,
                    "name": "Garage",
                    "capacity": 5.0,
                    "status": 3
                }
            ]
        })";

        const auto res = StationListResult::fromJson(QJsonDocument::fromJson(json).object());
        QVERIFY(res.success);
        QCOMPARE(res.total, 2);
        QCOMPARE(res.stations.size(), 2);
        QCOMPARE(res.stations[0].id, 61151868LL);
        QCOMPARE(res.stations[0].name, QStringLiteral("Home PV"));
        QCOMPARE(res.stations[0].installedCapacityKw, 10.5);
        QCOMPARE(res.stations[0].connectionStatus, QStringLiteral("NORMAL"));
        QCOMPARE(res.stations[1].installedCapacityKw, 5.0);
        QCOMPARE(res.stations[1].connectionStatus, QStringLiteral("ALL_OFFLINE"));
    }

    void parseStationLatest()
    {
        const QByteArray json = R"({
            "code": "1000000",
            "msg": "success",
            "success": true,
            "generationPower": 2985.0,
            "consumptionPower": 54.0,
            "gridPower": null,
            "purchasePower": null,
            "wirePower": 54.0,
            "chargePower": -3016.0,
            "dischargePower": null,
            "batteryPower": -3016.0,
            "batterySOC": 83.0,
            "lastUpdateTime": 1737070476
        })";

        const auto data = StationLatestData::fromJson(QJsonDocument::fromJson(json).object());
        QVERIFY(data.success);
        QCOMPARE(data.generationPowerW, 2985.0);
        QCOMPARE(data.consumptionPowerW, 54.0);
        QVERIFY(data.hasBatterySoc);
        QCOMPARE(data.batterySoc, 83.0);
        // Charging should be normalized to positive
        QCOMPARE(data.batteryPowerW, 3016.0);
        // Importing (wirePower > 0) normalized to positive
        QCOMPARE(data.gridPowerW, 54.0);
        QCOMPARE(data.lastUpdateTime, 1737070476LL);
    }

    void parseStationDevices()
    {
        const QByteArray json = R"({
            "code": "1000000",
            "msg": "success",
            "success": true,
            "total": 2,
            "deviceListItems": [
                {
                    "deviceId": 98765432,
                    "deviceSn": "2212228299",
                    "deviceName": "Inverter 1",
                    "deviceType": "INVERTER",
                    "productId": "SUN-10K-SG04LP3-EU",
                    "connectStatus": 1,
                    "collectionTime": 1718012400000
                },
                {
                    "deviceId": 98765433,
                    "deviceSn": "4100998877",
                    "deviceType": 2,
                    "connectStatus": 0,
                    "collectionTime": 1718012400
                }
            ]
        })";

        const auto res = DeviceListResult::fromJson(QJsonDocument::fromJson(json).object());
        QVERIFY(res.success);
        QCOMPARE(res.total, 2);
        QCOMPARE(res.devices.size(), 2);
        QCOMPARE(res.devices[0].deviceSn, QStringLiteral("2212228299"));
        QCOMPARE(res.devices[0].deviceName, QStringLiteral("Inverter 1"));
        QCOMPARE(res.devices[0].deviceType, QStringLiteral("Inverter"));
        QCOMPARE(res.devices[0].connectionStatus, QStringLiteral("NORMAL"));
        QCOMPARE(res.devices[0].collectionTime, 1718012400LL);
        QCOMPARE(res.devices[1].deviceType, QStringLiteral("Data Logger"));
        QCOMPARE(res.devices[1].connectionStatus, QStringLiteral("ALL_OFFLINE"));
    }

    void parseInverterConfigsAndOrder()
    {
        const QByteArray sysJson = R"({
            "code": "1000000",
            "success": true,
            "data": {
                "workMode": "ZERO_EXPORT_TO_CT",
                "energyPattern": "BATTERY_FIRST",
                "solarSell": true,
                "limitControl": "ZERO_EXPORT_TO_CT",
                "maxSellPower": 8000,
                "maxSolarPower": 10000,
                "gridPeakShaving": true,
                "gridPeakShavingPower": 4500
            }
        })";
        const auto sys = InverterSystemConfig::fromJson(QJsonDocument::fromJson(sysJson).object());
        QVERIFY(sys.success);
        QCOMPARE(sys.workMode, QStringLiteral("ZERO_EXPORT_TO_CT"));
        QCOMPARE(sys.energyPattern, QStringLiteral("BATTERY_FIRST"));
        QVERIFY(sys.solarSell);
        QCOMPARE(sys.maxSellPower, 8000);
        QCOMPARE(sys.gridPeakShavingPower, 4500);

        const QByteArray battJson = R"({
            "code": "1000000",
            "success": true,
            "data": {
                "batteryType": "LITHIUM",
                "gridCharge": true,
                "maxChargeCurrent": 80,
                "maxDischargeCurrent": 100,
                "shutdownSOC": 10,
                "floatV": 55.2
            }
        })";
        const auto batt = InverterBatteryConfig::fromJson(QJsonDocument::fromJson(battJson).object());
        QVERIFY(batt.success);
        QCOMPARE(batt.batteryType, QStringLiteral("LITHIUM"));
        QVERIFY(batt.gridChargeEnabled);
        QCOMPARE(batt.maxChargeCurrent, 80);
        QCOMPARE(batt.shutdownSoc, 10);
        QCOMPARE(batt.floatV, 55.2);

        const QByteArray touJson = R"({
            "code": "1000000",
            "success": true,
            "data": {
                "touAction": "on",
                "timeUseSettingItems": [
                    {"time": 0, "soc": 80, "power": 5000, "voltage": 0, "enableGridCharge": true, "enableGeneration": false},
                    {"time": 530, "soc": 50, "power": 5000, "voltage": 0, "enableGridCharge": false, "enableGeneration": false},
                    {"time": "1400", "soc": 90, "power": 6000, "voltage": 0, "enableGridCharge": false, "enableGeneration": false}
                ]
            }
        })";
        const auto tou = InverterTouConfig::fromJson(QJsonDocument::fromJson(touJson).object());
        QVERIFY(tou.success);
        QVERIFY(tou.enabled);
        QCOMPARE(tou.slotsList.size(), 3);
        QCOMPARE(tou.slotsList[0].time, QStringLiteral("00:00"));
        QCOMPARE(tou.slotsList[1].time, QStringLiteral("05:30"));
        QCOMPARE(tou.slotsList[2].time, QStringLiteral("14:00"));
        QCOMPARE(tou.slotsList[0].soc, 80);
        QVERIFY(tou.slotsList[0].enableGridCharge);

        const QByteArray orderJson = R"({"code": "1000000", "success": true, "orderId": "ord_9981"})";
        const auto ord = OrderResult::fromJson(QJsonDocument::fromJson(orderJson).object());
        QVERIFY(ord.success);
        QCOMPARE(ord.orderId, QStringLiteral("ord_9981"));
    }
};

QTEST_MAIN(TestDeyeModels)
#include "test_deye_models.moc"

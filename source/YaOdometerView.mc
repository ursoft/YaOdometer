import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

const SAVE_PERIOD = 10 * 60 * 1000; //10 minutes
const SAVE_PERIOD_MIN = 5 * 1000;   //5 sec

class YaOdometerView extends Ui.SimpleDataField {
    var m_app as YaOdometerApp = $.getApp();
    var m_convertMetersToDisplay as Double = 0.01d;

    var m_lastDistance as Float = 0.0, m_totalSavedDistance as Double = 0.0d;
    var m_lastSavedDistance as Float = 0.0, m_lastSaveMoment as Number = Sys.getTimer();

    function forceSave() as Void {
        var now = Sys.getTimer();
        if(now - m_lastSaveMoment < SAVE_PERIOD_MIN) {
            return; //too often
        }
        m_lastSaveMoment = now - SAVE_PERIOD - 1;
    }

    function onTimerReset() as Void {
        forceSave();
    }

    function onTimerStop() as Void {
        forceSave();
    }

    function onSettingsChanged() as Void {
        forceSave();
        m_lastDistance = 0.0;
        m_lastSavedDistance = 0.0;
        m_totalSavedDistance = m_app.readSetting("TotalOffset", 0.0d) as Double;
        if (m_totalSavedDistance < 0.0d) { m_totalSavedDistance = 0.0d; }

        var du = Sys.getDeviceSettings().distanceUnits;
        var customLabel = m_app.readSetting("Caption", "") as String;
        if (customLabel.length() == 0) {
            label = Ui.loadResource(du == Sys.UNIT_STATUTE ? Rez.Strings.Miles : Rez.Strings.Kilometers).toString();
        } else {
            label = customLabel;
        }
        m_convertMetersToDisplay = (du == Sys.UNIT_STATUTE) ? 0.00621371d : 0.01d;
    }

    function saveChunk(add as Float) as Void {
        if(add > 0) {
            m_totalSavedDistance += add.toDouble();
            m_app.storeSetting("TotalOffset", m_totalSavedDistance);
            m_lastSaveMoment = Sys.getTimer();
        }
    }

    function prettyPrint(val as Double) as String {
        if (val <= 0.0d) { return "-"; }
        var sotni = (val * m_convertMetersToDisplay + 0.5d).toNumber();
        return Lang.format("$1$.$2$", [(sotni / 10).format("%d"), (sotni % 10).format("%d")]);
    }

    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        var newDistance = (info.elapsedDistance != null) ? info.elapsedDistance as Float : 0.0;
        
        //test
        /*newDistance = m_lastDistance + 30.0;
        if(newDistance >= 20000.0) { 
            newDistance = 1000.0; 
        } else {
            if(newDistance > 300.0) { newDistance = 20000.0; }
        }*/
        //newDistance = m_lastDistance + 1.0;
        
        if (m_lastDistance > newDistance) {
            //раз уменьшилось - то m_lastDistance с предыдущей активности, теперь новый пойдет
            saveChunk(m_lastDistance - m_lastSavedDistance);
            m_lastSavedDistance = 0.0;
        } else if (m_lastDistance == 0.0 && m_lastSavedDistance == 0.0 && newDistance > 100) {
            //нули означают, что поле переинициализировано (например, переключали профиль) и почти весь newDistance 
            // в прошлый раз наверняка уже был учтен - т.е. сейчас нам надо продолжить учет, а не устраивать двойной
            m_lastDistance = newDistance;
            m_lastSavedDistance = newDistance;
            return prettyPrint(m_totalSavedDistance);
        }
        m_lastDistance = newDistance;
        //не пришло ли время сохранить накопления? смотрим по времени (раз в 10 минут) и расстоянию (раз в 300м)
        if (newDistance > m_lastSavedDistance && (newDistance - m_lastSavedDistance > 300 || Sys.getTimer() - m_lastSaveMoment > SAVE_PERIOD)) {
            saveChunk(newDistance - m_lastSavedDistance);
            m_lastSavedDistance = newDistance;
        }
        return prettyPrint(m_totalSavedDistance + (newDistance - m_lastSavedDistance).toDouble());
    }

    function initialize() {
        SimpleDataField.initialize();
        label = "Mileage";
        onSettingsChanged();
    }
}

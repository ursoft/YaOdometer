import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

const SAVE_PERIOD = 10 * 60 * 1000; //10 minutes
const SAVE_PERIOD_MIN = 5 * 1000;   //5 sec

class YaOdometerView extends Ui.SimpleDataField {
    var m_app = Application.getApp();
    var m_convertMetersToDisplay as Double = 0.01;

    var m_lastDistance as Float = 0.0, m_totalSavedDistance as Double = 0.0;
    var m_lastSavedDistance as Float = 0.0, m_lastSaveMoment as Number = Sys.getTimer();

    function forceSave() {
        var now as Number = Sys.getTimer();
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
        m_totalSavedDistance = m_app.readSetting("TotalOffset", 0.0).toDouble();
        if (m_totalSavedDistance < 0.0) { m_totalSavedDistance = 0.0; }

        var du as Number = Sys.getDeviceSettings().distanceUnits;
        var labelSetting as String = m_app.getProperty("Label");
        if (labelSetting == null || length(labelSetting) == 0) { 
            labelSetting = Ui.loadResource(du == Sys.UNIT_STATUTE ? Rez.Strings.Miles : Rez.Strings.Kilometers);
        }
        label = labelSetting;
        m_convertMetersToDisplay = (du == Sys.UNIT_STATUTE) ? 0.00621371 : 0.01;
    }

    function SaveChunk(add as Float) as Void {
        if(add > 0) {
            m_totalSavedDistance += add.toDouble();
            m_app.storeSetting("TotalOffset", m_totalSavedDistance);
            m_lastSaveMoment = Sys.getTimer();
        }
    }

    function PrettyPrint(val as Double) as String {
        if (val <= 0.0) { return "-"; }
        var sotni as Number = (val * m_convertMetersToDisplay + 0.5).toNumber();
        return Lang.format("$1$.$2$", [(sotni / 10).format("%d"), (sotni % 10).format("%d")]);
    }

    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        var newDistance as Float = 0.0;
        if (info.elapsedDistance != null) { newDistance = info.elapsedDistance; }
        
        //test
        /*newDistance = m_lastDistance + 30;
        if(newDistance >= 20000) { 
            newDistance = 1000; 
        } else {
            if(newDistance > 300) { newDistance = 20000; }
        }*/
        //newDistance = m_lastDistance + 1;
        
        if (m_lastDistance > newDistance) {
            //раз уменьшилось - то m_lastDistance с предыдущей активности, теперь новый пойдет
            SaveChunk(m_lastDistance - m_lastSavedDistance);
            m_lastSavedDistance = 0.0;
        }
        m_lastDistance = newDistance;
        //не пришло ли время сохранить накопления? смотрим по времени (раз в 10 минут) и расстоянию (раз в километр)
        if (newDistance > m_lastSavedDistance && (newDistance - m_lastSavedDistance > 1000 || Sys.getTimer() - m_lastSaveMoment > SAVE_PERIOD)) {
            SaveChunk(newDistance - m_lastSavedDistance);
            m_lastSavedDistance = newDistance;
        }
        return PrettyPrint(m_totalSavedDistance + (newDistance - m_lastSavedDistance).toDouble());
    }

    function initialize() as Void {
        SimpleDataField.initialize();
        label = "label";
        onSettingsChanged();
    }
}

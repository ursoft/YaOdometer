import Toybox.Application;
import Toybox.Lang;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

class YaOdometerApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    var m_view as YaOdometerView?;
    function getInitialView() as Array<Ui.Views or Ui.InputDelegates>? {
        m_view = new YaOdometerView();
        return [ m_view ] as Array<Ui.Views or Ui.InputDelegates>;
    }

    function storeSetting(name as String, value as Double) as Void {
        try {
            if (Application has :Storage) {
                Properties.setValue(name, value);
            } else {
                AppBase.setProperty(name, value);
            }
        } catch(ex) {
            Sys.println(Lang.format("storeSetting($1$, $2$) exception: $3$", [name, value, ex.getErrorMessage()])); 
        }
    }
    function readSetting(name as String, defValue as Double) as Double {
        try {
            if (Application has :Storage) {
                var ret = Properties.getValue(name);
                return ret;
            } else {
                return AppBase.getProperty(name);
            }
        } catch(ex) {
            Sys.println(Lang.format("readSetting($1$) exception: $2$", [name, ex.getErrorMessage()])); 
            storeSetting(name, defValue);
            return defValue;
        }
    }
    
    function onSettingsChanged() {
        AppBase.onSettingsChanged();
        if(m_view != null) { m_view.onSettingsChanged(); }
        Ui.requestUpdate();
    }
}
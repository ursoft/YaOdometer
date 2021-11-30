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

    var m_view as YaOdometerView = null;
    function getInitialView() as Array<Views or InputDelegates>? {
        m_view = new YaOdometerView();
        return [ m_view ] as Array<Views or InputDelegates>;
    }

    function storeSetting(name as String, value as Double or String) as Void {
        try {
            if (Application has :Storage) {
                Properties.setValue(name, value);
            } else {
                AppBase.setProperty(name, value);
            }
        } catch(ex) {
            Sys.println("storeSetting exception: " + ex); 
        }
    }
    function readSetting(name as String, defValue as Double or String) as Double or String or Null {
        try {
            if (Application has :Storage) {
                var ret = Properties.getValue(name);
                return ret;
            } else {
                return AppBase.getProperty(name);
            }
        } catch(ex) {
            Sys.println("readSetting exception: " + ex); 
            storeSetting(name, defValue);
            return defValue;
        }
    }
    
    function onSettingsChanged() {
        AppBase.onSettingsChanged();
        m_view.onSettingsChanged();
        Ui.requestUpdate();
    }
}

function getApp() as YaOdometerApp {
    return Application.getApp() as YaOdometerApp;
}
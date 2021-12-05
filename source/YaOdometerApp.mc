import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

const APP_VERSION as String = "0.5 #3"; //change it here (the only place)

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

    function storeSetting(name as String, value as Double or String) as Void {
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
    function readSetting(name as String, defValue as Double or String) as Double or String {
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
    function getSettingsView() as Array<Ui.Views or Ui.InputDelegates>? {
        if (WatchUi has :Menu2) {
            return [new MySettingsMenu(), new MySettingsMenuDelegate()] as Array<Ui.Views or Ui.InputDelegates>;
        } else {
            return null;
        }
    }
}
class MySettingsMenu extends Ui.Menu2 {
    function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle((Ui.loadResource(Rez.Strings.AppName) as String) + " v" + APP_VERSION);
        var app = $.getApp();
        Menu2.addItem(new Ui.MenuItem($.getApp().readSetting("Caption", "") as String, Ui.loadResource(Rez.Strings.CaptionTitle) as String, "Caption", null));
        Menu2.addItem(new Ui.MenuItem(($.getApp().readSetting("TotalOffset", 0.0d) as Double).toNumber().toString(), Ui.loadResource(Rez.Strings.TotalOffsetTitle) as String, "TotalOffset", null));
    }    
}
class MyTextPickerDelegate extends Ui.TextPickerDelegate {
    var m_sender as Ui.MenuItem;
    function initialize(sender as Ui.MenuItem) {
        TextPickerDelegate.initialize();
        m_sender = sender;
    }
    function onTextEntered(text as String, changed as Boolean) as Boolean {
        //Sys.println(Lang.format("onTextEntered($1$, $2$)", [text, changed])); 
        if (changed) {
            var sid = m_sender.getId() as String;
            switch (sid) {
                case "Caption":
                    $.getApp().storeSetting(sid, text);
                    break;
                case "TotalOffset":
                    try {
                        $.getApp().storeSetting(sid, text.toDouble() as Double);
                    } catch(ex) {
                        Sys.println(Lang.format("MyTextPickerDelegate($1$) exception: $2$", [text, ex.getErrorMessage()]));
                        return false;
                    }
                    break;
            }
            m_sender.setLabel(text);
            $.getApp().onSettingsChanged();
        }
        return true;
    }
}
class MySettingsMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }
    function onSelect(item as Ui.MenuItem) as Void {
        Ui.pushView(new Ui.TextPicker(item.getLabel()), new MyTextPickerDelegate(item), Ui.SLIDE_DOWN);
    }
    function onBack() as Void {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
    }
}
function getApp() as YaOdometerApp {
    return Application.getApp() as YaOdometerApp;
}

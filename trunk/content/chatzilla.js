plugin.id = 'growl';

plugin.init =
function init(glob)
{
    /* This function is called when Chatzilla first
    loads the plugin. */
    plugin.major = 0;
    plugin.minor = 1;
    plugin.version = plugin.major + "." + plugin.minor;
    plugin.description = "Displays growl notifications for chatzilla."

    display (replaceColorCodes ('%B%C02') +
             plugin.id + ' plugin version ' + plugin.version + ' loaded.');
}


plugin.enable =
function enable()
{
    /* This function is called by Chatzilla when the
    command "/enable-plugin plugin-name" is issued. */
    display (plugin.id + ' enabled.');
    return true;
}

plugin.disable =
function disable()
{
    /* This function is called by Chatzilla when the
    command "/disable-plugin plugin-name" is issued. */
    display (plugin.id + ' disabled.');
    return true;
}

<?php
// +-----------------------------------------------------------------------+
// | Copyright (c) 2006, Bertrand Mansion                                  |
// | All rights reserved.                                                  |
// |                                                                       |
// | Redistribution and use in source and binary forms, with or without    |
// | modification, are permitted provided that the following conditions    |
// | are met:                                                              |
// |                                                                       |
// | o Redistributions of source code must retain the above copyright      |
// |   notice, this list of conditions and the following disclaimer.       |
// | o Redistributions in binary form must reproduce the above copyright   |
// |   notice, this list of conditions and the following disclaimer in the |
// |   documentation and/or other materials provided with the distribution.|
// | o The names of the authors may not be used to endorse or promote      |
// |   products derived from this software without specific prior written  |
// |   permission.                                                         |
// |                                                                       |
// | THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS   |
// | "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT     |
// | LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR |
// | A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT  |
// | OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, |
// | SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT      |
// | LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, |
// | DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY |
// | THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT   |
// | (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE |
// | OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  |
// |                                                                       |
// +-----------------------------------------------------------------------+
// | Author: Bertrand Mansion <golgote@mamasam.com>                        |
// +-----------------------------------------------------------------------+
//
// $Id $

/**
 * Application object for {@link Net_Growl}
 * 
 * This object represents an application containing the notifications
 * to be registered by {@link http://growl.info Growl}. Feel free to use
 * your own application object as long as it implements the few public 
 * getter methods:
 * - {@link Net_Growl_Application::getGrowlNotifications()}
 * - {@link Net_Growl_Application::getGrowlName()}
 * - {@link Net_Growl_Application::getGrowlPassword()}
 *
 * @author    Bertrand Mansion <golgote@mamasam.com>
 * @copyright 2006
 * @license   http://www.opensource.org/licenses/bsd-license.php BSD License
 * @package   Net_Growl
 * @link      http://growl.info Growl Homepage
 */
class Net_Growl_Application
{
    /**
     * Name of application to be registered by Growl
     * @var string
     * @access private
     */
    var $_growlAppName;

    /**
     * Password for notifications
     * @var string
     * @access private
     */
    var $_growlAppPassword = '';

    /**
     * Array of notifications
     * @var array
     * @access private
     */
    var $_growlNotifications = array();

    /**
     * Constructor
     * Constructs a new application to be registered by Growl
     *
     * @param   string      Application name
     * @param   array       Array of notifications
     * @param   string      Password to be used to notify Growl
     * @access  public
     * @see     Net_Growl_Application::addGrowlNotifications()
     */
    function Net_Growl_Application($appName, $notifications, $password = '')
    {
        $this->_growlAppName = $appName;
        $this->_growlAppPassword = (empty($password)) ? '' : $password;
        if (!empty($notifications) && is_array($notifications)) {
            $this->addGrowlNotifications($notifications);
        }
    }

    /**
     * Adds notifications supported by this application
     *
     * Expected array format is:
     * <pre>
     * array('notification name' => array('option name' => 'option value'))
     * </pre>
     * At the moment, only option name 'enabled' is supported. Example:
     * <code>
     * $notifications = array('Test Notification' => array('enabled' => true));
     * </code>
     *
     * @access  public
     * @param array     Array of notifications to support
     */
    function addGrowlNotifications($notifications)
    {
        $default = $this->_getGrowlNotificationDefaultOptions();
        foreach ($notifications as $name => $options) {
            if (is_int($name)) {
                $name = $options;
                $options = $default;
            } elseif (!empty($options) && is_array($options)) {
                $options = array_merge($default, $options);
            }
            $this->_growlNotifications[$name] = $options;
        }
    }

    function _getGrowlNotificationDefaultOptions()
    {
        return array('enabled' => true);
    }

    /**
     * Returns the notifications accepted by Growl for this application
     *
     * Expected array format is:
     * <pre>
     * array('notification name' => array('option name' => 'option value'))
     * </pre>
     * At the moment, only option name 'enabled' is supported. Example:
     * <code>
     * $notifications = array('Test Notification' => array('enabled' => true));
     * return $notifications;
     * </code>
     *
     * @access  public
     * @return array notifications
     */
    function &getGrowlNotifications()
    {
        return $this->_growlNotifications;
    }

    /**
     * Returns the application name for registration in Growl
     *
     * @access  public
     * @return string application name
     */
    function getGrowlName()
    {
        return $this->_growlAppName;
    }

    /**
     * Returns the password to be used by Growl to accept notification packets
     *
     * @access  public
     * @return string password
     */
    function getGrowlPassword()
    {
        return $this->_growlAppPassword;
    }
}
?>
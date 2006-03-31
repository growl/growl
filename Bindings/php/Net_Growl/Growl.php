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

require_once 'PEAR.php';
require_once 'Net/Growl/Application.php';

/**#@+
 * Growl defines
 */
/**
 * Growl default UDP port
 */
if (!defined('GROWL_UDP_PORT')) define('GROWL_UDP_PORT', 9887);
/**
 * Version of the Growl protocol used in this package
 */
if (!defined('GROWL_PROTOCOL_VERSION')) define('GROWL_PROTOCOL_VERSION', 1);
/**
 * Packet of type Registration
 */
if (!defined('GROWL_TYPE_REGISTRATION')) define('GROWL_TYPE_REGISTRATION', 0);
/**
 * Packet of type Notification
 */
if (!defined('GROWL_TYPE_NOTIFICATION')) define('GROWL_TYPE_NOTIFICATION', 1);
/**#@-*/
/**#@+
 * Package defines
 */
/**
 * Current number of notification being displayed on user desktop
 */
$GLOBALS['_NET_GROWL_NOTIFICATION_COUNT'] = 0;
/**
 * Maximum number of notification to be displayed on user desktop
 */
if (!isset($GLOBALS['_NET_GROWL_NOTIFICATION_LIMIT'])) {
    $GLOBALS['_NET_GROWL_NOTIFICATION_LIMIT'] = 0;
}
/**#@-*/

/**
 * Sends notifications to {@link http://growl.info Growl}
 * 
 * This package makes it possible to easily send a notification from
 * your PHP script to {@link http://growl.info Growl}.
 *
 * Growl is a global notification system for Mac OS X.
 * Any application can send a notification to Growl, which will display
 * an attractive message on your screen. Growl currently works with a 
 * growing number of applications. 
 * 
 * The class provides the following capabilities:
 * - Register your PHP application in Growl.
 * - Let Growl know what kind of notifications to expect.
 * - Notify Growl.
 * - Set a maximum number of notifications to be displayed.
 *
 * @author    Bertrand Mansion <golgote@mamasam.com>
 * @copyright 2006
 * @license   http://www.opensource.org/licenses/bsd-license.php BSD License
 * @package   Net_Growl
 * @link      http://growl.info Growl Homepage
 */
class Net_Growl extends PEAR
{
    /**
     * PHP application object
     * 
     * This is usually a Net_Growl_Application object but can really be
     * any other object as long as Net_Growl_Application methods are
     * implemented.
     *
     * @var object
     * @access private
     */
    var $_application;

    /**
     * Socket resource
     * @var resource
     * @access private
     */
    var $_socket;

    /**
     * Application is registered
     * @var bool
     * @access private
     */
    var $_isRegistered = false;

    /**
     * Net_Growl connection options
     * @var array
     * @access private
     */
    var $_options = array(
                        'host' => '127.0.0.1',
                        'port' => GROWL_UDP_PORT,
                        'protocol' => 'udp'
                        );
    /**
     * Singleton
     *
     * Makes sure there is only one Growl connection open.
     *
     * @return object Net_Growl
     */
    function &singleton($appName, $notifications, $password = '', $options = array())
    {
        static $obj;
        
        if (!isset($obj)) {
            $obj = new Net_Growl($appName, $notifications, $password, $options);
        }
        return $obj;
    }

    /**
     * Constructor
     *
     * This method instantiate a new Net_Growl object and opens a socket connection
     * to the specified Growl socket server. Currently, only UDP is supported by Growl.
     * The constructor registers a shutdown function {@link Net_Growl::_Net_Growl()}
     * that closes the socket if it is open.
     * 
     * Example 1.
     * <code>
     * require_once 'Net/Growl.php';
     *
     * $notifications = array('Errors', 'Messages');
     * $growl = new Net_Growl('My application', $notification);
     * $growl->notify( 'Messages', 
     *                 'My notification title', 
     *                 'My notification description');
     * </code>
     *
     * @param  mixed    Can be a Net_Growl_Application object or the application name string
     * @param  array    Array of notifications
     * @param  string   Optional password for Growl
     * @param  array    Array of options : 'host', 'port', 'protocol' for Growl socket server
     * @access public
     */
    function Net_Growl(&$application, $notifications = array(), $password = '', $options = array())
    {
        foreach ($options as $k => $v) {
            if (isset($this->_options[$k])) {
                $this->_options[$k] = $v;
            }
        }
        if (is_string($application)) {
            $this->_application =& new Net_Growl_Application($application, $notifications, $password);
        } elseif (is_object($application)) {
            $this->_application =& $application;
        }
        parent::PEAR();
    }

    /**
     * Limit the number of notifications
     *
     * This method limits the number of notifications to be displayed on
     * the Growl user desktop. By default, there is no limit. It is used
     * mostly to prevent problem with notifications within loops.
     *
     * @access  public
     * @param   int     Maximum number of notifications
     */
    function setNotificationLimit($max)
    {
        $GLOBALS['_NET_GROWL_NOTIFICATION_LIMIT'] = $max;
    }

    /**
     * Returns the registered application object
     * @access public
     * @return object Application
     * @see Net_Growl_Application
     */
    function &getApplication()
    {
        return $this->_application;
    }

    /**
     * Build, encode end send the registration packet
     *
     * @access  private
     * @return true|PEAR_Error
     */
    function _sendRegister()
    {
        if (!isset($this->_socket)) {
            $socket = $this->_options['protocol'].'://'.$this->_options['host'];
            $this->_socket = fsockopen($socket, $this->_options['port'], $errno, $errstr);
            if ($this->_socket === false) {
                return PEAR::raiseError($errstr);
            }
        }

        $appName       = utf8_encode($this->_application->getGrowlName());
        $password      = $this->_application->getGrowlPassword();
        $nameEnc       = $defaultEnc = '';
        $nameCnt       = $defaultCnt = 0;
        $notifications = $this->_application->getGrowlNotifications();

        foreach($notifications as $name => $options) {
            if (is_array($options) && !empty($options['enabled'])) {
                $defaultEnc .= pack('c', $nameCnt);
                ++$defaultCnt;
            }

            $name = utf8_encode($name);
            $nameEnc .= pack('n', strlen($name)).$name;
            ++$nameCnt;

        }
        $data = pack('c2nc2',
                        GROWL_PROTOCOL_VERSION,
                        GROWL_TYPE_REGISTRATION,
                        strlen($appName),
                        $nameCnt,
                        $defaultCnt);

        $data .= $appName . $nameEnc . $defaultEnc;
    
        if (!empty($password)) {
            $checksum = pack('H32', md5($data . $password));
        } else {
            $checksum = pack('H32', md5($data));
        }
        $data .= $checksum;

        $res = fwrite($this->_socket, $data, strlen($data));
        if ($res === false) {
            return PEAR::raiseError('Could not send registration to Growl Server.');
        }
        $this->_isRegistered = true;
        return true;
    }

    /**
     * Sends a notification to Growl
     *
     * Growl notifications have a name, a title, a description and
     * a few options, depending on the kind of display plugin you use.
     * The bubble plugin is recommended, until there is a plugin more
     * appropriate for these kind of notifications.
     *
     * The current options supported by most Growl plugins are:
     * <pre>
     * array('priority' => 0, 'sticky' => false)
     * </pre>
     * - sticky: whether the bubble stays on screen until the user clicks on it.
     * - priority: a number from -2 (low) to 2 (high), default is 0 (moderate).
     *
     * @access  public
     * @param   object      Application object
     * @param   bool        Whether to send the registration to the server
     * @return true|PEAR_Error
     */
    function notify($name, $title, $description = '', $options = array())
    {
        if ($GLOBALS['_NET_GROWL_NOTIFICATION_LIMIT'] > 0 &&
            $GLOBALS['_NET_GROWL_NOTIFICATION_COUNT'] >= $GLOBALS['_NET_GROWL_NOTIFICATION_LIMIT']) {
            return true;
        }

        if (!$this->_isRegistered && ($res = $this->_sendRegister()) !== true) {
            return $res;
        }

        $appName     = utf8_encode($this->_application->getGrowlName());
        $password    = $this->_application->getGrowlPassword();
        $name        = utf8_encode($name);
        $title       = utf8_encode($title);
        $description = utf8_encode($description);
        $priority    = isset($options['priority']) ? $options['priority'] : 0;

        $flags = ($priority & 7) * 2;
      
        if ($priority < 0) {
            $flags |= 8;
        }
        if (isset($options['sticky']) && $options['sticky'] === true) {
            $flags = $flags | 1;
        }

        $data = pack('c2n5',
                        GROWL_PROTOCOL_VERSION,
                        GROWL_TYPE_NOTIFICATION,
                        $flags,
                        strlen($name),
                        strlen($title),
                        strlen($description),
                        strlen($appName));

        $data .= $name . $title . $description . $appName;

        if (!empty($password)) {
            $checksum = pack('H32', md5($data . $password));
        } else {
            $checksum = pack('H32', md5($data));
        }
        $data .= $checksum;

        $res = fwrite($this->_socket, $data, strlen($data));
        if ($res === false) {
            return PEAR::raiseError('Could not send notification to Growl Server.');
        }
        ++$GLOBALS['_NET_GROWL_NOTIFICATION_COUNT'];
        return true;
    }

    /**
     * Destructor
     *
     * Automatically closes the socket if it is open.
     *
     * @access  private
     */
    function _Net_Growl()
    {
        if (is_resource($this->_socket)) {
            fclose($this->_socket);
            $this->_socket = null;
        }
    }
}
?>
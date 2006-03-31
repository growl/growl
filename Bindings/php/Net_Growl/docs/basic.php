<?php

require_once 'Net/Growl.php';

// Basic usage

$growl =& Net_Growl::singleton('Net_Growl', array('Messages'));
$growl->notify('Messages', 'Hello', 'How are you ?');

?>
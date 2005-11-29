define( 'GROWL_UDP_PORT', 9887 );
define( 'GROWL_PROTOCOL_VERSION', 1 );
define( 'GROWL_TYPE_REGISTRATION', 0 );
define( 'GROWL_TYPE_NOTIFICATION', 1 );

class GrowlRegistrationPacket { // {{{
  var $m_szApplication;
  var $m_aNotifications;
  var $m_szPassword;
  var $m_szData;

  function GrowlRegistrationPacket(
    $szApplication = "growlnotify",
    $szPassword = "" ) {

    $this->m_szApplication  = utf8_encode($szApplication);
    $this->m_szPassword     = $szPassword;
    $this->m_aNotifications = array();
  } // GrowlRegistrationPacket

  function addNotification(
    $szNotification = "Command-Line Growl Notification",
    $bEnabled = True) {

    $this->m_aNotifications[$szNotification] = $bEnabled;
  } // addNotification

  function payload() {
    $szEncoded = $szDefaults = "";
    $nCount = $nDefaults = 0;
    foreach( $this->m_aNotifications as $szName => $bEnabled ) {
      $szName = utf8_encode( $szName );
      $szEncoded .= pack( "n", strlen($szName) ) . $szName;
      $nCount++;
      if( $bEnabled ) {
        $szDefaults .= pack( "c", $nCount-1 );
        $nDefaults++;
      }
    }
    $this->m_szData = pack( "c2nc2",
                            GROWL_PROTOCOL_VERSION,
                            GROWL_TYPE_REGISTRATION,
                            strlen($this->m_szApplication),
                            $nCount,
                            $nDefaults );
    $this->m_szData .= $this->m_szApplication . $szEncoded . $szDefaults;

    if( $this->m_szPassword )
       $szChecksum = pack( "H32", md5( $this->m_szData . $this->m_szPassword ) );
    else
       $szChecksum = pack( "H32", md5( $this->m_szData ));
    $this->m_szData .= $szChecksum;
    return $this->m_szData;
  } // payload
} // GrowlNotificationPacket }}}

class GrowlNotificationPacket { // {{{
  var $m_szApplication;
  var $m_szNotification;
  var $m_szTitle;
  var $m_szDescription;
  var $m_szData;

  function GrowlNotificationPacket(
    $szApplication = "growlnotify",
    $szNotification =  "Command-Line Growl Notification",
    $szTitle = "Title",
    $szDescription = "Description",
    $nPriority = 0,
    $bSticky = False,
    $szPassword = "" ) {

    $this->m_szApplication  = utf8_encode($szApplication);
    $this->m_szNotification = utf8_encode($szNotification);
    $this->m_szTitle        = utf8_encode($szTitle);
    $this->m_szDescription  = utf8_encode($szDescription);

    $nFlags = ($nPriority & 7) * 2;
    if( $nPriority < 0 )
      $nFlags |= 8;
    if( $bSticky )
      $nFlags |= 1;
    $this->m_szData = pack( "c2n5",
                            GROWL_PROTOCOL_VERSION,
                            GROWL_TYPE_NOTIFICATION,
                            $nFlags,
                            strlen($this->m_szNotification),
                            strlen($this->m_szTitle),
                            strlen($this->m_szDescription),
                            strlen($this->m_szApplication) );
    $this->m_szData .= $this->m_szNotification;
    $this->m_szData .= $this->m_szTitle;
    $this->m_szData .= $this->m_szDescription;
    $this->m_szData .= $this->m_szApplication;
    if( $szPassword )
       $szChecksum = pack( "H32", md5( $this->m_szData . $szPassword ) );
    else
       $szChecksum = pack( "H32", md5( $this->m_szData ));
    $this->m_szData .= $szChecksum;
  } // GrowlNotificationPacket

  function payload() {
    return $this->m_szData;
  } // payload
} // GrowlNotificationPacket }}}

$s = socket_create( AF_INET, SOCK_DGRAM, SOL_UDP );
$p = new GrowlRegistrationPacket("PHP Notifier");
$p->addNotification("Informational", false);
$p->addNotification("Warning");
$szBuffer = $p->payload();
socket_sendto( $s, $szBuffer, strlen($szBuffer), 0x100, "192.168.0.42", GROWL_UDP_PORT );
$p = new GrowlNotificationPacket("PHP Notifier", "Warning", "Apache",
                                 "PHP Warning", -2, True );
$szBuffer = $p->payload();
socket_sendto( $s, $szBuffer, strlen($szBuffer), 0x100, "192.168.0.42", GROWL_UDP_PORT );
socket_close( $s );
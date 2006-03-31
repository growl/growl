<?php
/**
 * Net_growl package generator
 * @package Net_Growl
 */
require_once 'PEAR/PackageFileManager.php';

$version = '0.7.0';

$notes = <<<EOT
Initial release
EOT;

$description = <<<EOT
Growl is a MACOSX application that listen to notifications sent by 
applications and displays them on the desktop using different display 
styles. Net_Growl offers the possibility to send notifications to Growl 
from your PHP application through network communication using UDP.
EOT;

$package = new PEAR_PackageFileManager();

$e = $package->setOptions(array(
    'package'           => 'Net_Growl',
    'summary'           => 'Send notifications to Growl from PHP on MACOSX',
    'description'       => $description,
    'version'           => $version,
    'state'             => 'beta',
    'license'           => 'BSD',
    'filelistgenerator' => 'file',
    'ignore'            => array('package.php', 'package.xml'),
    'notes'             => $notes,
    'changelogoldtonew' => false,
    'simpleoutput'      => true,
    'baseinstalldir'    => 'Net',
    'packagedirectory' => '/Volumes/doc/Dev/trunk/Bindings/php/Net_Growl',
));

if (PEAR::isError($e)) {
    echo $e->getMessage();
    exit;
}
$package->addMaintainer('mansion', 'lead', 'Bertrand Mansion', 'golgote@mamasam.com');
$package->addDependency('PEAR', '1.3.3', 'ge',  'pkg', false);
$e = $package->writePackageFile();
if (PEAR::isError($e)) {
    echo $e->getMessage();
    exit;
}
echo "package.xml generated successfully!\n";
?>
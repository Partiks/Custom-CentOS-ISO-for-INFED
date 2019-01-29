<?php
/*
$Id: main.php 5233 2014-02-02 12:36:12Z gruberroland $

  This code is part of LDAP Account Manager (http://www.ldap-account-manager.org/)
  Copyright (C) 2003 - 2014  Roland Gruber

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

/**
* This page redirects to the correct start page after login.
*
* @package main
* @author Roland Gruber
*/

/** config object */
include_once('../lib/config.inc');

// start session
startSecureSession();

setlanguage();

// check if all suffixes in conf-file exist
$conf = $_SESSION['config'];
$new_suffs = array();
// get list of active types
$types = $_SESSION['config']->get_ActiveTypes();
for ($i = 0; $i < sizeof($types); $i++) {
	$info = @ldap_read($_SESSION['ldap']->server(), escapeDN($conf->get_Suffix($types[$i])), "(objectClass=*)", array('objectClass'), 0, 0, 0, LDAP_DEREF_NEVER);
	$res = @ldap_get_entries($_SESSION['ldap']->server(), $info);
	if (!$res && !in_array($conf->get_Suffix($types[$i]), $new_suffs)) $new_suffs[] = $conf->get_Suffix($types[$i]);
}

// display page to add suffixes, if needed
if ((sizeof($new_suffs) > 0) && checkIfWriteAccessIsAllowed()) {
	metaRefresh("initsuff.php?suffs='" . implode(";", $new_suffs));
}
else {
	if (sizeof($types) > 0) {
		for ($i = 0; $i < sizeof($types); $i++) {
			if (isAccountTypeHidden($types[$i])) {
				continue;
			}
			metaRefresh("lists/list.php?type=" . $types[$i]);
			break;
		}
	}
	else {
		metaRefresh("tree/treeViewContainer.php");
	}
}
?>

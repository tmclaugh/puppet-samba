
class samba::client ($join_user, $join_pass, $createcomputer) {
	package { "samba-client" :
		ensure => installed,
		require => Class["ntp::client"]
	}

	# XXX: Not sure if we want to manage the contents of this file.
	file { "/etc/samba/smb.conf" :
		owner => "root",
		group => "root",
		mode => '0644',
		require => Package["samba-client"],
	}

# XXX: Eventually get to handling this.  For now we'll asume kickstart
# handled this.
#	exec { "authconfig_samba" :
#		command => "authconfig  --smbworkgroup $adwrkgrp --smbrealm $krb5realm --smbsecurity ads",
#		unless => "perl -ne 'BEGIN { @p = (qr/\^\s*workgroup = $adwrkgrp/, qr/^\\s*realm = $krb5realm/, qr/^\\s*security = ads/); } for \$p (@p) { \$p{\$p}++ if /\$p/ }; END { exit (@p != keys %p) }' /etc/samba/smb.conf",
#		require => File["/etc/samba/smb.conf"]
#	}

	exec { "net_ads_join" :
		command => "net ads join createcomputer=$createcomputer -U ${join_user}%${join_pass}",
		unless => "net ads testjoin",
		tries => 6,
		try_sleep => 10,
		require => File["/etc/samba/smb.conf"],
		#require => Exec["authconfig_samba"]
	}

	exec { "keytab_create" : 
		# XXX: Give some time for stuff to propogate. 
		command => "net ads keytab create -P", 
		tries => 6, 
		try_sleep => 10, 
		unless => "test -f /etc/krb5.keytab", 
		require => Class["krb5::client"] 
	} 
}

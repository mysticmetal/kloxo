### begin content - please not remove this line

<?php

$statsapp = $stats['app'];
$statsprotect = ($stats['protect']) ? true : false;

$tmpdom = str_replace(".", "\.", $domainname);

$excludedomains = array(
        "cp",
        "disable",
        "default",
        "webmail"
);

$excludealias = implode("|", $excludedomains);

$serveralias = '';

if ($wildcards) {
    $serveralias .= "(?:^|\.){$tmpdom}$";
} else {
    $serveralias .= "^(?:www\.|){$tmpdom}$";
}

if ($serveraliases) {
    foreach ($serveraliases as &$sa) {
        $tmpdom = str_replace(".", "\.", $sa);
        $serveralias .= "|^(?:www\.|){$tmpdom}$";
    }
}

if ($parkdomains) {
    foreach ($parkdomains as $pk) {
        $pa = $pk['parkdomain'];
        $tmpdom = str_replace(".", "\.", $pa);
        $serveralias .= "|^(?:www\.|){$tmpdom}$";
    }
}

if ($webmailapp) {
    $webmaildocroot = "/home/kloxo/httpd/webmail/{$webmailapp}";
} else {
    $webmaildocroot = "/home/kloxo/httpd/webmail";
}

if ($indexorder) {
    $indexorder = implode(' ', $indexorder);
}

$indexorder = '"' . $indexorder . '"';
$indexorder = str_replace(' ', '", "', $indexorder);

if ($blockips) {
    $blockips = str_replace(' ', ', ', $blockips);
}

$ipssls = '';

if ($ipssllist) {
    foreach ($ipssllist as &$ipssl) {
        $ipssls .= '|' . $ipssl;
    }
}

$userinfo = posix_getpwnam($user);
$fpmport = (50000 + $userinfo['uid']);

if ($reverseproxy) {
	$lighttpdextratext = null;
}

$disablepath = "/home/kloxo/httpd/disable";

$globalspath = "/home/lighttpd/conf/globals";

?>

## web for '<?php echo $domainname; ?>'
$HTTP["host"] =~ "<?php echo $serveralias; ?><?php echo $ipssls; ?>" {

    var.domain = "<?php echo $domainname; ?>"
<?php

    if ($wwwredirect) {
?>

    url.redirect = ( "^/(.*)" => "http://www.<?php echo $domainname; ?>/$1" )
<?php
    }

    if ($disabled) {


?>

    var.rootdir = "<?php echo $disablepath; ?>/"

    server.document-root = var.rootdir
<?php
    } else {
?>

    var.rootdir = "<?php echo $rootpath; ?>/"

    server.document-root = var.rootdir
<?php
    }
?>

    index-file.names = ( <?php echo $indexorder; ?> )

    var.user = "<?php echo $user; ?>"

    include "<?php echo $globalspath; ?>/generic.conf"
<?php
    if (!$reverseproxy) {
        if ($statsapp === 'awstats') {
?>

    var.statstype = "awstats"

    include "<?php echo $globalspath; ?>/awstats.conf"
<?php
            if ($statsprotect) {
?>

    var.protectpath = "awstats"
    var.protectauthname = "Awstats"
    var.protectfile = "__stats"

    include "<?php echo $globalspath; ?>/dirprotect.conf"
<?php
            }
        } elseif ($statsapp === 'webalizer') {
?>

    var.statstype = "stats"

    include "<?php echo $globalspath; ?>/webalizer.conf"
<?php
            if ($statsprotect) {
?>

    var.protectpath = "stats"
    var.protectauthname = "stats"
    var.protectfile = "__stats"

    include "<?php echo $globalspath; ?>/dirprotect.conf"
<?php
            }
        }
    }

    if ($lighttpdextratext) {
?>

    # Extra Tags - begin
<?php echo $lighttpdextratext; ?>

    # Extra Tags - end
<?php
    }

    if (!$disablephp) {
        if ($reverseproxy) {
?>

    include "<?php echo $globalspath; ?>/proxy.conf"
<?php
        } else {
            if ($phpcgitype === 'fastcgi') {
?>

    var.fpmport = "<?php echo $fpmport; ?>"

    include "<?php echo $globalspath; ?>/php-fpm.conf"
<?php
            } elseif ($phpcgitype === 'suexec') {
?>

    include "<?php echo $globalspath; ?>/suexec.conf"
<?php
            }
        }
    }

    if ($dirprotect) {
        foreach ($dirprotect as $k) {
            $protectpath = $k['path'];
            $protectauthname = $k['authname'];
            $protectfile = str_replace('/', '_', $protectpath) . '_';
?>

    $HTTP["url"] =~ "^/<?php echo $protectpath; ?>[/$]" {
        auth.backend = "htpasswd"
        auth.backend.htpasswd.userfile = "/home/httpd/" + var.domain + "/__dirprotect/<?php echo $protectfile; ?>"
        auth.require = ( "/<?php echo $protectpath; ?>" => (
            "method" => "basic",
            "realm" => "<?php echo $protectauthname; ?>",
            "require" => "valid-user"
        ))
    }
<?php
        }
    }

    if ($blockips) {
?>

    $HTTP["remoteip"] =~ "{<?php echo $blockips; ?>}" {
        url.access-deny = ( "" )
    }
<?php
    }
?>
}

<?php 
    if ($disabled) {
?>

## webmail for '<?php echo $domainname; ?>'
$HTTP["host"] =~ "^webmail\.<?php echo str_replace(".", "\.", $domainname); ?>" {

    var.rootdir = "<?php echo $disablepath; ?>/"

    server.document-root = var.rootdir

    index-file.names = ( <?php echo $indexorder; ?> )
<?php
        if ($reverseproxy) {
?>

    include "<?php echo $globalspath; ?>/proxy.conf"
<?php
        } else {
?>

    var.fpmport = "50000"

    include "<?php echo $globalspath; ?>/php-fpm.conf"
<?php
        }
?>

}

<?php
    } else {
        if ($webmailremote) {
?>

## webmail for '<?php echo $domainname; ?>'
$HTTP["host"] =~ "^webmail\.<?php echo str_replace(".", "\.", $domainname); ?>" {

    url.redirect = ( "/" =>  "<?php echo $webmailremote; ?>/" )

}

<?php
        } elseif ($webmailapp) {
?>

## webmail for '<?php echo $domainname; ?>'
$HTTP["host"] =~ "^webmail\.<?php echo str_replace(".", "\.", $domainname); ?>" {

    var.rootdir = "<?php echo $webmaildocroot; ?>/"

    server.document-root = var.rootdir

    index-file.names = ( <?php echo $indexorder; ?> )
<?php
            if ($reverseproxy) {
?>

    include "<?php echo $globalspath; ?>/proxy.conf"
<?php
            } else {
?>

    var.fpmport = "50000"

    include "<?php echo $globalspath; ?>/php-fpm.conf"
<?php
            }
?>

}

<?php
        } else {
?>

## webmail for '<?php echo $domainname; ?>' handled by ../webmails/webmail.conf

<?php
        }
    }

    if ($domainredirect) {
        foreach ($domainredirect as $domredir) {
            $redirdomainname = $domredir['redirdomain'];
            $redirpath = ($domredir['redirpath']) ? $domredir['redirpath'] : null;
            $webmailmap = ($domredir['mailflag'] === 'on') ? true : false;

            if ($redirpath) {
                $redirfullpath = str_replace('//', '/', $rootpath . '/' . $redirpath);
?>

## web for redirect '<?php echo $redirdomainname; ?>'
$HTTP["host"] =~ "^<?php echo str_replace(".", "\.", $redirdomainname); ?>" {

    var.rootdir = "<?php echo $redirfullpath; ?>/"

    server.document-root = var.rootdir

    index-file.names = ( <?php echo $indexorder; ?> )

    var.user = "<?php echo $user; ?>"
<?php
    if (!$disablephp) {
        if ($reverseproxy) {
?>

    include "<?php echo $globalspath; ?>/proxy.conf"
<?php
        } else {
            if ($phpcgitype === 'fastcgi') {
?>

    var.fpmport = "<?php echo $fpmport; ?>"

    include "<?php echo $globalspath; ?>/php-fpm.conf"
<?php
            } elseif ($phpcgitype === 'suexec') {
?>

    include "<?php echo $globalspath; ?>/suexec.conf"
<?php
            }
        }
    }
?>

}

<?php
            } else {
?>

## web for redirect '<?php echo $redirdomainname; ?>'
$HTTP["host"] =~ "^<?php echo str_replace(".", "\.", $redirdomainname); ?>" {

    url.redirect = ( "/" =>  "http://<?php echo $domainname; ?>/" )

}

<?php
            }
        }
    }

    if ($parkdomains) {
        foreach ($parkdomains as $dompark) {
            $parkdomainname = $dompark['parkdomain'];
            $webmailmap = ($dompark['mailflag'] === 'on') ? true : false;

            if ($disabled) {
?>

## webmail for parked '<?php echo $parkdomainname; ?>'
$HTTP["host"] =~ "^webmail\.<?php echo str_replace(".", "\.", $parkdomainname); ?>" {

    var.rootdir = "<?php echo $disablepath; ?>/"

    server.document-root = var.rootdir

    index-file.names = ( <?php echo $indexorder; ?> )
<?php
                if ($reverseproxy) {
?>

    include "<?php echo $globalspath; ?>/proxy.conf"
<?php
                } else {
?>

    var.fpmport = "50000"

    include "<?php echo $globalspath; ?>/php-fpm.conf"
<?php
                }
?>

}

<?php
            } else {
                if ($webmailremote) {
?>

## webmail for parked '<?php echo $parkdomainname; ?>'
$HTTP["host"] =~ "^webmail\.<?php echo str_replace(".", "\.", $parkdomainname); ?>" {

    url.redirect = ( "/" =>  "<?php echo $webmailremote; ?>/" )

}

<?php

                } elseif ($webmailmap) {
                    if ($webmailapp) {
?>

## webmail for parked '<?php echo $parkdomainname; ?>'
$HTTP["host"] =~ "^webmail\.<?php echo str_replace(".", "\.", $parkdomainname); ?>" {

    var.rootdir = "<?php echo $webmaildocroot; ?>/"

    server.document-root = var.rootdir

    index-file.names = ( <?php echo $indexorder; ?> )
<?php
                        if ($reverseproxy) {
?>

    include "<?php echo $globalspath; ?>/proxy.conf"
<?php
                        } else {
?>

    var.fpmport = "50000"

    include "<?php echo $globalspath; ?>/php-fpm.conf"
<?php
                        }
?>

}

<?php
                    } else {
?>

## webmail for parked '<?php echo $parkdomainname; ?>' handled by ../webmails/webmail.conf

<?php
                    }
                } else {
?>

## No mail map for parked '<?php echo $parkdomainname; ?>'

<?php
                }
            }
        }
    }

    if ($domainredirect) {
        foreach ($domainredirect as $domredir) {
            $redirdomainname = $domredir['redirdomain'];
            $webmailmap = ($domredir['mailflag'] === 'on') ? true : false;

            if ($disabled) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
$HTTP["host"] =~ "^webmail\.<?php echo str_replace(".", "\.", $redirdomainname); ?>" {

    var.rootdir = "<?php echo $disablepath; ?>/"

    server.document-root = var.rootdir

    index-file.names = ( <?php echo $indexorder; ?> )
<?php
                if ($reverseproxy) {
?>

    include "<?php echo $globalspath; ?>/proxy.conf"
<?php
                } else {
?>

    var.fpmport = "50000"

    include "<?php echo $globalspath; ?>/php-fpm.conf"
<?php
                }
?>

}

<?php
            } else {
                if ($webmailremote) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
$HTTP["host"] =~ "^webmail\.<?php echo str_replace(".", "\.", $redirdomainname); ?>" {

    url.redirect = ( "/" =>  "<?php echo $webmailremote; ?>/" )

}

<?php
               } elseif ($webmailmap) {
                    if ($webmailapp) {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>'
$HTTP["host"] =~ "^webmail\.<?php echo str_replace(".", "\.", $redirdomainname); ?>" {

    var.rootdir = "<?php echo $webmaildocroot; ?>/"

    server.document-root = var.rootdir

    index-file.names = ( <?php echo $indexorder; ?> )
<?php
                        if ($reverseproxy) {
?>

    include "<?php echo $globalspath; ?>/proxy.conf"
<?php
                        } else {
?>

    var.fpmport = "50000"

    include "<?php echo $globalspath; ?>/php-fpm.conf"
<?php
                        }
?>

}

<?php
                    } else {
?>

## webmail for redirect '<?php echo $redirdomainname; ?>' handled by ../webmails/webmail.conf

<?php
                    }
                } else {
?>

## No mail map for redirect '<?php echo $redirdomainname; ?>'

<?php
                }
            }
        }
    }
?>

### end content - please not remove this line
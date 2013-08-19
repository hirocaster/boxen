require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $luser,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::luser}",
  ]
}

File {
  group => 'staff',
  owner => $luser
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => Class['git']
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # core modules, needed for most things
  include dnsmasq
  include git
  include hub
  include nginx

  # # fail if FDE is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  # node versions
  include nodejs::v0_4
  include nodejs::v0_6
  include nodejs::v0_8
  include nodejs::v0_10

  # python
  include python
  python::pip { 'pync':
    virtualenv => '/opt/boxen/homebrew',
  }

  # default ruby versions
  package {
    [
     'readline',
     'openssl',
     ]:
  }
  # include ruby::1_8_7
  include ruby::1_9_3
  include ruby::2_0_0
  # please, see https://gist.github.com/hirocaster/5698361

  # $env = {
  #   'CONFIGURE_OPTS' => '--with-readline-dir=/opt/boxen/homebrew/opt/readline --with-openssl-dir=/opt/boxen/homebrew/opt/openssl'
  # }
  # ruby::version { '1.9.3-p392':
  #   env => $env
  # }
  # ruby::version { '2.0.0-p195':
  #   env => {
  #     'CONFIGURE_OPTS' => '--with-readline-dir=/opt/boxen/homebrew/opt/readline --with-openssl-dir=/opt/boxen/homebrew/opt/openssl'
  #   }
  # }

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar'
    ]:
  }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }
}

class logstash::common {
  file {
    '/usr/local/logstash/':
      ensure   => directory;
    '/etc/logstash/':
      ensure   => directory;
    '/usr/local/logstash/bin/':
      ensure   => directory;
    '/usr/local/logstash/lib/':
      ensure   => directory;
    '/usr/local/logstash/conf':
      ensure   => directory;
    '/usr/local/logstash/logs':
      ensure   => directory;
    '/var/log/logstash/':
      ensure   => directory,
      recurse  => true;
  }
  # Obviously I abused fpm to create a logstash package and put it on my
  # repository
  package { 'logstash': ensure => latest; }
}

class logstash {
  include logstash::common
}

class logstash::shipper (
  $logstash_server = 'localhost',
  $verbose = 'no',
  $jarname = 'logstash-1.1.0-monolithic.jar',
  # TODO This needs refactoring :)
  $logfiles = '"/var/log/messages", "/var/log/syslog", "/var/log/*.log"'
)
{
  file {
    '/etc/logstash/shipper.conf':
      ensure  => file,
      group   => '0',
      mode    => '0644',
      owner   => '0',
      content => template('logstash/shipper.conf.erb'),
      notify  => Service['logstash-shipper'],
  }
  file {
    '/etc/rc.d/init.d/logstash-shipper':
      ensure => file,
      group  => '0',
      mode   => '0755',
      owner  => '0',
      notify  => Service['logstash-shipper'],      
      source => 'puppet:///modules/logstash/logstash-shipper';
  }
  file {
    '/usr/local/logstash/conf/shipper-wrapper.conf':
      ensure   => file,
      group    => '0',
      mode     => '0644',
      owner    => '0',
      notify  => Service['logstash-shipper'],
      content  => template('logstash/shipper-wrapper.conf.erb');
  }
  service { 'logstash-shipper':
    ensure    => running,
    hasstatus => true,
    enable    => true,
  }
  file { '/etc/logrotate.d/syslog':
    ensure   => file,
    group    => '0',
    mode     => '0644',
    owner    => '0',
    source   => 'puppet:///modules/logstash/syslog.logrotate';
  }
}

class logstash::server(
  $verbose = 'no',
  $jarname = 'logstash-1.1.0-monolithic.jar'
)
{
  file {
    '/etc/logstash/indexer.conf':
      ensure  => file,
      group   => '0',
      mode    => '0644',
      owner   => '0',
      notify  => Service['logstash-server'],
      source  => 'puppet:///modules/logstash/indexer.conf';
  }
  file {
    '/etc/rc.d/init.d/logstash-server':
      ensure => file,
      group  => '0',
      mode   => '0755',
      owner  => '0',
      notify  => Service['logstash-server'],
      source => 'puppet:///modules/logstash/logstash-server' ;
  }
  file {
    '/usr/local/logstash/conf/server-wrapper.conf':
      ensure   => file,
      group    => '0',
      mode     => '0644',
      owner    => '0',
      notify  => Service['logstash-server'],
      content  => template('logstash/server-wrapper.conf.erb');
  }
  file {
    '/etc/logstash/grok_patterns':
      source  => 'puppet:///modules/logstash/grok_patterns',
      group   => '0',
      mode    => '0644',
      owner   => '0',
      notify  => Service['logstash-server'],
      ensure  => directory,
      replace => true,
      purge   => true,
      recurse => true;
  }
  service { 'logstash-server':
    ensure    => running,
    hasstatus => true,
    enable    => true,
  }
}

class logstash::web ($jarname ='logstash-1.1.0-monolithic.jar')
{
  file {
    '/etc/rc.d/init.d/logstash-web':
      ensure => file,
      group  => '0',
      mode   => '0755',
      owner  => '0',
      notify  => Service['logstash-web'],
      source => 'puppet:///modules/logstash/logstash-web' ;
  }
  file {
    '/usr/local/logstash/conf/web-wrapper.conf':
      ensure   => file,
      group    => '0',
      mode     => '0644',
      owner    => '0',
      notify  => Service['logstash-web'],
      content  => template('logstash/web-wrapper.conf.erb');
  }
  service { 'logstash-web':
    ensure    => running,
    hasstatus => true,
    enable    => true,
  }
}

# Class jenkins::cli_helper
#
# A helper script for creating resources via the Jenkins cli
#
class jenkins::cli_helper {
  include jenkins
  include jenkins::cli

  Class['jenkins::cli']
  -> Class['jenkins::cli_helper']
  -> Anchor['jenkins::end']

  $libdir = $jenkins::libdir
  $cli_jar = $jenkins::cli::jar
  $port = jenkins_port()
  $prefix = jenkins_prefix()
  $helper_groovy = "${libdir}/puppet_helper.groovy"

  file { $helper_groovy:
    source  => 'puppet:///modules/jenkins/puppet_helper.groovy',
    owner   => $jenkins::user,
    group   => $jenkins::group,
    mode    => '0444',
    require => Class['jenkins::cli'],
  }

  exec { "Restart Jenkins - error 500 ## ${title}":
    command  => "/bin/systemctl restart jenkins && sleep 30",
    path     => '/usr/bin:/usr/sbin:/bin',
    provider => shell,
    onlyif   => 'if ! [[ $(curl -s -o /dev/null -w "%{http_code}" 127.0.0.1:8080) =~ 000|200|403 ]]; then echo 0 ; else exit 1; fi',
  }

  $helper_cmd = join(
    delete_undef_values([
      '/bin/cat',
      $helper_groovy,
      '|',
      '/usr/bin/java',
      "-jar ${cli_jar}",
      "-s http://127.0.0.1:${port}${prefix}",
      $jenkins::_cli_auth_arg,
      'groovy =',
    ]),
    ' '
  )
}

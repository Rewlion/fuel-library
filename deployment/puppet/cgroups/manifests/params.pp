class cgroups::params {

  case $::osfamily {
    'Debian': {
      $packages = ['cgroup-bin', 'libcgroup1', 'cgroup-upstart']
    }
    'redhat':{
      $packages = []
    }
    default: {
      fail("Unsupported platform")
    }
  }
}

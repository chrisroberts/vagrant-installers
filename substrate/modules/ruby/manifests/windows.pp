# == Class: ruby::windows
#
# This installs Ruby on Windows.
#
class ruby::windows(
  $install_dir = undef,
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
) {
  $ruby_version = "2.2.7"
  $devkit_source_url = "http://dl.bintray.com/oneclick/rubyinstaller/DevKit-mingw64-32-4.7.2-20130224-1151-sfx.exe"
  $devkit_installer_path = "${file_cache_dir}\\devkit-4.7.2-64.exe"
  $ri_install_dir = "${file_cache_dir}"
  $ri_full_dir = "${file_cache_dir}\\rubyinstaller-master"
  $ruby_installer_path = "${ri_full_dir}\\pkg\\rubyinstaller-${ruby_version}.exe"
  $ruby_installer_zip = "https://github.com/oneclick/rubyinstaller/archive/master.zip"
  $ruby_installer_zip_path = "${file_cache_dir}\\ri.zip"

  $extra_args = $install_dir ? {
    undef   => "",
    default => " /dir=\"${install_dir}\"",
  }

  #------------------------------------------------------------------
  # Ruby
  #------------------------------------------------------------------
  download { "rubyinstaller":
    source => $ruby_installer_zip,
    destination => $ruby_installer_zip_path,
    file_cache_dir => $file_cache_dir,
  }

  powershell { "extract-rubyinstaller":
    content => template("ruby/extract.erb"),
    creates => "${ri_full_dir}\\rakefile.rb",
    file_cache_dir => $file_cache_dir,
    require => [
      Download["rubyinstaller"],
    ],
  }

  powershell { "set-ruby-version":
    content => template("ruby/set-version.erb"),
    file_cache_dir => $file_cache_dir,
    require => Powershell["extract-rubyinstaller"],
  }

  exec { "build-ruby":
    command => "C:\\Ruby22\\bin\\rake.bat ruby22",
    creates => $ruby_installer_path,
    cwd => $ri_full_dir,
    timeout => 1200,
    require => [
      Powershell["extract-rubyinstaller"],
      Powershell["set-ruby-version"],
    ]
  }

  exec { "package-ruby":
    command => "C:\\Ruby22\\bin\\rake.bat ruby22:package:installer",
    creates => $ruby_installer_path,
    cwd => $ri_full_dir,
    environment => "NODOCS=1",
    require => Exec["build-ruby"],
  }

  exec { "install-ruby":
    command => "cmd.exe /C ${ruby_installer_path} /silent${extra_args}",
    creates => "${install_dir}/bin/ruby.exe",
    require => Exec["package-ruby"],
  }

  #------------------------------------------------------------------
  # Ruby DevKit
  #------------------------------------------------------------------
  download { "ruby-devkit":
    source      => $devkit_source_url,
    destination => $devkit_installer_path,
    file_cache_dir => $file_cache_dir,
  }

  exec { "extract-devkit":
    command => "cmd.exe /C ${devkit_installer_path} -y -o\"${install_dir}\"",
    creates => "${install_dir}/dk.rb",
    require => [
      Download["ruby-devkit"],
      Exec["install-ruby"],
    ],
  }

  file { "${install_dir}/config.yml":
    content => template("ruby/windows/config.yml.erb"),
    require => Exec["extract-devkit"],
  }

  exec { "install-devkit":
    command => "cmd.exe /C ${install_dir}\\bin\\ruby.exe dk.rb install",
    creates => "${install_dir}/lib/ruby/site_ruby/devkit.rb",
    cwd     => $install_dir,
    require => [
      Exec["extract-devkit"],
      File["${install_dir}/config.yml"],
    ],
  }

  file { "${install_dir}/lib/ruby/site_ruby/devkit.rb":
    backup  => false,
    content => template("ruby/windows/devkit.rb.erb"),
    require => Exec["install-devkit"],
  }
}

require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'notifyme', 'start'))

Gem::Specification.new do |s|  
  s.homepage = 'http://github.com/xianhuazhou/NotifyMe'
  s.rubyforge_project = 'notifyme'

  s.name = "notifyme"
  s.version = NotifyMe::VERSION
  s.author = 'xianhua.zhou'
  s.email = 'xianhua.zhou@gmail.com'

  s.platform = Gem::Platform::RUBY

  s.summary = "It's a kind of cronjob."
  s.description = "NotifyMe is a monitoring script, it can monitor processes, services etc. with ruby scripts."

  s.bindir = 'bin'
  s.executables = ['notifyme_daemon', 'notifyme']
  s.default_executable = 'notifyme_daemon'

  s.files = Dir["lib/**/*", "README.rdoc", "CHANGELOG", "INSTALL", "notifyme_config.rb", "bin/*"]
  s.require_path = 'lib'
  s.has_rdoc = false

  s.add_dependency('daemons', '>= 1.1.0')
  s.add_dependency('json_pure', '>= 1.4.2')
  s.add_dependency('http_request.rb', '>= 1.1.13')
  s.add_dependency('facter', '>= 1.6.17')
  s.add_dependency('mail', '>= 2.5.3')
end

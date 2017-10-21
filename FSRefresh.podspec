
Pod::Spec.new do |s|
  s.name      = 'FSRefresh'
  s.version   = '0.1.0'
  s.summary   = 'A short description of FSRefresh.'
  s.homepage  = 'https://github.com/lifusheng/FSRefresh'
  s.license   = { :type => 'MIT', :file => 'LICENSE' }
  s.author    = { 'lifusheng' => 'lifution@icloud.com' }
  s.source    = { 
    :git => 'https://github.com/lifusheng/FSRefresh.git',
    :tag => s.version.to_s
  }
  
  s.ios.frameworks = 'UIKit'
  s.ios.deployment_target = '8.0'

  s.resource = 'FSRefresh/Assets/*'
  s.source_files = 'FSRefresh/Classes/**/*'
  
end

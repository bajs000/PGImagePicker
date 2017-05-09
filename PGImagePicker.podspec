Pod::Spec.new do |s|
  s.name     = 'PGImagePicker'
  s.version  = '0.0.1'
  s.ios.deployment_target = '8.0'
  s.license  = 'MIT'
  s.summary  = '本地图片手势批量选择'
  s.homepage = 'https://github.com/bajs000/PGImagePicker'
  s.authors   = { 'bajs000' => 'bajs000@163.com'}
  s.source   = { :git => 'https://github.com/bajs000/PGImagePicker.git', :tag => s.version }

  s.description = '读取本地图片，并支持点击、滑动手势多选，效果仿苹果自带相册。'

  s.source_files = 'PGImagePicker/PGImagePickerVC/*.{png,h,m}'
  s.requires_arc = true
end
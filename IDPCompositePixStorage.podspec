Pod::Spec.new do |s|

  s.name         = "IDPCompositePixStorage"
  s.version      = "0.0.17"
  s.summary      = "IDPcompositePixStorage is a script and iOS middleware set for the storage of the image by combining the mBaaS and Web hosting service"

  s.description  = <<-DESC
                   IDPcompositePixStorage is a script and iOS middleware set for the storage of the image by combining the mBaaS and Web hosting service. Supported mBaaS is Parse, server-side PHP, client-side is built with Objective-C. - IDPcompositePixStorage はmBaaSとWeb hosting service を組み合わせてイメージをストレージするためのスクリプトとiOSミドルウェア一式です。サポートしているmBaaSはParse,サーバーサイドはPHP、クライアントサイドはObjective-Cで構築されています。
                   DESC

  s.homepage     = "https://github.com/notoroid/IDPcompositePixStorage"

  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "notoroid" => "noto@irimasu.com" }
  s.social_media_url   = "http://twitter.com/notoroid"

  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/notoroid/IDPcompositePixStorage.git", :tag => "v0.0.17" }
  s.source_files  = "Lib/**/*.{h,m}","Lib/IDPStorageManagerModel.xcdatamodeld","Lib/IDPStorageManagerModel.xcdatamodeld/*.xcdatamodel"
  s.resources = ['Lib/IDPStorageManagerModel.xcdatamodeld','Lib/IDPStorageManagerModel.xcdatamodeld/*.xcdatamodel']
  s.preserve_paths = 'Lib/IDPStorageManagerModel.xcdatamodeld'
  s.framework  = 'CoreData'  
  s.dependency 'AFNetworking'
  s.dependency 'Parse'
  s.dependency 'Bolts/Tasks'

  s.requires_arc = true

end

# IDPCompositePixStorage
IDPcompositePixStorage is a script and iOS middleware set for the storage of the image by combining the mBaaS and Web hosting service. Supported mBaaS is Parse, server-side PHP, client-side is built with Objective-C. - IDPcompositePixStorage はmBaaSとWeb hosting service を組み合わせてイメージをストレージするためのスクリプトとiOSミドルウェア一式です。サポートしているmBaaSはParse,サーバーサイドはPHP、クライアントサイドはObjective-Cで構築されています。

Usage
Cocoapods Supported. Please describe the following in your Podfile.

pod 'IDPCompositePixStorage', :git => 'https://github.com/notoroid/IDPCompositePixStorage.git'

cocoapod install
or

cocoapod update
open [yourproject].xcworkspace


#Configure Parse

##Add Classses in Parse - Data.
- UploadTicket
- PhotoImage
- StoreSubFolder

##Add Parameter in Parse - Config.
| Configure Name        | Type        |         Note            |
|:----------------------|------------:|:-----------------------:|
| IDPUploadTicketPrefix |      String |your image prefix        |
| IDPLoadURL            |      String |load.php,absolute URL.   |
| IDPUploadURL          |      String |upload.php,absolute URL. |




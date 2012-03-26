# au Wi-Fi SPOT接続用クライアント(WISPr 1.0クライアント)

これはコマンドラインからau Wi-Fi SPOTに接続するためのスクリプトです。  
付属のWISPrクライアントはau Wi-Fi SPOTのみならず、WISPr 1.0プロトコル対応の公衆無線LANであれば使用できます。

## 用意するもの

* au ID(au one-ID)とそのパスワード
* 各サービスのSSIDとパスフレーズ
* Perl実行環境と以下のPerlモジュール
    * File::Temp
    * Getopt::Long
    * JSON
    * LWP::UserAgent
    * Pod::Usage
    * Web::Scraper
    * XML::Simple
* 事前の機器登録(MACアドレス登録)

auの「ISフラット」もしくは「プランF (IS) シンプル/プランF (IS)」に加入していなければ使えないそうです。 詳しくは[au Wi-Fi SPOT公式サイト](http://www.au.kddi.com/wifi/au_wifi_spot/index.html)で確認してください。

### au ID(au one-ID)とパスワードの取得方法

[au one-ID登録・設定変更方法](https://connect.auone.jp/net/id/id_guide/regist.html)で確認してください。

### 各サービスのSSIDとパスフレーズ

au Wi-Fi SPOTで使えるアクセスポイントは次のSSIDのもののようです。

* au_Wi-Fi
* Wi2_club
* Wi2premium_club
* UQ_Wi-Fi

これらのSSIDのパスフレーズは何らかの方法で調べてください。ちなみに、

* [Windows用au Wi-Fi接続ツール](http://www.au.kddi.com/wifi/au_wifi_spot/riyo/pc/windows.html)
* [OSX用au Wi-Fi接続ツール](http://www.au.kddi.com/wifi/au_wifi_spot/riyo/pc/mac.html)

をインストールして「ネットワーク(SSID)の登録」を押すと、これらのアクセスポイントのパスフレーズがお使いの端末に記録されるので簡単に確認できます。

### Perl実行環境と以下のPerlモジュール

cpanmなどでインストールすればいいんじゃないでしょうか。

    # curl -L http://cpanmin.us/ | perl - File::Temp Getopt::Long JSON LWP::UserAgent Pod::Usage Web::Scraper XML::Simple

### 事前の機器登録(MACアドレス登録)

まずauwifi\_authenticate.plで、au Wi-Fi SPOTで使用する機器のMACアドレスを登録します。  
**これはau Wi-Fi SPOTのアクセスポイントでは実施できません。事前にインターネットに接続できる環境で実施してください。**

    $ perl auwifi_authorize.pl -i [au ID] -p [au IDのパスワード] -m [MACアドレス]

MACアドレスは:を使わず12桁をそのまま書いてください。正しい場合、以下のようになります。

    $ perl auwifi_authorize.pl -i auoneid -p auonepassword -m au1234567890AB
    Authentication success
    passwd: [パスワード]
    max_device_num: 02
    device_num: 02
    user_id: [ユーザ名]
    code: N22

このuser\_idとpasswdの欄に表示されているものをWISPrのログインに使用しますので控えておいてください。

## 公衆無線LANに接続する

公衆無線LANのアクセスポイントに接続後、wispr\_login.plでログインします。au Wi-Fiの場合、上記の機器登録で取得したuser\_idとpasswdを設定します。

    $ perl wispr_login.pl -u [user_id] -p [passwd]

### ログイン成功

    ...
    Login succeeded (Access ACCEPT)
    LogoffUrl: https://...

こんな感じにLogin succeededと表示されたら成功です。

### ログイン失敗

パスワードなどが間違っていた場合、次のように表示されます。

    ...
    Login failed (Access REJECT)

### 未サポートもしくはログイン済

WISPrプロトコルに非対応の公衆無線LAN、もしくはすでに公衆無線LANにログイン済の場合、以下のように表示されます。

    ...
    no WISPr protocol found.(Already connected?)

## ログオフ

上記接続手順で表示されたLogoffUrlのURLにアクセスすると公衆無線LANからログオフができます。
ログオフ用URLはブラウザでもcurlコマンドでも構いません。

    $ curl https://...

## WISPrクライアント動作確認済の公衆無線LANサービス一覧

付属のWISPrクライアントで接続確認できた公衆無線LANサービスとそのSSIDは以下の通り。

* au Wi-Fi SPOT
    * au_Wi-Fi
* Wi2 300
    * Wi2_club
    * Wi2premium_club
* BBモバイルポイント
    * mobilepoint

## 参考リンク

* [au Wi-Fi SPOTにLinuxから接続できるようにしてみた](http://d.hatena.ne.jp/tmatsuu/20120320/1332262068)
* [WISPr - Wikipedia](http://en.wikipedia.org/wiki/WISPr) 
* [ACMEWISP](http://www.acmewisp.com/)

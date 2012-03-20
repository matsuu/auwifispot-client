# au Wi-Fi SPOT接続用クライアント

これはコマンドラインからau Wi-Fi SPOTに接続するためのスクリプトです。

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

これらのSSIDを何らかの方法で調べてください。ちなみに、
* [Windows用au Wi-Fi接続ツール](http://www.au.kddi.com/wifi/au_wifi_spot/riyo/pc/windows.html)
* [OSX用au Wi-Fi接続ツール](http://www.au.kddi.com/wifi/au_wifi_spot/riyo/pc/mac.html)
をインストールして「ネットワーク(SSID)の登録」を押すと、これらのアクセスポイントのパスフレーズがお使いの端末に記録されるので簡単に確認できます。

### Perl実行環境と以下のPerlモジュール

cpanmなどでインストールすればいいんじゃないでしょうか。

    # cpanm -L http://cpanmin.us/ | perl - File::Temp Getopt::Long JSON LWP::UserAgent Pod::Usage Web::Scraper XML::Simple

### 事前の機器登録(MACアドレス登録)

まずauwifi_authenticate.plで、au Wi-Fi SPOTで使用する機器のMACアドレスを登録します。
*これはau Wi-Fi SPOTのアクセスポイントでは実施できません。事前にインターネットに接続できる環境で実施してください。*

    # perl auwifi_authorize.pl -i [au ID] -p [au IDのパスワード] -m [MACアドレス]

MACアドレスは:を使わず12桁をそのまま書いてください。正しい場合、以下のようになります。

    # perl auwifi_authorize.pl -i auoneid -p auonepassword -m au1234567890AB
    Authentication success
    passwd: [パスワード]
    max_device_num: 02
    device_num: 02
    user_id: [ユーザ名]
    code: N22

このuser_idとpasswdの欄に表示されているものをWISPrのログインに使用しますので控えておいてください。

## 接続する

au Wi-Fi SPOTのアクセスポイントに接続後、auwifi_login.plでログインします。上記の機器登録で取得したuser_idとpasswdを設定します。

    # perl auwifi_login.pl -u [user_id] -p [passwd]
    ...
    Login succeeded
    LogoffUrl: https://...

こんな感じにLogin succeededと表示されたら成功です。
